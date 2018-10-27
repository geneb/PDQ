;======================================================================
; R$STR.ASM
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------

;   Use MASM /E for the Emulator Library
;   NOTE: to create the _STR$FP.OBJ stub file assemble with a /DSTUB switch.

; 11/28/90      .000    Reconstruct.
; 11/29/90      .001    Integrate Paul's FP calls.
; 12/1/90       .002    Complete DQ up to exponent.
;               .003    Finish exponent.
;               .004    Copy final string.
; 12/2/90       .005    Remove unneeded scientific notation.
; 12/11/90      .006    Redo string logic. Change segment names.
;               .007    Modify interface w/FP, Split.
; 12/12/90      .008    Add FP_POP.
; 12/20/90      .009    Use B$FIX in SPLIT.
; 1/12/91       .010    Fix trailing radix.
;               .011    Recode as duals. Finish double.
; 1/13/91       .012    Minor updates. Shrink code.
;               .013    Generalize MULT and DIV. Support SP.
;               .014    Clean up
; 1/28/91       .015    Use floating pt emulator interrupts. Argh.
; 2/10/91       .016    Change DQs to DTs. Use 87 opcodes.
; 2/12/91               DTs back to DQs. Add 87 debug code.
; 2/16/91       .017    Debugging string manipulation.
; 2/18/91       .018    Split, sep out data.
;               .019    Fix right shift.
; 9/9/91        .020    Changed the string picture of infinity.
; 9/29/91       .021    Fix exponent to return 3 digits only if needed (EW)
; 11/5/91       .022    Fix bug when printing .1 (.0999999999999)
; 11/5/91       .023    Rework to conditionally assemble for _STR$FP.OBJ
;----------------------------------------------------------------------
PUBLIC  R$STR           ;NEAR (Internal)
PUBLIC  R$STR_COPY      ;NEAR (Internal)

;----------------------------------------------------------------------
; FAR Externals
;----------------------------------------------------------------------
EXTRN   P$MAKETEMP:FAR          ;PDQ internal routine

;======================================================================
; DGROUP addressing fixed up by linker.
; DSEG: Initialized data.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU

D87     MACRO   ;ignore this macro throughout the file
        ENDM

;----------------------------------------------------------------------
; String representations of two special cases: zero and infinity.
;----------------------------------------------------------------------
PUBLIC          A_0
PUBLIC          A_INF
PUBLIC          A_INF_TYPE

A_0             DB      1,"0"
A_INF           DB      8,"1.#"
A_INF_TYPE      DB      "D+INF"

;----------------------------------------------------------------------
; The binary powers of ten as represented as binary real numbers.
;----------------------------------------------------------------------
EXTRN           POSPOWER:QWORD
EXTRN           R_10:QWORD
EXTRN           R_100:QWORD
EXTRN           NEGPOWER:QWORD

R_HALF          DQ      0.5

DSEG            ENDS
;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'
;----------------------------------------------------------------------
; Temporary storage for the string we build.
;----------------------------------------------------------------------
PUBLIC          EXP_CHAR
PUBLIC          SIGN_BYTE
PUBLIC          DIGITS
PUBLIC          S_STR

EXP_CHAR        DB      1 DUP (?)       ;Exponent character

SIGN_BYTE       DB      1 DUP (?)       ;+/-
S_STR           DB      22 DUP (?)      ;1.234567890123456D+123
S_LEN           EQU     $-OFFSET DGROUP:S_STR

TEMP_INT        DW      1 DUP (?)       ;To hold conversion
DIGITS          DW      1 DUP (?)       ;Digits allowed
FFLAGS          DW      1 DUP (?)       ;Hold 87 flags
STATE87         DW      1 DUP (?)

USEG            ENDS
;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG02          SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG02, DS:DGROUP, ES:NOTHING, SS:DGROUP

;======================================================================
; R$STR (NEAR:Internal)
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Assumes that the exponent letter, sign byte and digits
;    have been initialized correctly by calling routine.
;----------------------------------------------------------------------
; INPUT:
;       ST(0) = Floating point number to convert to ASCII representation.
; OUTPUT:
;       AX -> String descriptor of ASCII representation.
;             Leading + is suppressed.
;             Non-significant 0's are suppressed.
;----------------------------------------------------------------------
; CHANGES: AX, BX, CX, DX, SI, DI, ES, FLAGS
;----------------------------------------------------------------------
R$STR   PROC    NEAR
        ASSUME  CS:CSEG02, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    DS
                POP     ES
        ASSUME  ES:DGROUP
;----------------------------------------------------------------------
; Set the rounding control of the 87 to "truncate" instead of "round."
; Save old state to restore upon exit.
;----------------------------------------------------------------------
                FSTCW   WORD PTR [STATE87]      ;Store ctrl word
                FWAIT

                MOV     AX,WORD PTR [STATE87]   ;Get it
                OR      AH,0CH                  ;Change rounding bits

                MOV     WORD PTR [TEMP_INT],AX  ;Must load from mem
                FLDCW   WORD PTR [TEMP_INT]     ;Load into 87
;----------------------------------------------------------------------
; Init the string.
;----------------------------------------------------------------------
                MOV     AL,"0"
                MOV     DI,OFFSET DGROUP:S_STR  ;Write str at DI
                MOV     CX,S_LEN
                REP     STOSB
;----------------------------------------------------------------------
; PHASE 1:
; Number is a legitimate value. Scale the number to the range
; 1.0 <= n < 10.0 while adjusting the exponent.
;----------------------------------------------------------------------
; CX = CURRENT POWER OF 10
; DX = BASE 10 EXPONENT (being built)
; SI = TABLE OF REAL NUMBERS
; BX = ADDITIONAL OFFSET TO QWORD IN TABLE
; ST = NUMBER TO BE CONVERTED
;----------------------------------------------------------------------
                MOV     CX,256                  ;10 to the...
                XOR     DX,DX                   ;Init exponent
;----------------------------------------------------------------------
; Compare the number to +1. If < 1, need to scale the number up by
; dividing by negative powers of ten until in the range 1 <= n < 10.
;----------------------------------------------------------------------
                FLD1                            ;Load a +1.0
        D87
                FCOMP   ST(1)                   ;CMP 1,NUM
        D87
                FSTSW   WORD PTR [FFLAGS]
                FWAIT
                MOV     AH,BYTE PTR [FFLAGS+1]
                SAHF

                MOV     BX,8*8                  ;Offset = 8 8-byte words

                JA      STR_5A
;----------------------------------------------------------------------
; Number is >1. If >10, must divide by powers of ten until <10.
;----------------------------------------------------------------------
                MOV     SI,OFFSET DGROUP:POSPOWER ;Point SI to 10^CX
STR_4A:
                FLD     QWORD PTR [BX+SI]
        D87
                FCOMP   ST(1)
        D87
                FSTSW   WORD PTR [FFLAGS]
                FWAIT
                MOV     AH,BYTE PTR [FFLAGS+1]
                SAHF

                JA      STR_4B
;----------------------------------------------------------------------
; # > than this power of ten. Divide.
;----------------------------------------------------------------------
                FLD     QWORD PTR [BX+SI]
        D87
                FDIVP   ST(1),ST
        D87
                ADD     DX,CX                   ;Add the exponent
STR_4B:
                SHR     CX,1                    ;Decrease test exp

                SUB     BX,8                    ;Point to that DQ
                JNS     STR_4A                  ;Drop unless >0

                JMP     SHORT STR_5C            ;Finished, # < 10
;----------------------------------------------------------------------
; # is <1. Divide by negative powers of ten (same as mult) until >1.
;----------------------------------------------------------------------
STR_5A:
                MOV     SI,OFFSET DGROUP:NEGPOWER ;Point DI to 10^-CX
                FLD     QWORD PTR [BX+SI]
        D87
                FCOMP   ST(1)
        D87
                FSTSW   WORD PTR [FFLAGS]
                FWAIT
                MOV     AH,BYTE PTR [FFLAGS+1]
                SAHF

                JB      STR_5B
;----------------------------------------------------------------------
; # < than this power of ten. Divide.
;----------------------------------------------------------------------
                FLD     QWORD PTR [BX+SI]
        D87
                FDIVP   ST(1),ST
        D87
                SUB     DX,CX                   ;Sub the exponent
STR_5B:
                SHR     CX,1                    ;Decrease test exponent

                SUB     BX,8                    ;Point to that DQ
                JNS     STR_5A                  ;Drop unless >0
;----------------------------------------------------------------------
; This operation can still leave us with a value 0<#<1. Adjust if needed.
;----------------------------------------------------------------------
                FLD1
        D87
                FCOMP   ST(1)
        D87
                FSTSW   WORD PTR [FFLAGS]
                FWAIT
                MOV     AH,BYTE PTR [FFLAGS+1]
                SAHF

                JBE     STR_5C

                MOV     SI,OFFSET DGROUP:R_10
                FLD     QWORD PTR [SI]
        D87
                FMULP   ST(1),ST
        D87
                DEC     DX                      ;Adjust exponent
STR_5C:
;----------------------------------------------------------------------
; PHASE 2:
; Now we have a number that can be represented in base 10 as
; 1.0 <= n < 10.0.
; Convert this to an ASCII string one base-10 digit at a time.
;----------------------------------------------------------------------
                MOV     DI,OFFSET DGROUP:S_STR  ;Write str at DI
;----------------------------------------------------------------------
; Return the integer portion of ST0 in AX. Leave the fractional part
; in ST0. The integer portion will always be a single digit. Convert
; to ASCII, write into the string, and add the decimal point.
;----------------------------------------------------------------------
                CALL    RSTR_SPLIT              ;Rtn INT in AX

                OR      AL,"0"                  ;Convert to char
                MOV     AH,"."                  ; add decimal
                STOSW                           ; write to str

                MOV     CX,WORD PTR [DIGITS]
                DEC     CX                      ;Digits left to cnvrt
;----------------------------------------------------------------------
; Convert the remainder of the fraction. Convert until the fraction = 0
; or until we have processed DP_DIGITS.
;----------------------------------------------------------------------
                JMP     SHORT STR_6D
STR_6C:
                MOV     SI,OFFSET DGROUP:R_10   ;Mult frac by 10
                FLD     QWORD PTR [SI]
        D87
                FMULP   ST(1),ST
        D87
                CALL    RSTR_SPLIT              ;Get integer portion
        D87
                OR      AL,"0"                  ;Cnvrt to ASCII
                STOSB
                DEC     CX                      ;Digits left
;----------------------------------------------------------------------
; If the fraction is now zero, then no rounding of the last digit is
; needed. Proceed to string cleanup.
;----------------------------------------------------------------------
STR_6D:
                FTST
                FSTSW   WORD PTR [FFLAGS]
                FWAIT

                MOV     AH,BYTE PTR [FFLAGS+1]
                SAHF
                JE      STR_8A
;----------------------------------------------------------------------
; If all the digits have been used (the fraction != 0), stop converting
; and round the last digit.
;----------------------------------------------------------------------
                JCXZ    STR_7A
                JMP     STR_6C
;----------------------------------------------------------------------
; The maximum number of digits were converted and placed in the string
; but the fraction was not zero.
;----------------------------------------------------------------------
STR_7A:
                MOV     CX,DI                   ;Remember current ptr
                DEC     DI                      ;Point to last char
;----------------------------------------------------------------------
; Round the last digit if the fraction is >= 0.5 .
;----------------------------------------------------------------------
                MOV     SI,OFFSET DGROUP:R_HALF

                FLD     QWORD PTR [SI]
        D87
                FCOMP   ST(1)
        D87
                FSTSW   WORD PTR [FFLAGS]
                FWAIT
                MOV     AH,BYTE PTR [FFLAGS+1]
                SAHF

                JA      STR_7Z
;----------------------------------------------------------------------
; Round up the last digit (in the ASCII string).
;----------------------------------------------------------------------
STR_7B:
                CMP     BYTE PTR [DI],"."
                JNE     STR_7D
;----------------------------------------------------------------------
; We must round up the digit to the left of the radix.
;----------------------------------------------------------------------
                DEC     DI
                INC     BYTE PTR [DI]
                CMP     BYTE PTR [DI],"9"
                JBE     STR_7Z
;----------------------------------------------------------------------
; The digit to the left of the radix was rounded to 10. Shift the string
; right, losing the last digit, move the decimal point, and adjust the
; exponent.
;----------------------------------------------------------------------
                MOV     BYTE PTR [DI],"1"       ;ONE
                INC     DI                      ;POINT
                MOV     AL,"0"                  ;ZERO

                PUSH    CX
                MOV     CX,WORD PTR [DIGITS]
STR_7C:
                INC     DI
                XCHG    AL,BYTE PTR [DI]
                LOOP    STR_7C

                POP     CX
                INC     DX
                JMP     SHORT STR_7Z
;----------------------------------------------------------------------
; Round up a "normal" digit. If <= "9", we're done.
;----------------------------------------------------------------------
STR_7D:
                INC     BYTE PTR [DI]
                CMP     BYTE PTR [DI],"9"
                JBE     STR_7Z
;----------------------------------------------------------------------
; There was a carry. Move it into the digit to the left.
;----------------------------------------------------------------------
                MOV     BYTE PTR [DI],"0"
                DEC     DI
                JMP     STR_7B
;----------------------------------------------------------------------
; We're done with rounding. Restore pointer.
;----------------------------------------------------------------------
STR_7Z:
                MOV     DI,CX                   ;Current str ptr
                XOR     CX,CX                   ;Restore digits left ctr
;----------------------------------------------------------------------
; Remove trailing zeros from string, if present.
;----------------------------------------------------------------------
STR_8A:
                CMP     BYTE PTR [DI-1],"0"
                JNE     STR_8B

                DEC     DI                      ;Move write ptr
                INC     CX                      ;More digits left
                JMP     STR_8A
STR_8B:
;----------------------------------------------------------------------
; PHASE 3: Eliminate the exponent if unnecessary.
;----------------------------------------------------------------------
; CX = number of digits not used.
; DX = exponent
; DI -> one past last valid character written
; AX,BX,SI are unused
;----------------------------------------------------------------------
; At the moment, the number has 1 significant digit, the radix, and
; possibly additional digits.  Positive and negative exponents must be
; handled separately.
;----------------------------------------------------------------------
                OR      DX,DX                   ;Check sign of exp
                JS      STR_10A
                JNZ     @F          ;needed because the jump is out of range
                JMP     STR_11C
@@:

;----------------------------------------------------------------------
; Exponent is non-negative. Radix may shift right up to DIGITS-1 times.
;----------------------------------------------------------------------
                CMP     DX,WORD PTR [DIGITS]
                JNL     STR_11A                 ;Go scientific
;----------------------------------------------------------------------
; How many digits are we going to add to the number?
;----------------------------------------------------------------------
                SUB     CX,WORD PTR [DIGITS]
                INC     CX
                ADD     CX,DX
                JS      STR_9A

                ADD     DI,CX
STR_9A:
;----------------------------------------------------------------------
; Move the radix to the right DX times (eliminating the exponent).
;----------------------------------------------------------------------
                MOV     CX,DX                   ;CX = places to move

                MOV     SI,OFFSET DGROUP:S_STR+1 ;Point to decimal
STR_9B:
                LODSB
                XCHG    AL,BYTE PTR [SI]
                MOV     BYTE PTR [SI-1],AL
                LOOP    STR_9B

                JMP     SHORT STR_11C
;----------------------------------------------------------------------
; DI -> one past last valid character written
; CX = number of digits not used.
; DX = exponent
; AX,BX,SI are unused
;----------------------------------------------------------------------
; Exponent is negative, so radix must shift left.
; CX contains # digits not used. All of these may be used plus one
;   additional shift: the radix is currently to the right of the first
;   digit. MAX_SHIFT = CX+1
; The required shift is defined by the exponent (which is negative).
;   REQUIRE_SHIFT = -DX
; For the shift to happen, Required_shift must be <= Max Shift.
;----------------------------------------------------------------------
STR_10A:
                INC     CX                      ;Max shift

                MOV     AX,DX
                NEG     AX                      ;Required shift

                CMP     AX,CX
                JG      STR_11A
;----------------------------------------------------------------------
; To shift, we will first move the leading digit to the right of the
;   radix. (One left shift.)
;----------------------------------------------------------------------
                XCHG    AX,WORD PTR [S_STR]
                XCHG    AH,AL
                XCHG    WORD PTR [S_STR],AX
;----------------------------------------------------------------------
; Second, we move ALL the characters in the string REQUIRED_SHIFT-1
;   places to the right.
;----------------------------------------------------------------------
                DEC     AX
                JZ      STR_11c

                STD

                DEC     CX
                SUB     CX,WORD PTR [DIGITS]
                NEG     CX

                DEC     DI
                MOV     SI,DI
                ADD     DI,AX                   ;DI=new EOS

                MOV     BX,DI
                INC     BX                      ;BX=one past new EOS

                REP     MOVSB
;----------------------------------------------------------------------
; Third, add needed zeros to pad the string.
;----------------------------------------------------------------------
                CLD                             ;Forward again

                MOV     CX,AX

                MOV     DI,(OFFSET DGROUP:S_STR)+1
                MOV     AL,"0"
                REP     STOSB

                MOV     DI,BX                   ;Restore to EOS+1

                JMP     SHORT STR_11C
;----------------------------------------------------------------------
; Scientific Notation: Convert the base 10 exponent. Write a D and sign.
;----------------------------------------------------------------------
STR_11A:
                MOV     AH,"+"
                MOV     AL,BYTE PTR [EXP_CHAR]

                OR      DX,DX
                JNS     STR_11B

                MOV     AH,"-"
                NEG     DX                      ;Remove sign bit
STR_11B:
                MOV     WORD PTR [DI],AX
                INC     DI
                INC     DI
;----------------------------------------------------------------------
; Extract the three digits.  9/29/91 EW added code below to return only
; 2 exponent digits if all 3 are not needed (to cooperate with FUsing).
;----------------------------------------------------------------------
                XOR     AX,AX
                XCHG    AX,DX
                MOV     CX,100
                DIV     CX

                CMP     AL,0                ;EW 9/29/91
                JNZ     @F                  ;EW 9/29/91
                DEC     WORD PTR [DIGITS]   ;EW 9/29/91
                JMP     SHORT Exp2Digits    ;EW 9/29/91

@@:                                         ;EW 9/29/91
                OR      AL,"0"
                STOSB
Exp2Digits:                                 ;EW 9/29/91
                MOV     AX,DX
                AAM
                OR      AX,"00"
                XCHG    AH,AL
                STOSW
;----------------------------------------------------------------------
; If the last character in the number is the radix, remove it.
; DI -> one past last valid char
;----------------------------------------------------------------------
STR_11C:
                CMP     BYTE PTR [DI-1],"."
                JNE     STR_11D

                DEC     DI
;----------------------------------------------------------------------
; Calculate the length of the string.
;----------------------------------------------------------------------
STR_11D:
                MOV     SI,OFFSET DGROUP:S_STR
                SUB     DI,SI
                MOV     CX,DI                   ;Length of str in CX
                ADD     CL,BYTE PTR [SIGN_BYTE] ;Plus one for neg sign

                FSTP    ST                      ;Clean the FP stack

                FLDCW   WORD PTR [STATE87]

                RET

R$STR   ENDP

;======================================================================
; RSTR_SPLIT (Internal:NEAR)
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; A special-purpose routine to split the real number into integer and
; fractional parts.
;----------------------------------------------------------------------
; INPUT:
;       ST0 = floating point number
; OUTPUT:
;       AX = FIX (ST0)
;       ST0 = ST0 - FIX (ST0)
; ASSUMES:
;       0 >= # < 10
;----------------------------------------------------------------------
; CHANGES: AX
;----------------------------------------------------------------------
RSTR_SPLIT      PROC    NEAR
        ASSUME  CS:CSEG02, DS:DGROUP, ES:NOTHING, SS:DGROUP
;----------------------------------------------------------------------
; Get the portion of the number left of the radix. (Same as BASIC's
; FIX() function. The number is always positive.
;----------------------------------------------------------------------
        D87
                FLD     ST                      ;Dup the stack top
        D87
                FISTP   WORD PTR [TEMP_INT]     ;Write int portion
                FWAIT
        D87
                FILD    WORD PTR [TEMP_INT]
        D87
                MOV     AX,WORD PTR [TEMP_INT]

                FSUBP   ST(1),ST
        D87
                RET

RSTR_SPLIT      ENDP

;======================================================================
; R$STR_COPY
;----------------------------------------------------------------------
; Copies the string produced by R$STR from the temporary area to
; a legitimate string.
;----------------------------------------------------------------------
R$STR_COPY      PROC    NEAR
        ASSUME  CS:CSEG02, DS:DGROUP, ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
; Allocate a string using Ethan's P$MAKETEMP. Returns:
;  BX = eraseable descriptor containing DI,CX
;  DI = offset of start of eraseable string
;  CX = max length of eraseable string
;  ES = DS = DGROUP
;  CLD
;----------------------------------------------------------------------
; Changes: AX, BX, CX, SI, DI, ES
;----------------------------------------------------------------------
IFNDEF STUB     ;if we're not creating the _STR$FP.OBJ stub file
                CMP     BYTE PTR [SIGN_BYTE],0  ;is number negative?
                JNE     @F                      ;yes, skip over
                INC     CX                      ;no, include leading blank
@@:
ENDIF

                CALL    P$MAKETEMP              ;Allocate string
        ASSUME  ES:DGROUP

;----------------------------------------------------------------------
; Copy the local string to a permanent location.
;----------------------------------------------------------------------
IFNDEF STUB     ;if we're not creating the _STR$FP.OBJ stub file
                MOV     AL," "                  ;assume a leading blank
                CMP     BYTE PTR [SIGN_BYTE],0  ;is number positive?
                JE      @F                      ;yes, continue
                MOV     AL,"-"                  ;no, add a leading minus
                DEC     CX                      ;show one less digits 
@@:
                STOSB                           ;and store it
ELSE            ;we are creating the stub file
                CMP     BYTE PTR [SIGN_BYTE],0  ;is number positive?
                JE      @F                      ;yes, continue
                
                MOV     AL,"-"                  ;no, add a leading minus
                STOSB                           ;and store it
                DEC     CX                      ;show one less digits
@@:
ENDIF

                REP     MOVSB                   ;then copy the string
                MOV     AX,BX                   ;return a pointer in AX
                RET

R$STR_COPY      ENDP

CSEG02          ENDS
                END
