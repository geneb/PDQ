; DOSBUSY.ASM
;   DOSBusy PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/8/89        Original.
; 7/25/89       Make data uninitialized.
; 7/29/89       .000    Split into file TSR08
; 9/9/89        .001    Update doc,segs.
; 1/8/90        .002    Unify Include file.
;----------------------------------------------------------------------
PUBLIC  DosBusy

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU
DSEG            ENDS
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'
pDOSFLAG        DD      1 DUP (?)
USEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; DosBusy
;----------------------------------------------------------------------
; 1. Check the DOSBUSY flag to see if DOS is in an uninterruptable state.
; 2. Must be called from the non-resident portion once before use in the
;    resident portion.
;----------------------------------------------------------------------
; Usage:
;       IF (DosBusy%) do something
;----------------------------------------------------------------------
DosBusy         PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP
;----------------------------------------------------------------------
; First time, jump to next location and find address of flag.  Then patch
; the jump to skip the intercept code.
;----------------------------------------------------------------------
                DB      0EBH                    ;JMP SHORT RELATIVE
JMP_LOC         DB      0
;----------------------------------------------------------------------
; First time through, get the busy flag in ES:BX.
;----------------------------------------------------------------------
                MOV     AH,34H                  ;Get pointer to flag
                INT     21H

                MOV     WORD PTR [pDOSFLAG][0],BX       ;Save address
                MOV     WORD PTR [pDOSFLAG][2],ES
;----------------------------------------------------------------------
; Patch the jump to skip the above code.
;----------------------------------------------------------------------
    MOV BYTE PTR CSEG:[JMP_LOC],(OFFSET CSEG:BUSY_1 - OFFSET CSEG:DOSBUSY - 2)
BUSY_1:
                LES     BX,DWORD PTR [pDOSFLAG] ;Load ptr
                XOR     AH,AH
                MOV     AL,BYTE PTR ES:[BX]

                RET                             ;Return to BASIC

DosBusy         ENDP

CSEG            ENDS
                END
