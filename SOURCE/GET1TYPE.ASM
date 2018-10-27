;********* GET1TYPE.ASM - PDQ routine to access dynamic memory

;Copyright (c) 1989 Ethan Winer


;Syntax - CALL Get1Type(Segment%, Element%, Length%, TypeVar)
;
;Where Segment% was obtained earlier using AllocMem, Element% is the element
;number to retrieve, Length% is its length in bytes, and TypeVar is a TYPE
;variable in near memory that will receive the element.

.Model Medium, Basic
.Code

Get1Type Proc Uses SI DI DS, MemSeg:Word, Element:Word, Lenth:Word, TypeVar:Ptr

    Cld                   ;ensure that string moves are forward
    Push DS               ;copy DS into ES for moving below
    Pop  ES

    Mov  BX,Element       ;get the address for Element%
    Mov  AX,[BX]          ;put it into AX for indexing below
    Mov  BX,Lenth         ;get the address for Length%
    Mov  CX,[BX]          ;put it into CX for multiplying
    Mov  DI,TypeVar       ;get the address for TypeVar
    Mov  BX,MemSeg        ;get the address for Segment%
    Mov  DS,[BX]          ;put it into DS

    Dec  AX               ;adjust the element number to be zero based
    Mul  CX               ;now AX holds the correct offset into far memory
    Mov  SI,AX            ;transfer that to SI for moving bytes
    Rep  Movsb            ;copy the element into the "near" TYPE variable
    Ret                   ;and return to BASIC

Get1Type Endp
End
