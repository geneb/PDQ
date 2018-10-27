; CYREAD.ASM
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 3/14/91       .000    Derived from READLONG.ASM by Ethan (thanks Rob)
;----------------------------------------------------------------------

.8087       ;this file MUST be assembled with MASM 5.1 using the /e switch

PUBLIC      B$RDCY

EXTRN       B$FVAL:FAR

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG,USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

INCLUDE     C:\PDQ\SOURCE\R$PDQ.EQU         ;edit to suit your directories

EXTRN       R$PARSESTR:WORD                 ;In R$RDPTR.ASM
EXTRN       P$10000:WORD                    ;In CYDATA.ASM

DSEG        ENDS
;----------------------------------------------------------------------
USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized

EXTRN       TARGET_TYPE:BYTE                ;In R$RDPTR.ASM

USEG        ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; B$RDCY
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Read a Currency value from a string source.
; By default, reads are made from the internal strings created by the
;  DATA statement.
; This routine also services INPUT and INPUT #
;----------------------------------------------------------------------
B$RDCY      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            PUSH    BP
            MOV     BP,SP
;----------------------------------------------------------------------
; Parse off a single entry in the string at the default location and
; return it as a seperate string.
;----------------------------------------------------------------------
            MOV     BYTE PTR [TARGET_TYPE],_NUMERIC
            CALL    WORD PTR [R$PARSESTR]

;----------------------------------------------------------------------
; Convert the string pointed to by AX to a double precision value and
; return it as a double precision value through the floating point load
; and store mechanism.  Multiply times 10000 because Currency data is
; stored biased that way.
;----------------------------------------------------------------------
            PUSH    AX
            CALL    B$FVAL

            LES     BX,DWORD PTR [BP+6]
        ASSUME  ES:NOTHING

            MOV     SI,AX
            FLD     QWORD PTR [SI]
            FMUL    DWORD PTR P$10000
            FISTP   QWORD PTR ES:[BX]
            FWAIT

            POP     BP
            RET     2 * 2

B$RDCY      ENDP

CSEG        ENDS
            END
