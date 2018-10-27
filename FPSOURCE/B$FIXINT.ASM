;B$FIXINT.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   Use "MASM /E" for the Emulator Library
;
;   02/27/91    .000    Reconstruct


;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          B$FIX4              ;Far Proc
    Public          B$FIX8              ;Far Proc
    Public          B$INT4              ;Far Proc
    Public          B$INT8              ;Far Proc
    

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
;   B$FIX4, B$FIX8  Truncate the fractional portion of ST(0)
;
;   Input:  Value in ST(0)
;   Result: Truncated value will be ST(0) MOD 65536 ^ 2
;----------------------------------------------------------------------
B$FIX4      Proc Far
B$FIX8      Proc Far

    Push    AX          ;save AX
    Mov     AX,0C00h    ;to set the Rounding Control to Chop
    Jmp Short Fix_Int
    


;----------------------------------------------------------------------
;   B$INT4, B$INT8  Remove the fractional portion of ST(0) by rounding
;
;   Input:  Value in ST(0)
;   Result: Rounded value will be ST(0) MOD 65536 ^ 2
;----------------------------------------------------------------------
B$INT4      Proc Far
B$INT8      Proc Far

    Push    AX          ;save AX
    Mov     AX,0400h    ;to set the Rounding Control to Round Down
    ;Jmp Short Fix_Int  ;this just falls into FIX_INT



;----------------------------------------------------------------------
;   FIX_INT completes the conversion of floating point value in ST(0)
;           to integer form by temporarily changing "Rounding Control"
;           bits of the 80x87.
;
;   Input:  AX = mask of RC bits "....XX.........." ("." = 0, "XX" = RC bits)
;           Caller's AX is preserved on stack
;   Result: Fractional portion of ST(0) removed.
;   Regs:   Unchanged
;   Flags:  Unchanged
;----------------------------------------------------------------------
Fix_Int     Proc Near               ;Internal

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
; Create local storage and the stack frame.
;----------------------------------------------------------------------
    Sub     SP,6                    ;Local work/storage space
    Push    BP                      ;save BP
    Mov     BP,SP                   ;Stack Frame


;----------------------------------------------------------------------
; Save the old and establish the new Control Word.
;----------------------------------------------------------------------
    FSTCW   [BP+6]                  ;save the current Control Word
    FWAIT
    
    Or      AX,[BP+6]               ;calculate new Rounding Control
    Mov     [BP+2],AX               ;put it in the work space

    FLDCW   [BP+2]                  ;set the Control Word's new "RC"

;----------------------------------------------------------------------
; do the FIX / INT.
;----------------------------------------------------------------------
    FISTP   DWord Ptr [BP+2]
    FILD    DWord Ptr [BP+2]

;----------------------------------------------------------------------
; Restore the original status and return.
;----------------------------------------------------------------------
    FLDCW   [BP+6]                  ;restore the original Control Word
    FWAIT
    
    Pop     BP                      ;recover BP
    Add     SP,6                    ;remove the local storage

    Pop     AX                      ;on the stack from B$FIX or B$INT

    RetF

Fix_Int     EndP

B$INT8      EndP
B$INT4      EndP

B$FIX8      EndP
B$FIX4      EndP


    PDQ_FP          EndS

END
