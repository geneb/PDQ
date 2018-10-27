;********* GET1BYTE.ASM - PDQ routine to access dynamic memory

;Copyright (c) 1989 Ethan Winer


;Syntax - Value = Get1Byte%(Segment%, Element%)
;
;Where Segment% was obtained earlier using AllocMem, and Element% is the
;element number to retrieve.

.Model Medium, Basic
.Code

Get1Byte Proc, MemSeg:Word, Element:Word

    Mov  BX,MemSeg        ;get the address for Segment%
    Mov  ES,[BX]          ;put it into ES
    Mov  BX,Element       ;get the address for Element%
    Mov  BX,[BX]          ;put it into BX for indexing
    Dec  BX               ;adjust to zero based
    Mov  AL,ES:[BX]       ;get the byte
    Cbw                   ;convert to a full word (-128 to 127)
;   Xor  AH,AH            ;use this instead of the line above to return 0-255
    Ret                   ;return to caller

Get1Byte Endp
End
