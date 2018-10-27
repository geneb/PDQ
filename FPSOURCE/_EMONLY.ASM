;_EMONLY.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;written by Paul Passarelli

;   03/07/91    .000    Reconstruct, Cleanup
;   03/15/91    .001    Add Int 3C support
;   12/19/91    .002    Point INT 3Dh with the others

;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          P$HookFP            ;Proc Far
    Public          HookFP              ;Proc Far
    Public          P$87Used            ;Byte
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
        P$87Used    DB      0               ;default to '87 not active
    DSEG            ENDS
;======================================================================


;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
    USEG            SEGMENT WORD    PUBLIC  'BSS'
;----------------------------------------------------------------------
    Extrn   OldFPInts   :DWord              ;Interrupt vectors 34h - 3Dh
;----------------------------------------------------------------------
    USEG            ENDS
;======================================================================


;======================================================================
; Code segment.
;----------------------------------------------------------------------
    PDQ_FP          SEGMENT WORD    PUBLIC  'CODE'
;----------------------------------------------------------------------
    Extrn   P$Int_EM    :Near           ;in EMULATOR
;----------------------------------------------------------------------



HookFP Proc Far                             ;let BASIC get at them too
HookFP Endp

;----------------------------------------------------------------------
P$HookFP    Proc Far
    Assume  CS:PDQ_FP, DS:DGROUP, ES:Nothing, SS:DGROUP
;----------------------------------------------------------------------------
;   Save registers
;----------------------------------------------------------------------------
    Push    AX
    Push    BX
    Push    CX
    Push    DX
    Push    SI
    Push    BP
    Push    DS
    Push    ES

;----------------------------------------------------------------------------
;   Save the existing interrupt vectors to local storage
;----------------------------------------------------------------------------
    Mov     AX,3534h                ;service# 35h in AH, INT# 34h in AL
    Mov     CX,10                   ;for Interrupt 34h - 3Dh
    Mov     SI,Offset DGroup:OldFPInts  ;local storage

 Save_Old_Int:
    Int     21h                     ;via DOS
    Mov     [SI],BX                 ;save the address
    Mov     [SI+2],ES               ;save the segment
    Add     SI,4                    ;point to the next storage area
    Inc     AL                      ;select the next interrupt
    Loop    Save_Old_Int

;----------------------------------------------------------------------------
;   Now redirect the floating point interrupts to ourselves
;----------------------------------------------------------------------------
    Push    CS                      ;here's the segment
    Pop     DS                      ;which DOS wants in DS
    Assume  DS:Nothing

    Mov     DX,Offset PDQ_FP:P$Int_EM   ;Emulator Lib
    Mov     CX,10
    Mov     AX,2534h                ;point Interrupt 34h - 3Dh to our handler

 Tell_New_Int:
    Int     21h                     ;call DOS to do it
    Inc     AL
    Loop    Tell_New_Int


;----------------------------------------------------------------------------
;   Restore registers. Return
;----------------------------------------------------------------------------
    Pop     ES
    Pop     DS
    Pop     BP
    Pop     SI
    Pop     DX
    Pop     CX
    Pop     BX
    Pop     AX

    Ret
P$HookFP EndP
;----------------------------------------------------------------------

    PDQ_FP          EndS
;======================================================================

END
