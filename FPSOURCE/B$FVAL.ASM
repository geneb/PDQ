;======================================================================
; B$FVAL.ASM    Returns the numeric value of a string of digits.
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;
;
;   Use "MASM /E" for the Emulator Library 
;
;
;----------------------------------------------------------------------
; 1/29/91       .000    Code to use 87 emulation interrupts.
; 2/9/91        .001    Handle sloppy exponents.
; 3/22/91       .002    Fix bug in numeric conversion logic.
; 4/30/91       .003    Add call to P$FreeTemp to handle VAL(MID$(..)) EW
; 6/16/91       .004    Pad the Result data area to the needed 8 bytes
; 12/2/91       .005    Moved FLDZ to FVAL_2B: to correct VAL("") (Paul P)
; 12/11/91      .006    Recognize "E" or "D" without a leading "+" or "-"
; 04/23/92      .007    Moved FLDZ @ FVAL_2B below leading null tests (Paul P)
;----------------------------------------------------------------------
PUBLIC  B$FVAL  ;FAR (QB)
EXTRN   P$FREETEMP:FAR      ;in FREETEMP.ASM
 
;======================================================================
; DGROUP addressing fixed up by linker.
; DSEG: Initialized data.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
 
INCLUDE R$PDQ.EQU
;----------------------------------------------------------------------
; The binary powers of ten as represented as binary real numbers.
;----------------------------------------------------------------------
EXTRN           POSPOWER:QWORD
EXTRN           NEGPOWER:QWORD
EXTRN           R_10:QWORD
 
DSEG            ENDS
 
;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'
 
;----------------------------------------------------------------------
; Temporary storage for the number we build.
;----------------------------------------------------------------------
RESULT          EQU     $
NEW_DIGIT       DW      1 DUP (?)
EXP             DW      1 DUP (?)       ;To hold exponent
                DW      1 DUP (?)       ;pad to 8 bytes
SIGN_M          DB      1 DUP (?)
SIGN_E          DB      1 DUP (?)
 
INIT_LEN        EQU     $-OFFSET DGROUP:RESULT
 
USEG            ENDS
 
;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG00          SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG00, DS:DGROUP, ES:NOTHING, SS:DGROUP
 
;======================================================================
; B$FVAL:FAR (QB)
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Usage: VAL(string)
;
; 1. string is a sequence of characters that can be interpreted as a
;    numeric value. VAL stops reading the string at the FIRST char that
;    it cannot recognize as part of a number.
; 2. VAL strips leading blanks, tabs and linefeeds.
; 3. Only 16 or fewer significant digits are converted.
;----------------------------------------------------------------------
; INPUT:
;       STACK = Point to descriptor
;               -> [dw len][dw offset]
; OUTPUT:
;       AX = Offset of QWORD floating point number
;----------------------------------------------------------------------
; ALGORITHM:
;
; 1. Scan off digits and convert to a real number.
; 2. Keep track of how many digits are encountered after radix,
;    exponent symbol, end-of-string (EOS) or invalid char is found.
;    Put inverse of this number in exponent word.
; 3. If an exponent is included, convert this and add to exponent word.
; 4. Create +/- 1^n, where n is the exponent.
; 5. Multiply the two, letting the 87 chip do the work.
; 6. Retrieve the number as an 8-byte real.
;----------------------------------------------------------------------
; CHANGES: AX, BX, CX, DX
;----------------------------------------------------------------------
B$FVAL          PROC    FAR
        ASSUME  CS:CSEG00, DS:DGROUP, ES:NOTHING, SS:DGROUP
 
                PUSH    BP                      ;Create stack frame
                MOV     BP,SP
 
                PUSH    SI                      ;Save used registers
                PUSH    DI
 
                CLD                             ;String moves forward
;----------------------------------------------------------------------
; Start with a result of +0, the default response.
;----------------------------------------------------------------------
                XOR     AX,AX
                MOV     DI,OFFSET DGROUP:RESULT
                MOV     CX,INIT_LEN
                PUSH    DS
                POP     ES
        ASSUME  ES:DGROUP
                REP     STOSB
 
;----------------------------------------------------------------------
; Find the string.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BP+6]      ;Pointer
                MOV     CX,WORD PTR [SI]        ;Length
                MOV     SI,WORD PTR [SI+2]      ;Offset
;----------------------------------------------------------------------
; Parse off leading blanks, tabs and LFs, if any.
; If, at any time, the string is reduced to 0 chars, exit.
;----------------------------------------------------------------------
FVAL_2A:
                OR      CX,CX
                JNZ     FVAL_2B
                JMP     FVAL_8A
FVAL_2B:
                LODSB                           ;Get a char
                DEC     CX                      ;Reduce chars remaining
 
                CMP     AL,BLANK
                JE      FVAL_2A
 
                CMP     AL,TAB
                JE      FVAL_2A
 
                CMP     AL,LF
                JE      FVAL_2A

                FLDZ                            ;Init the fp stack
;----------------------------------------------------------------------
; Found a non-white character. Prepare to translate string.
;----------------------------------------------------------------------
; AX: AL = char, AH = 0
;     AX = lo word of DX:AX dword
; BX: BH = converted digit count
;     BL = flags
;               0000 0001 = radix has been scanned
; CX: chars left in string
; SI: ptr to string
; DI: ptr to work space
;----------------------------------------------------------------------
                MOV     DI,OFFSET DGROUP:NEW_DIGIT
                XOR     BX,BX
                XOR     DX,DX
;----------------------------------------------------------------------
; + is only allowed as first char and is ignored.
;----------------------------------------------------------------------
                CMP     AL,"+"
                JE      FVAL_3F
;----------------------------------------------------------------------
; - is only allowed as first char.
;----------------------------------------------------------------------
                CMP     AL,"-"
                JNE     FVAL_3A
 
                INC     BYTE PTR [SIGN_M]
                JMP     SHORT FVAL_3F
;----------------------------------------------------------------------
; Parse for digits making up the mantissa.
;----------------------------------------------------------------------
FVAL_3A:
                CMP     AL,"0"
                JB      FVAL_3G
 
                CMP     AL,"9"
                JA      FVAL_3G
;----------------------------------------------------------------------
; Char was digit, 0-9.
; Note that only 17 digits of a string will be converted since that is
;  all that will fit into a long real.
;----------------------------------------------------------------------
                CMP     BH,17                   ;Have max digits?
                JBE     FVAL_3C
;----------------------------------------------------------------------
; This digit will not be added to mantissa, but it may affect the exponent.
;----------------------------------------------------------------------
                TEST    BL,1                    ;If radix not scanned
                JNZ     FVAL_3B
 
                INC     WORD PTR [EXP]          ; inc exponent
FVAL_3B:
                JMP     SHORT FVAL_3F
;----------------------------------------------------------------------
; This digit will be added to the mantissa.
;----------------------------------------------------------------------
FVAL_3C:
                INC     BH                      ;Up digit counter
 
                FLD     QWORD PTR [R_10]
                FMUL
 
                SUB     AL,"0"
                MOV     WORD PTR [DI],AX
                FILD    WORD PTR [DI]
                FADD
;----------------------------------------------------------------------
; If we've already scanned radix, must compensate by decreasing exp.
;----------------------------------------------------------------------
                TEST    BL,1                    ;Are we left of radix?
                JZ      FVAL_3E
 
                DEC     WORD PTR [EXP]
FVAL_3E:
;----------------------------------------------------------------------
; Read the next char. If none left, we're done.
;----------------------------------------------------------------------
FVAL_3F:
                JCXZ    FVAL_6A
 
                LODSB                           ;Next char in AL
                DEC     CX                      ;Decrease count
                JMP     FVAL_3A
;----------------------------------------------------------------------
; If a radix is encountered, note the fact and continue the scan.
; A second occurance of a radix ends the scan.
;----------------------------------------------------------------------
FVAL_3G:
                CMP     AL,"."
                JNE     FVAL_4A
 
                TEST    BL,1
                JNZ     FVAL_6A
 
                OR      BL,1
                JMP     FVAL_3F
;----------------------------------------------------------------------
; All scanning of the mantissa is completed.
; Look for an exponent character, sign, and exponent.
; Sloppy exponents (E+000001) must be handled politely.
;----------------------------------------------------------------------
FVAL_4A:
                OR      AL,20H
 
                CMP     AL,"e"
                JE      FVAL_4B
 
                CMP     AL,"d"
                JNE     FVAL_6A
 
;----------------------------------------------------------------------
; An exponent is indicated by a D or E character.
; If there are no more chars, stop scanning now.
;----------------------------------------------------------------------
FVAL_4B:
                JCXZ    FVAL_6A                 ;No need to scan further
 
                LODSB                           ;Get next char
                DEC     CX                      ;Decrease count
;----------------------------------------------------------------------
; The exponent may have a sign.
;----------------------------------------------------------------------
                CMP     AL,"+"
                JE      FVAL_4C
 
                CMP     AL,"-"
                JNE     FVAL_4D1
 
                INC     BYTE PTR [SIGN_E]
;----------------------------------------------------------------------
; Read off the exponent digits. Convert the digits faithfully until some
; ridiculous number such as e+32768 is reached. You can't just count digits
; because it could have leading zeros. You can't cut off at 308 because
; .0001e+309 is valid. You just have to do your best to handle what may
; be thrown at you.
;----------------------------------------------------------------------
FVAL_4C:
                JCXZ    FVAL_4E
FVAL_4D:
                LODSB
                DEC     CX
FVAL_4D1:
                CMP     AL,"0"
                JB      FVAL_4E
 
                CMP     AL,"9"
                JA      FVAL_4E
 
                SUB     AL,"0"                  ;Convert to digit
;----------------------------------------------------------------------
; Add the new digit to the exponent.
;----------------------------------------------------------------------
                PUSH    AX                      ;Save new ones digit
                XCHG    AX,DX                   ;Current exp in AX
 
                MOV     DX,10
                MUL     DX                      ;AX = AX*10
 
                POP     DX
                ADD     DX,AX
 
                CMP     DX,3276
                JB      FVAL_4C
FVAL_4E:
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
                CMP     BYTE PTR [SIGN_E],0
                JE      FVAL_4F
 
                NEG     DX
FVAL_4F:
;----------------------------------------------------------------------
; Determine if the exponent is legal. If > 308, ignore it.
;----------------------------------------------------------------------
FVAL_6A:
                ADD     DX,WORD PTR [EXP]
                CMP     DX,308
                JG      FVAL_6B
                CMP     DX,-308
                JNL     FVAL_6C
FVAL_6B:
                XOR     DX,DX
                JMP     SHORT FVAL_6D
;----------------------------------------------------------------------
; Select the correct block of exponents based on the sign of exp.
;----------------------------------------------------------------------
FVAL_6C:
                MOV     SI,OFFSET DGROUP:POSPOWER+8*8
 
                OR      DX,DX
                JNS     FVAL_6D
 
                MOV     SI,OFFSET DGROUP:NEGPOWER+8*8
                NEG     DX
FVAL_6D:
;----------------------------------------------------------------------
; Load a floating point number 1. If number is negative, change sign.
;----------------------------------------------------------------------
                CMP     BYTE PTR [SIGN_M],1
                JNE     FVAL_6F
 
                FCHS
FVAL_6F:
;----------------------------------------------------------------------
; Now give the identity the correct exponent.
;----------------------------------------------------------------------
                MOV     BX,256
FVAL_7A:
                CMP     DX,BX
                JB      FVAL_7B
 
                FLD     QWORD PTR [SI]
                FMULP   ST(1),ST
 
                SUB     DX,BX
FVAL_7B:
                SUB     SI,8
 
                SHR     BX,1
                JNZ     FVAL_7A
;----------------------------------------------------------------------
; Free the incoming string if it was a temp, store the final result.
;----------------------------------------------------------------------
                FSTP    QWORD PTR [RESULT]
                FWAIT
FVAL_8A:
                PUSH    [BP+6]
                CALL    P$FREETEMP
                MOV     AX,OFFSET DGROUP:RESULT

                POP     DI
                POP     SI
                POP     BP
 
                RET     1*2
 
B$FVAL          ENDP
 
CSEG00          ENDS
                END
