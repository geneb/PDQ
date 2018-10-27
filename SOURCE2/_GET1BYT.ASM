;********* _GET1BYT.ASM - alternate Get1Byte treats numbers as being unsigned

;Copyright (c) 1991 Ethan Winer

;See GET1BYTE.ASM

.Model Medium, Basic
.Code

Get1Byte Proc, MemSeg:Word, Element:Word

    Mov  BX,MemSeg        ;get the address for Segment%
    Mov  ES,[BX]          ;put it into ES
    Mov  BX,Element       ;get the address for Element%
    Mov  BX,[BX]          ;put it into BX for indexing
    Dec  BX               ;adjust to zero based
    Mov  AL,ES:[BX]       ;get the byte
    Xor  AH,AH            ;ignore the high byte (return 0 to 255)
    Ret                   ;return to caller

Get1Byte Endp
End
