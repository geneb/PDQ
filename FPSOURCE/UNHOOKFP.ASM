;UNHOOKFP.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;written by Paul Passarelli

;   04/11/91    .000    Extract

;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          P$UnhookFP          ;Proc Far
    Public          UnhookFP            ;Proc Far
    Public          OldFPInts           ;DWord storage
;======================================================================


;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
    DGROUP          GROUP   DSEG,USEG
;======================================================================


;======================================================================
; DSEG: Initialized data.
;----------------------------------------------------------------------
    DSEG            SEGMENT WORD    PUBLIC  'DATA'
    DSEG            ENDS
;======================================================================


;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
    USEG            SEGMENT WORD    PUBLIC  'BSS'
;----------------------------------------------------------------------
    OldFPInts   DD  10  Dup (?)             ;Interrupt vectors 34h - 3Dh
;----------------------------------------------------------------------
    USEG            ENDS
;======================================================================


;======================================================================
; Code segment.
;----------------------------------------------------------------------
    PDQ_FP          SEGMENT WORD    PUBLIC  'CODE'
;----------------------------------------------------------------------


UnhookFP Proc Far                           ;let BASIC get at them too
UnhookFP Endp

;----------------------------------------------------------------------
;   P$UnHookFP  Restores the original interrupt vectors.
;----------------------------------------------------------------------
P$UnHookFP  Proc Far

    Assume  CS:PDQ_FP, DS:Nothing, ES:Nothing, SS:DGROUP

;----------------------------------------------------------------------
;   Save registers
;----------------------------------------------------------------------
    Push    AX
    Push    DX
    Push    SI
    Push    DS                      ;save DS so PDQ.ASM can access P$TermCode

;----------------------------------------------------------------------
;   Reinstate the original interrupt vectors.
;----------------------------------------------------------------------
    Mov     AX,2534h                ;service 25h in AH, INT 34h in AL
    Mov     CX,10
    Mov     SI,Offset DGroup:OldFPInts  ;for Interrupt 34h - 3Dh

 Tell_Old_Int:
    Lds     DX,SS:[SI]
    Int     21h                     ;let DOS do the dirty work
    Add     SI,4                    ;point to the next storage area
    Inc     AL                      ;select the next interrupt
    Loop    Tell_Old_Int

;----------------------------------------------------------------------
;   Restore registers.  Return
;----------------------------------------------------------------------
    Pop     DS
    Pop     SI
    Pop     DX
    Pop     AX

    Ret
P$UnHookFP  EndP
;----------------------------------------------------------------------

    PDQ_FP          EndS
;======================================================================

END
