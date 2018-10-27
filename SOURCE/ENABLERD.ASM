; R$ENBLRD.ASM
;  ENABLEREAD PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1/8/90    .000    Initial version.
;----------------------------------------------------------------------
    PUBLIC      ENABLEREAD

    EXTRN       R$READDATA:NEAR

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized
    EXTRN       R$PARSESTR:WORD
DSEG        ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; EnableRead
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Usage:    CALL    EnableRead
;----------------------------------------------------------------------
; Used to enable the READ operation in a PDQ program.
;----------------------------------------------------------------------
ENABLEREAD  PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

            LEA     AX,CSEG:R$READDATA

            MOV     WORD PTR [R$PARSESTR],AX

            RET     

ENABLEREAD  ENDP

CSEG        ENDS
            END
