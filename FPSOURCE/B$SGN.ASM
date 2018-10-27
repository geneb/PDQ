;B$SGN.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   Use "MASM /E" for the Emulator Library
;
;   02/27/91    .000    Reconstruct


;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          B$SGN4              ;Far Proc
    Public          B$SGN8              ;Far Proc


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
;   B$SGN$, B$SGN8  determine the sign of the value in ST(0)
;
;   Input:  Value in ST(0)
;   Result: ST(0) is replaced by [ -1 | 0 | 1 ]
;   Assume: Valid number in ST
;   Regs:   AX destroyed
;           Others unchanged
;   Flags:  Set for conditional jump
;----------------------------------------------------------------------
B$SGN4      Proc Far
B$SGN8      Proc Far

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
    Push    BP                  ;preserve BP
    Push    AX                  ;create free space on the Stack
    Mov     BP,SP               ;create Stack Frame

    FTST                        ;test the value in ST
    FSTSW   Word Ptr [BP]       ;put result in free space
    FWAIT

    Pop     AX                  ;get the Status Word into AX
    Sahf                        ;get the Status Word into the flags
    Jz      @F                  ;SGN(0) = 0 we're done

    FSTP    ST                  ;otherwise pop the FP Stack
    FLD1                        ;assume it was a positive number

    Ja      @F                  ;we were right

    FCHS                        ;it was negative

 @@:Pop     BP
    RetF

B$SGN8      EndP
B$SGN4      EndP
;----------------------------------------------------------------------

    PDQ_FP          EndS

END
