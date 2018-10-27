;********* SET1BYTE.ASM - PDQ routine to access dynamic memory

;Copyright (c) 1989 Ethan Winer


;Syntax - CALL Set1Byte(Segment%, Element%, Value%)
;
;Where Segment% was obtained earlier using AllocMem, Element% is the element
;number to assign, and Value is the value.

.Model Medium, Basic
.Code

Set1Byte Proc, MemSeg:Word, Element:Word, Value:Word

    Mov  BX,MemSeg        ;get the address for Segment%
    Mov  ES,[BX]          ;put it into ES
    Mov  BX,Value         ;get the address for Value%
    Mov  AL,[BX]          ;put Value% into AL
    Mov  BX,Element       ;get the address for Element%
    Mov  BX,[BX]          ;put it into BX for indexing
    Dec  BX               ;adjust to zero based
    Mov  ES:[BX],AL       ;assign the byte
    Ret                   ;return to caller

Set1Byte Endp
End
