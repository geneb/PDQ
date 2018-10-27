;B$FCMP.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   Use "MASM /E" for the Emulator Library
;
;   02/27/91    .000    Reconstruct


;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          B$FCMP              ;Far Proc


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




;----------------------------------------------------------------------
;   B$FCMP  Performs comparisons "=", "<", ">", "<=", ">=", "<>".
;
;   Input:  ST & ST(1) on the floating point stack
;   Result: flags set for conditional jump, ST & ST(1) Popped
;   Assume: valid numbers. not "NAN" or "Proj. Inf."
;   Regs:   Unchanged   (preserved)
;   Flags:  Net result of a signed comparison.
;----------------------------------------------------------------------
B$FCMP      Proc Far

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:Nothing, SS:DGROUP

;----------------------------------------------------------------------
    Push    BP              ;save BP
    Push    AX              ;save AX

    Push    AX              ;reserve some space on the stack
    Mov     BP,SP           ;have BP point to the free space

    FCOMPP
    FSTSW   Word Ptr [BP]
    FWAIT
    
    Pop     AX              ;get the status word off the stack
    Sahf                    ;then put the part we want in the flags

    Pop     AX              ;saved AX
    Pop     BP              ;saved BP

    RetF

B$FCMP EndP

    PDQ_FP          EndS

END
