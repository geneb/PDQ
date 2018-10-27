;********* GET1LONG.ASM - PDQ routine to access dynamic memory

;Copyright (c) 1989 Ethan Winer


;Syntax - Value = Get1Long&(Segment, Element)
;
;Where Segment was obtained earlier using AllocMem, and Element is the
;element number to retrieve.

.Model Medium, Basic
.Code

Get1Long Proc, MemSeg:Word, Element:Word

    Mov  BX,MemSeg        ;get the address for Segment%
    Mov  ES,[BX]          ;put it into ES
    Mov  BX,Element       ;get the address for Element%
    Mov  BX,[BX]          ;put it into BX for indexing
    Dec  BX               ;adjust to zero based
    Shl  BX,1             ;adjust element number to long offset
    Shl  BX,1             ;twice because each element is four bytes
    Les  AX,ES:[BX]       ;get both words at once
    Mov  DX,ES            ;and then transfer the high word to DX
    Ret                   ;return to caller

Get1Long Endp
End
