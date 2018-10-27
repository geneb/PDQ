; R$PEOS.ASM
;   B$PEOS  PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1/4/90    .000    Conversion.
; 1/31/90   .001    Add deletion of temp string from B$INPP.
;----------------------------------------------------------------------
PUBLIC  B$PEOS              ;FAR

EXTRN   P$FREETEMP:FAR      ;In FREETEMP.ASM
EXTRN   ENABLEREAD:FAR      ;In ENABLERD.ASM

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

EXTRN       P$PRINTHANDLE:WORD              ;In PHANDLE.ASM

EXTRN       R$PARSESTR:WORD                 ;In R$RDPTR.ASM
EXTRN       R$PARSEDEF:WORD                 ;In R$RDPTR.ASM
EXTRN       INPUT_DESC:WORD                 ;In R$RDPTR.ASM

DSEG        ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; B$PEOS
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1. This routine cleans up after a non-console input or output.
;----------------------------------------------------------------------
B$PEOS      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

            MOV     WORD PTR [P$PRINTHANDLE],1

            MOV     AX,WORD PTR [R$PARSEDEF]
            MOV     WORD PTR [R$PARSESTR],AX

            XOR     CX,CX
            XCHG    CX,WORD PTR [INPUT_DESC]
            JCXZ    PEOS_1

            PUSH    CX
            CALL    P$FREETEMP
PEOS_1:
            CALL    ENABLEREAD
            RET

B$PEOS      ENDP

CSEG        ENDS
            END
