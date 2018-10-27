;P$HOOKFP.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;written by Paul Passarelli


;   NOTE: DO NOT USE /E WITH THIS FILE. IT WON'T WORK ANYHOW!!!
;
;   03/01/91    .000    Reconstruct
;   03/07/91    .001    Comment processor section.  Cleanup.
;   04/11/91    .002    Remove P$UnHook, P$Int_87
;   04/18/91            Unable to INIT Emulator from here
;   12/11/91    .003    Reduced Tell_New_Int loop for changes in EMULATOR.ASM
;                       and PROCESOR.ASM for combined INT 3Dh code.

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
;----------------------------------------------------------------------
    Math_Tool       DW      P$INT_87        ;Selected FP handler
    P$87Used        DB      0               ;default to '87 not active
;----------------------------------------------------------------------
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
    ASSUME  CS:PDQ_FP
;----------------------------------------------------------------------
    Extrn   P$Int_EM    :Near               ;in EMULATOR.ASM
    Extrn   P$Int_87    :Near               ;in PROCESOR.ASM
;----------------------------------------------------------------------


HookFP Proc Far                             ;let BASIC get at them too
HookFP Endp

;----------------------------------------------------------------------
;   P$HookFP Determines the presence of a coprocessor at runtime.
;            Also installs interrupt vector table to use an 80x87 if present
;            or use the emulator library subset.
;----------------------------------------------------------------------
P$HookFP    Proc Far

    ASSUME  CS:PDQ_FP, DS:DGROUP, ES:Nothing, SS:DGROUP

;----------------------------------------------------------------------
;   Save registers
;----------------------------------------------------------------------
    Push    SI
    Push    BP
    Push    DS

;----------------------------------------------------------------------
;   Determine the presence of a math coprocessor.  Assume 80x87 present.
;----------------------------------------------------------------------
    Xor     AX,AX                   ;create a zero
    Push    AX                      ;on the stack
    Mov     BP,SP                   ;point to it

    FNSTCW  [BP]                    ;attempt to store the Control word

    Pop     AX
    Cmp     AH,3                    ;if these bits are not set there's no '87
    Je      Chip_There              ;our assumption was correct

;----------------------------------------------------------------------
;   Otherwise we'll use the emulator library
;----------------------------------------------------------------------
    Mov     Math_Tool,Offset PDQ_FP:P$INT_EM
    Jmp     Short @F                ;skip over setting P$87Used

Chip_There:
;----------------------------------------------------------------------
;   Set P$87Used to show an '87 is being used, and save the existing
;   interrupt vectors to storage defined in P$UnHookFP.
;----------------------------------------------------------------------
    Mov     P$87Used,-1

@@:
    Mov     AX,3534h                ;service 35h in AH, INT# 34h in AL
    Mov     CX,10                   ;for Interrupt 34h - 3Dh
    Mov     SI,Offset DGroup:OldFPInts  ;local storage

 Save_Old_Int:
    Int     21h                     ;via DOS
    Mov     [SI],BX                 ;save the address
    Mov     [SI+2],ES               ;save the segment
    Add     SI,4                    ;point to the next storage area
    Inc     AL                      ;select the next interrupt
    Loop    Save_Old_Int


;----------------------------------------------------------------------
;   Now redirect the floating point interrupts to ourselves
;----------------------------------------------------------------------
    Push    CS                      ;here's the segment
    Pop     DS                      ;which DOS wants in DS
    Assume  DS:PDQ_FP

    Mov     DX,Math_Tool            ;80x87 support vs. Emulator Lib

    Mov     CX,10
    Mov     AX,2534h                ;point Interrupt 34h-3Dh to our handler

 Tell_New_Int:
    Int     21h                     ;call DOS to do it
    Inc     AL
    Loop    Tell_New_Int


;----------------------------------------------------------------------
;   Restore registers. Return
;----------------------------------------------------------------------
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
