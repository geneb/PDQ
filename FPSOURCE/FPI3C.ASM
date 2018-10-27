;FPI3C.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   03/14/91    .000    Original

;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          P$Int3C             ;Proc Interrupt Handler
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
        Extrn       Spare_Real      :TByte              ;in FP_STACK.ASM
;----------------------------------------------------------------------
    DSEG            ENDS
;======================================================================


;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
    USEG            SEGMENT WORD    PUBLIC  'BSS'
    USEG            ENDS
;======================================================================


;======================================================================
; Code segment.
;----------------------------------------------------------------------
    PDQ_FP          SEGMENT WORD    PUBLIC  'CODE'

    ASSUME  CS:PDQ_FP
;----------------------------------------------------------------------
    Extrn           P$Int34_3C      :Near               ;in FPI34_35.ASM
    Extrn           P$Int35_3C      :Near               ;in FPI34_35.ASM
    Extrn           P$Int36_3C      :Near               ;in FPI36_37.ASM
    Extrn           P$Int37_3C      :Near               ;in FPI36_37.ASM
    Extrn           P$Int38_3C      :Near               ;in FPI38_39.ASM
    Extrn           P$Int39_3C      :Near               ;in FPI38_39.ASM
    Extrn           P$Int3A_3C      :Near               ;in FPI3A_3B.ASM
    Extrn           P$Int3B_3C      :Near               ;in FPI3A_3B.ASM
;----------------------------------------------------------------------



;----------------------------------------------------------------------
; P$Int3C Handles interrupt 3Ch which does Segment overrides.  The caller's
; segment values for CS, and ES are sent here on the stack as passed
; parameters.  Also, an instruction word between 0-255, and tells which
; segment to use CS, ES, or SS.  And what do do, FLD, FST, FADD, etc...
;----------------------------------------------------------------------
P$Int3C     Proc Near

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Create stack frame
;----------------------------------------------------------------------
    Mov     BP,SP

;----------------------------------------------------------------------
;   Passed parameters and incoming registers are now prepared to be used
;   as follows:
;
;   [BP+2] = Caller's ES
;   [BP+4] = Caller's CS
;   [BP+6] = Caller's instruction byte:  "SS ??? FF I"
;   Where:
;
;    SS = Segment override bits
;    FF = Format bits
;    I  = Low/ High interrupt # ie 34h v. 35h, for I=0, and I=1, respectively
;
;
;   AX incoming holds Reg portion of Mode/REG/R-M byte (also DL)
;
;   CL incoming holds Mode/REG/R-M byte
;   CH incoming holds Mode portion of Mode/REG/R-M byte
;   DL incoming holds Reg portion of Mode/REG/R-M byte
;   DH incoming holds R-M portion of Mode/REG/R-M byte
;
;   Carry is set (ie. CH = 3) for a 2-register instruction
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;   Determination based upon the type of number.  Bits "FF", and "I"
;----------------------------------------------------------------------
    Mov     BX,Offset P$Int3B_3C    ;for Short Integer
    Push    BX
    Mov     BX,Offset P$Int3A_3C
    Push    BX

    Mov     BX,Offset P$Int39_3C    ;for Long Real
    Push    BX
    Mov     BX,Offset P$Int38_3C
    Push    BX

    Mov     BX,Offset P$Int37_3C    ;for Short Integer
    Push    BX
    Mov     BX,Offset P$Int36_3C
    Push    BX

    Mov     BX,Offset P$Int35_3C    ;for Short Real
    Push    BX
    Mov     BX,Offset P$Int34_3C
    Push    BX

    PushF
    Mov     BX,[BP+6]
    And     BX,7
    Shl     BX,1
    Add     BX,SP
    Add     BX,2
    PopF
    Push    BX


;----------------------------------------------------------------------
;   Get the caller's instruction byte to determine which segment override
;----------------------------------------------------------------------
    Mov     BX,[BP+6]
    Rol     BL,1
    Rol     BL,1

;----------------------------------------------------------------------
    And     BX,3
    Jnz     @F

    Push    DS          ;caller used DS override

 @@:
;----------------------------------------------------------------------
    Dec     BX
    Jnz     @F

    Push    SS          ;caller used SS override

 @@:
;----------------------------------------------------------------------
    Dec     BX
    Jnz     @F

    Push    [BP+4]      ;caller used CS override

 @@:
;----------------------------------------------------------------------
    Dec     BX
    Jnz     @F

    Push    [BP+2]      ;caller used ES override

 @@:
;----------------------------------------------------------------------
    Pop     DS          ;execute the segment override
    Assume  DS:Nothing

    Pop     BX
    Call    Word Ptr SS:[BX]
    Add     SP,16
    Ret     6

P$Int3C     EndP
;----------------------------------------------------------------------

    PDQ_FP      EndS
;======================================================================

END
