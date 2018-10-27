;======================================================================
; SWAPCODE.ASM
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 10/10/91  .000    Original.
;----------------------------------------------------------------------
PUBLIC  SWAPCODE

;======================================================================
; Externals.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EXTRN   R$SWAPCODE:WORD ;In R$CORE.ASM

RLHSEG      ENDS

;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU

DSEG            ENDS

;======================================================================
; Non-resident code.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; SwapCode (PDQ)
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Usage:
;       RESULT = SwapCode%
;
; A return of 0 indicates that AA was not responsible for the popup.
;----------------------------------------------------------------------
; Changes: ES
;----------------------------------------------------------------------
SWAPCODE    PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                MOV     AX,RLHSEG
                MOV     ES,AX
        ASSUME  ES:RLHSEG

                MOV     AX,WORD PTR ES:[R$SWAPCODE]

                RET

SWAPCODE        ENDP

CSEG            ENDS
                END
