;******** _87ONLY.ASM

;Copyright (c) 1990-1991 Crescent Software Inc.
;written by Paul Passarelli

;   NOTE: DO NOT USE /E WITH THIS FILE. IT WON'T WORK ANYHOW!!!
;
;   03/07/91    .000    Reconstruct, Cleanup
;   04/11/91    .001    Int 3Ch support & claenup
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
    Assume  CS:PDQ_FP
;----------------------------------------------------------------------
    Extrn   P$Int_87    :Near               ;in PROCESOR.ASM
;----------------------------------------------------------------------

HookFP Proc Far                             ;let BASIC get at them too
HookFP Endp

P$HookFP    Proc Far

    Assume  CS:PDQ_FP, DS:DGROUP, ES:Nothing, SS:DGROUP

;----------------------------------------------------------------------------
;   Save registers
;----------------------------------------------------------------------------
    Push    SI
    Push    BP
    Push    DS

    Cmp     P$87Used,-1             ;do we already know that an '87 is used?
    Je      Chip_There              ;yes, skip testing again
;----------------------------------------------------------------------------
;   Confirm the presence of a math coprocessor.
;----------------------------------------------------------------------------
    Xor     AX,AX                   ;create a zero
    Push    AX
    Mov     BP,SP                   ;point to it

    FNSTCW  [BP]                    ;attempt to store the Control word

    Pop     AX
    Cmp     AH,3                    ;if these bits are not set there's no '87
    Je      Chip_There

    Push    CS                      ;there is no coprocessor in this machine
    Pop     DS
    Assume  DS:PDQ_FP

    Mov     DX,Offset No_Chip
    Mov     AH,9                    ;select Display String service
    Int     21h

    Mov     AX,4CFFh                ;select end the program service
    Int     21h                     ;terminate the program

 No_Chip:   DB  "Math coprocessor required.$"

 Chip_There:
;----------------------------------------------------------------------
;   Set P$87Used to show an '87 is being used, and save the existing
;   interrupt vectors to storage defined in P$UnHookFP.
;----------------------------------------------------------------------
    Mov     P$87Used,-1
    Mov     AX,3534h                ;service 35h in AH, INT 34h in AL
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

    Mov     DX,Offset PDQ_FP:P$Int_87   ;conversion routine
    Mov     CX,10
    Mov     AX,2534h                ;point Interrupt 34h - 3Dh to our handler

 Tell_New_Int:
    Int     21h                     ;call DOS to do it
    Inc     AL
    Loop    Tell_New_Int

;----------------------------------------------------------------------------
;   Restore registers. Return
;----------------------------------------------------------------------------
    Pop     DS
    Pop     BP
    Pop     SI

    FNINIT

    Ret
P$HookFP EndP
;----------------------------------------------------------------------

    PDQ_FP          EndS
;======================================================================

END
