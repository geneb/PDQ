;********** PDQPEEK2.ASM - peeks a word instead of a byte

;Copyright (c) 1989 Ethan Winer


;Syntax:
;    DEF SEG = Segment
;    Value = PDQPeek2%(Address)


.Model Medium, Basic
.Data
    Extrn B$Seg:Word      ;this is in PDQDATA.ASM

.Code

PDQPeek2 Proc, Address:Word

    Mov  ES,B$Seg         ;put the current DEF SEG setting into ES
    Mov  BX,Address       ;get the address for Address
    Mov  BX,[BX]          ;put it into BX
    Mov  AX,ES:[BX]       ;PEEK the word
    Ret                   ;return to BASIC

PDQPeek2 Endp
End
