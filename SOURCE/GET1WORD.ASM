;********* GET1WORD.ASM - PDQ routine to access dynamic memory

;Copyright (c) 1989 Ethan Winer


;Syntax - Value = Get1Word%(Segment%, Element%)
;
;Where Segment% was obtained earlier using AllocMem, and Element% is the
;element number to retrieve.

.Model Medium, Basic
.Code

Get1Word Proc, MemSeg:Word, Element:Word

    Mov  BX,MemSeg        ;get the address for Segment%
    Mov  ES,[BX]          ;put it into ES
    Mov  BX,Element       ;get the address for Element%
    Mov  BX,[BX]          ;put it into BX for indexing
    Dec  BX               ;adjust to zero based
    Shl  BX,1             ;adjust element number to word offset
    Mov  AX,ES:[BX]       ;get the word
    Ret                   ;return to caller

Get1Word Endp
End
