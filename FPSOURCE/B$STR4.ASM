;======================================================================
; B$STR4.ASM
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel

;   Use MASM /E for the emulator library

;----------------------------------------------------------------------
; 2/18/91   .000    Extract from R$STR.
; 4/11/91   .001    Change WORD PTR [BP+9] to BYTE PTR.
; 09/5/91   .002    Change mask near STR4_2B: for infinity.
; 09/9/91   .003    If the number is infinity, force sign byte positive
;----------------------------------------------------------------------
PUBLIC  B$STR4  ;FAR (QB)

;----------------------------------------------------------------------
; Externals
;----------------------------------------------------------------------
EXTRN   P$MAKETEMP:FAR      ;PDQ internal routine
EXTRN   R$STR:NEAR          ;in R$STR.ASM
EXTRN   R$STR_COPY:NEAR     ;in R$STR.ASM

;======================================================================
; DGROUP addressing fixed up by linker.
; DSEG: Initialized data.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU

D87 MACRO
    ENDM
;----------------------------------------------------------------------
; Precision allowed by each numeric type (total digits, NOT chars).
;----------------------------------------------------------------------
SP_DIGITS   EQU 7

;----------------------------------------------------------------------
; String representations of two special cases: zero and infinity.
;----------------------------------------------------------------------
EXTRN       A_0:BYTE
EXTRN       A_INF:BYTE
EXTRN       A_INF_TYPE:BYTE

DSEG            ENDS
;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'

EXTRN       S_STR:BYTE
EXTRN       SIGN_BYTE:BYTE
EXTRN       DIGITS:WORD
EXTRN       EXP_CHAR:BYTE

USEG            ENDS
;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG02      SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG02, DS:DGROUP, ES:NOTHING, SS:DGROUP
;======================================================================
; B$STR4:FAR (QB)
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. A single precision number is allowed to have 7 significant digits.
;----------------------------------------------------------------------
; INPUT:
;   STACK = 4-byte real to be converted.
;       WORD0 = BP+6    ;Least significant part
;       WORD1 = BP+8    ;Sign + exponent part
; OUTPUT:
;   AX = String descriptor pointer of ASCII representation.
;        Leading + is suppressed. Non-significant 0's are suppressed.
;----------------------------------------------------------------------
; CHANGES: AX, BX, CX, DX, ES, FLAGS
;----------------------------------------------------------------------
B$STR4      PROC    FAR
    ASSUME  CS:CSEG02, DS:DGROUP, ES:NOTHING, SS:DGROUP

;        FINIT
;        FWAIT
;----------------------------------------------------------------------
; Perform entry code and other common functions.
;----------------------------------------------------------------------
        PUSH    BP          ;Create stack frame
        MOV     BP,SP

        PUSH    SI          ;Save used registers
        PUSH    DI

        CLD                 ;String moves forward
;----------------------------------------------------------------------
; DI is the natural choice for pointer to the output string.
;----------------------------------------------------------------------
        MOV     DI,OFFSET DGROUP:S_STR

        MOV     BYTE PTR [SIGN_BYTE],0
        MOV     WORD PTR [DIGITS],SP_DIGITS
        MOV     BYTE PTR [EXP_CHAR],"E"
;----------------------------------------------------------------------
; Check for special cases.
; 1) If the Exponent = 0, then the number is 0 by definition.
;----------------------------------------------------------------------
        MOV     AX,WORD PTR [BP+8]  ;Portion containing Exp

        AND     AX,7F10H            ;Leave only Exp
        JNZ     STR4_2A

        MOV     SI,OFFSET DGROUP:A_0    ;EXP was 0, copy string
        JMP     SHORT STR4_2C
;----------------------------------------------------------------------
; Exponent was not 0.
; Determine the sign of the number. No + sign is printed for positive
; numbers, but a - is used for negative numbers.
;----------------------------------------------------------------------
STR4_2A:
        TEST    BYTE PTR [BP+9],80H     ;Sign bit on?
        JZ      STR4_2B

        INC     BYTE PTR [SIGN_BYTE]    ;Turn sign on in string
        AND     BYTE PTR [BP+9],7FH     ;Turn sign bit off in num
STR4_2B:
;----------------------------------------------------------------------
; Determine if the number is infinity (exp = 7F).
;----------------------------------------------------------------------
        CMP     AX,7F00H                ;was 7F10H, Paul 9/5/91
        JNE     STR4_3A

        MOV     BYTE PTR [SIGN_BYTE],0  ;force number to be positive (EW)
        MOV     SI,OFFSET DGROUP:A_INF  ;String picture of infinity
        MOV     AL,BYTE PTR [EXP_CHAR]
        MOV     BYTE PTR [A_INF_TYPE],AL
;----------------------------------------------------------------------
; Put the length of the string in CX and point SI to the first char.
;----------------------------------------------------------------------
STR4_2C:
        XOR     AX,AX                   ;AX = 0
        LODSB                           ;Get AL=# bytes to xfer
        MOV     CX,AX                   ; into CX

        JMP     SHORT STR4_3B
;----------------------------------------------------------------------
; Convert the number to ASCII.
;----------------------------------------------------------------------
STR4_3A:
        MOV     SI,BP           ;Point SI to # to convert
        ADD     SI,6            ;Point to number under test

        FLD     DWORD PTR [SI]
    D87                         ;for debugging, adds no code
        CALL    R$STR           ;CX=len,SI->str
STR4_3B:
        CALL    R$STR_COPY
;----------------------------------------------------------------------
; Exit with the string descriptor in AX.
;----------------------------------------------------------------------
        POP     DI
        POP     SI
        POP     BP

        RET     2*2         ;2 words on stack

B$STR4  ENDP

CSEG02  ENDS
        END
