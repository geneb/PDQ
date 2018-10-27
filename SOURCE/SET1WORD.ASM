;********* SET1WORD.ASM - PDQ routine to access dynamic memory

;Copyright (c) 1989 Ethan Winer


;Syntax - CALL Set1Word(Segment%, Element%, Value%)
;
;Where Segment% was obtained earlier using AllocMem, Element% is the element
;number to assign, and Value% it its value.

.Model Medium, Basic
.Code

Set1Word Proc, MemSeg:Word, Element:Word, Value:Word

    Mov  BX,MemSeg        ;get the address for Segment%
    Mov  ES,[BX]          ;put it into ES
    Mov  BX,Value         ;get the address for Value%
    Mov  AX,[BX]          ;put it into AX
    Mov  BX,Element       ;get the address for Element%
    Mov  BX,[BX]          ;put it into BX for indexing
    Dec  BX               ;adjust to zero based
    Shl  BX,1             ;adjust element number to word offset
    Mov  ES:[BX],AX       ;assign the word
    Ret                   ;return to caller

Set1Word Endp
End
