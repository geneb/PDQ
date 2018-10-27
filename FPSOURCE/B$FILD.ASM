;B$FILD.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   Use "MASM /E" for the Emulator Library
;
;   02/27/91    .000    Reconstruct


;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          B$FIL2              ;Far Proc
    Public          B$FILD              ;Far Proc


;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
    DGROUP          GROUP   DSEG,USEG


;======================================================================
; DSEG: Initialized data.
;----------------------------------------------------------------------
    DSEG            SEGMENT WORD    PUBLIC  'DATA'
    DSEG            ENDS


;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
    USEG            SEGMENT WORD    PUBLIC  'BSS'
    USEG            ENDS


;======================================================================
; Code segment.
;----------------------------------------------------------------------
    PDQ_FP          SEGMENT WORD    PUBLIC  'CODE'

    ASSUME  CS:PDQ_FP
;----------------------------------------------------------------------
    


;----------------------------------------------------------------------
;   B$FIL2  Converts a Word Integer to a 32 bit integer, then enters...
;   B$FILD  Loads a 32 bit "Short Integer" into ST(0).
;
;   Input:  AX (B$FIL2) --or-- DX:AX (B$FILD) Signed Integer
;   Result: Numeric data pushed onto the FP stack (temporary real format)
;   Regs:   DX destroyed by B$FIL2, others unchanged
;           Unchanged by B$FILD
;   Flags:  Unchanged
;----------------------------------------------------------------------------
B$FIL2      Proc Far

    Cwd                     ;convert integer in AX to long in DX:AX

B$FILD      Proc Far

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
    Push    BP              ;save BP
    Push    DX              ;push high and low words on the stack
    Push    AX
    Mov     BP,SP           ;have BP point to the long on the stack

    FILD    DWord Ptr [BP]

    Pop     AX              ;restore registers
    Pop     DX
    Pop     BP
    RetF

B$FILD      EndP

B$FIL2      EndP

    PDQ_FP          EndS
    
END
