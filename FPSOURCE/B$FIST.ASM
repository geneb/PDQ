;B$FIST.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   Use "MASM /E" for the Emulator Library
;
;   02/27/91    .000    Reconstruct


;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          B$FIS2              ;Far Proc
    Public          B$FIST              ;Far Proc


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
;   B$FIS2  Converts the value in ST(0) to a "Word Integer" returned
;           in AX, the value is popped from the FP Stack.
;
;   Input:  Numeric data popped from the FP stack (temporary real format)
;   Result: Signed integer value in AX, default rounding in effect
;   Assume: Result will be ST(0) MOD 65536
;   Regs:   AX = result
;           Others unchanged
;   Flags:  Unchanged
;----------------------------------------------------------------------
B$FIS2      Proc Far

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
    Push    BP              ;save BP
    Push    AX              ;make room for integer on the stack
    Mov     BP,SP           ;BP points to the integer (on the stack)

    FISTP   Word Ptr [BP]
    FWAIT
    
    Pop     AX              ;get result
    Pop     BP              ;restore BP
    RetF

B$FIS2      EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   B$FIST  Converts the value in ST(0) to a "Short Integer" (32 bit)
;           returned in DX:AX, the value is popped from the FP Stack.
;
;   Input:  Numeric data popped from the FP stack (temporary real format)
;   Result: Signed integer value in DX:AX, default rounding in effect
;   Assume: Result will be ST(0) MOD 65536 ^ 2
;   Regs:   DX:AX = result
;           Others unchanged
;   Flags:  Unchanged
;----------------------------------------------------------------------
B$FIST      Proc Far

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
    Push    BP              ;save BP
    Push    DX              ;make room for high and low words on the stack
    Push    AX
    Mov     BP,SP           ;BP points to the long integer (on the stack)

    FISTP   DWord Ptr [BP]
    FWAIT

    Pop     AX
    Pop     DX
    Pop     BP
    RetF

B$FIST EndP

    PDQ_FP          EndS

END
