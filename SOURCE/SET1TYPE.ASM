;********* SET1TYPE.ASM - PDQ routine to access dynamic memory

;Copyright (c) 1989 Ethan Winer


;Syntax - CALL Set1Type(Segment, Element, Length, TypeVar)
;
;Where Segment was obtained earlier using AllocMem, Element is the element
;number to assign, Length is its length in bytes, and TypeVar is the TYPE
;variable in near memory that is to be assigned.

.Model Medium, Basic
.Code

Set1Type Proc Uses SI DI, MemSeg:Word, Element:Word, Lenth:Word, TypeVar:Word

    Cld                   ;ensure that string moves are forward

    Mov  BX,Element       ;get the address for Element
    Mov  AX,[BX]          ;put it into AX for indexing below
    Mov  BX,Lenth         ;get the address for Length
    Mov  CX,[BX]          ;put it into CX for multiplying
    Mov  SI,TypeVar       ;get the address for TypeVar
    Mov  BX,MemSeg        ;get the address for Segment
    Mov  ES,[BX]          ;put it into ES
    
    Dec  AX               ;adjust the element number to be zero based
    Mul  CX               ;now AX holds the correct offset into far memory
    Mov  DI,AX            ;transfer that to DI for moving bytes
    Rep  Movsb            ;copy the element into the "near" TYPE variable
    Ret                   ;and return to BASIC

Set1Type Endp
End
