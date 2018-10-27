;********** PDQPOKE2.ASM - pokes a word instead of a byte

;Copyright (c) 1989 Ethan Winer


;Syntax:
;    DEF SEG = Segment
;    CALL PDQPoke2(Address, Value)


.Model Medium, Basic
.Data
    Extrn B$Seg:Word      ;this is in PDQDATA.ASM

.Code

PDQPoke2 Proc, Address:Word, Value:Word

    Mov  ES,B$Seg         ;put the current DEF SEG setting into ES
    Mov  BX,Value         ;get the address for Value
    Mov  AX,[BX]          ;put it into AX
    Mov  BX,Address       ;get the address for Address
    Mov  BX,[BX]          ;put it into BX
    Mov  ES:[BX],AX       ;POKE the word
    Ret                   ;return to BASIC

PDQPoke2 Endp
End
