;======================================================================
; B$STR8.ASM
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel

;   Use MASM /E for the emulator library

;----------------------------------------------------------------------
; 2/18/91   .000    Extract from R$STR.
; 4/11/91   .001    Change WORD PTR [BP+0DH] to BYTE PTR.
; 09/9/91   .002    If the number is infinity, force sign byte positive
;----------------------------------------------------------------------
PUBLIC  B$STR8  ;FAR (QB)

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
DP_DIGITS   EQU 15

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
; B$STR8:FAR (QB)
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. A double precision number is allowed to have 16 significant digits.
;----------------------------------------------------------------------
; INPUT:
;   STACK = 8-byte real to be converted.
;       WORD0 = BP+6    ;Least significant part
;       WORD1 = BP+8
;       WORD2 = BP+0AH
;       WORD3 = BP+0CH  ;Sign + exponent part
; OUTPUT:
;   AX = String descriptor pointer of ASCII representation.
;        Leading + is suppressed. Non-significant 0's are suppressed.
;----------------------------------------------------------------------
; CHANGES: AX, BX, CX, DX, ES, FLAGS
;----------------------------------------------------------------------
B$STR8      PROC    FAR
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

        CLD             ;String moves forward
;----------------------------------------------------------------------
; DI is the natural choice for pointer to the output string.
;----------------------------------------------------------------------
        MOV     DI,OFFSET DGROUP:S_STR
        MOV     BYTE PTR [SIGN_BYTE],0

        MOV     WORD PTR [DIGITS],DP_DIGITS
        MOV     BYTE PTR [EXP_CHAR],"D"
;----------------------------------------------------------------------
; Check for special cases.
; 1) If the Exponent = 0, then the number is 0 by definition.
;----------------------------------------------------------------------
        MOV     AX,WORD PTR [BP+0CH]    ;Portion containing Exp

        AND     AX,7FF0H                ;Leave only Exp
        JNZ     STR8_2A

        MOV     SI,OFFSET DGROUP:A_0    ;EXP was 0, copy string
        JMP     SHORT STR8_2C
;----------------------------------------------------------------------
; Exponent was not 0.
; Determine the sign of the number. No + sign is printed for positive
; numbers, but a - is used for negative numbers.
;----------------------------------------------------------------------
STR8_2A:
        TEST    BYTE PTR [BP+0DH],80H   ;Sign bit on?
        JZ      STR8_2B

        INC     BYTE PTR [SIGN_BYTE]    ;Turn sign on in string
        AND     BYTE PTR [BP+0DH],7FH   ;Turn sign bit off in num
STR8_2B:
;----------------------------------------------------------------------
; Determine if the number is infinity (exp = 7FF).
;----------------------------------------------------------------------
        CMP     AX,07FF0H               ;is the Exponent = 7FF?
        JNE     STR8_3A

        MOV     BYTE PTR [SIGN_BYTE],0  ;force number to be positive (EW)
        MOV     SI,OFFSET DGROUP:A_INF  ;String picture of infinity
        MOV     AL,BYTE PTR [EXP_CHAR]
        MOV     BYTE PTR [A_INF_TYPE],AL
;----------------------------------------------------------------------
; Put the length of the string in CX and point SI to the first char.
;----------------------------------------------------------------------
STR8_2C:
        XOR     AX,AX                   ;AX = 0
        LODSB                           ;Get AL=# bytes to xfer
        MOV     CX,AX                   ; into CX

        JMP     SHORT STR8_3B
;----------------------------------------------------------------------
; Convert the number to ASCII.
;----------------------------------------------------------------------
STR8_3A:
        MOV     SI,BP           ;Point SI to # to convert
        ADD     SI,6            ;Point to number under test

        FLD     QWORD PTR [SI]
    D87                         ;for debugging, adds no code
        CALL    R$STR           ;CX=len,SI->str
STR8_3B:
        CALL    R$STR_COPY
;----------------------------------------------------------------------
; Exit with the string descriptor in AX.
;----------------------------------------------------------------------
        POP     DI
        POP     SI
        POP     BP

        RET     4*2             ;4 words on stack

B$STR8  ENDP

CSEG02  ENDS
        END
