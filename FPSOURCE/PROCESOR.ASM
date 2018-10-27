;PROCESOR.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;written by Paul Passarelli


;   NOTE: DO NOT USE /E WITH THIS FILE.  It will assemble, but CRASH!!!
;
;   03/01/91    .000    Reconstruct
;   03/07/91    .001    Comment processor secection.  Cleanup.
;   04/11/91    .002    Extract from P$HOOKFP
;   04/12/91    .003    Brought FIXUP values in from FIXUPS.ASM
;   08/30/91    .004    Removed Wait in P$INT_87 per R.H.
;   12/11/91    .005    Combined INT 3Dh with P$Int_87

;======================================================================
; Fixup values to service floating point interrupts.
;----------------------------------------------------------------------
    FIARQQ  Equ 0FE32h      ;Used with DS override  (3Eh)   32³FE³
    FJARQQ  Equ 04000h      ;                                 ³00³40

    FICRQQ  Equ 00E32h      ;Used with CS override  (2Eh)   32³0E³
    FJCRQQ  Equ 0C000h      ;                                 ³00³C0

    FIDRQQ  Equ 05C32h      ;No segment override

    FIERQQ  Equ 01632h      ;Used with ES override  (26h)   32³16³
    FJERQQ  Equ 0           ;not required or used             ³00³00

    FISRQQ  Equ 00632h      ;Used with SS override  (36h)   32³06³
    FJSRQQ  Equ 08000h      ;                                 ³00³80

    FIWRQQ  Equ 0A23Dh      ;Changes INT 3Dh to FWait
;----------------------------------------------------------------------
;Note:   Microsoft Knowledge Base says: "0xde9b bad fixup"
;======================================================================



;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          P$INT_87                ;Proc Far
    Public          FIARQQ                  ;Equate
    Public          FJARQQ                  ;Equate
    Public          FICRQQ                  ;Equate
    Public          FJCRQQ                  ;Equate
    Public          FIDRQQ                  ;Equate
    Public          FIERQQ                  ;Equate
    Public          FISRQQ                  ;Equate
    Public          FJSRQQ                  ;Equate
    Public          FIWRQQ                  ;Equate
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


;----------------------------------------------------------------------
; P$INT_87 converts a floating point interrupt back to the original
;          coprocessor instruction.  Then it returns execution to that
;          instruction which the coprocessor executes.
;----------------------------------------------------------------------
P$INT_87 Proc

    Assume  CS:PDQ_FP, DS:DGROUP, ES:Nothing, SS:DGROUP

;----------------------------------------------------------------------
;   Restore maskable interrupts, clear direction flag, synchronize
;   processors, create stack frame, and save registers.
;----------------------------------------------------------------------
    Sti
    Cld
    Push    BP
    Mov     BP,SP

    Push    AX
    Push    SI
    Push    DS

;----------------------------------------------------------------------
;   To determine which interrupt was used, put the number in AL
;----------------------------------------------------------------------
    Lds     SI,[BP+2]           ;DS gets callers CS, SI gets callers IP
    Assume  DS:Nothing

    Mov     AL,[SI-1]

;----------------------------------------------------------------------
;   Regardless of the INT have SI and caller's CS:IP point back to the
;   beginning of the instruction just executed.
;----------------------------------------------------------------------
    Sub     SI,2
    Mov     [BP+2],SI

;----------------------------------------------------------------------
;   Was it Interrupt 3Ch?
;----------------------------------------------------------------------
    Cmp     AL,3Ch
    Je      Int_3C


;----------------------------------------------------------------------
;   Was it Interrupt 3Dh?
;----------------------------------------------------------------------
    Cmp     AL,3Dh
    Jne     @F

    Mov     AX,FIWRQQ           ;the "Magic Number"
    Sub     Word Ptr [SI],AX    ;change "INT ##" to "F???"
    Jmp     Short Exit


 @@:
;----------------------------------------------------------------------
;   Change INT ?? [arg] to coprocessor instruction
;----------------------------------------------------------------------
 Int_34_3B:
    Mov     AX,FIDRQQ           ;the "Magic Number"
    Sub     Word Ptr [SI],AX    ;change "INT ##" to "F???"
    Jmp     Short Exit


;----------------------------------------------------------------------
;   Perform special handling for INT 3Ch
;----------------------------------------------------------------------
 Int_3C:
    Mov     AL,[SI+2]           ;we know "CD 3C ??", we need "??"
    Rol     AL,1
    Rol     AL,1

    And     AX,3
    Jnz     @F
    Mov     AX,FIARQQ           ;DS: override
    Sub     Word Ptr [SI],AX    ;transform "INT 3C ??" to "F??? DS:??"
    Mov     AX,FJARQQ
    Sub     Word Ptr [SI+1],AX  ;transform "INT 3C ??" to "F??? DS:??"
    Jmp     Short Exit


 @@:Dec     AX
    Jnz     @F
    Mov     AX,FISRQQ           ;SS: override
    Sub     Word Ptr [SI],AX    ;transform "INT 3C ??" to "F??? SS:??"
    Mov     AX,FJSRQQ
    Sub     Word Ptr [SI+1],AX  ;transform "INT 3C ??" to "F??? SS:??"
    Jmp     Short Exit


 @@:Dec     AX
    Jnz     @F
    Mov     AX,FICRQQ           ;CS: override
    Sub     Word Ptr [SI],AX    ;transform "INT 3C ??" to "F??? CS:??"
    Mov     AX,FJCRQQ
    Sub     Word Ptr [SI+1],AX  ;transform "INT 3C ??" to "F??? CS:??"
    Jmp     Short Exit

 @@:;Dec     AX
    ;Jnz     @F
    Mov     AX,FIERQQ           ;ES: override
    Sub     Word Ptr [SI],AX    ;transform "INT 3C ??" to "F??? ES:??"
    ;Mov     AX,FJERQQ
    ;Sub     Word Ptr [SI+1],AX ;transform "INT 3C ??" to "F??? ES:??"
    Jmp     Short Exit

;@@:                            ;just to maintain structure

;----------------------------------------------------------------------
;   Restore registers. Return from interrupt to where we started.
;----------------------------------------------------------------------
 Exit:
    Pop     DS
    Assume  DS:DGROUP

    Pop     SI
    Pop     AX

    Pop     BP

    IRet

P$INT_87    EndP
;----------------------------------------------------------------------

    PDQ_FP          EndS
;======================================================================
END
