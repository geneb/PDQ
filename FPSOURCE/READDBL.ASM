; READDBL.ASM
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 3/14/91       .000    Derived from READLONG.ASM by Ethan (thanks Rob)
; 8/22/96       .001    Added Push/Pop SI around Proc code
;----------------------------------------------------------------------

.8087       ;this file MUST be assembled with MASM 5.1 using the /e switch

PUBLIC      B$RDR8

EXTRN       B$FVAL:FAR

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG,USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

INCLUDE R$PDQ.EQU

EXTRN       R$PARSESTR:WORD                 ;In R$RDPTR.ASM

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
; B$RDR8
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Read a double precision value from a string source.
; By default, reads are made from the internal strings created by the
;  DATA statement.
; This routine also services INPUT and INPUT #
;----------------------------------------------------------------------
B$RDR8      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            PUSH    BP
            MOV     BP,SP
            PUSH    SI
;----------------------------------------------------------------------
; Parse off a single entry in the string at the default location and
; return it as a seperate string.
;----------------------------------------------------------------------
            MOV     BYTE PTR [TARGET_TYPE],_NUMERIC
            CALL    WORD PTR [R$PARSESTR]

;----------------------------------------------------------------------
; Convert the string pointed to by AX to a double precision value and
; return it as a double precision value through the floating point load
; and store mechanism.
;----------------------------------------------------------------------
            PUSH    AX
            CALL    B$FVAL

            LES     BX,DWORD PTR [BP+6]
        ASSUME  ES:NOTHING

            MOV     SI,AX
            FLD     QWORD PTR [SI]
            FSTP    QWORD PTR ES:[BX]
            FWAIT

            POP     SI
            POP     BP
            RET     2 * 2

B$RDR8      ENDP

CSEG        ENDS
            END
