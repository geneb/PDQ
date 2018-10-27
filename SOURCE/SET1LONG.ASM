;********* SET1LONG.ASM - PDQ routine to access dynamic memory

;Copyright (c) 1989 Ethan Winer


;Syntax - CALL Set1Long(Segment%, Element%, Value&)
;
;Where Segment% was obtained earlier using AllocMem, Element% is the element
;number to assign, and Value& is its value.

.Model Medium, Basic
.Code

Set1Long Proc Uses SI DI, MemSeg:Word, Element:Word, Value:Word

    Mov  BX,MemSeg        ;get the address for Segment
    Mov  ES,[BX]          ;put it into ES
    Mov  SI,Value         ;get the address for Value& (the source)
    
    Mov  BX,Element       ;get the address for Element
    Mov  DI,[BX]          ;put it into DI for indexing (the destination)
    Dec  DI               ;adjust to zero based
    Shl  DI,1             ;adjust element number to long offset
    Shl  DI,1             ;twice because each element is four bytes

    Cld                   ;force copying to be forward
    Movsw                 ;first copy the low word
    Movsw                 ;and then the high word
    Ret                   ;return to caller

Set1Long Endp
End
