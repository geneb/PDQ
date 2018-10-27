;B$FUST.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   Use "MASM /E" for the Emulator Library
;
;   02/27/91    .000    Reconstruct


;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          B$FUST              ;Far Proc


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
        ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:NOTHING, SS:DGROUP


;----------------------------------------------------------------------
;   B$FUST  Comment to follow!
;----------------------------------------------------------------------
B$FUST      Proc Far

    PUSH    BP
    MOV     BP,SP
    SUB     SP,+04

    FISTP   DWord Ptr [BP-04]       ;INT 37h    CD375EFC
    FWAIT                           ;INT 3Dh    CD3D

    CMP     Word Ptr [BP-02],+00
    JZ      @F                      ;B$FUST+1Ch

    FILD    DWord Ptr [BP-04]       ;INT 37h    CD3746FC
    FISTP   Word Ptr [BP-04]        ;INT 3Bh    CD3B5EFC
    FWAIT                           ;INT 3Dh    CD3D

 @@:POP     AX
    ADD     SP,+02
    MOV     SP,BP
    POP     BP
    RETF
    
B$FUST      EndP
;----------------------------------------------------------------------

    PDQ_FP          EndS
    
END
