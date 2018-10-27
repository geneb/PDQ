;********* BLOCKOPY.ASM - copies a block of memory from here to there

;Copyright (c) 1989 Ethan Winer


;Syntax - CALL BlockCopy(FromSeg%, FromAddr%, ToSeg%, ToAddr%, NumBytes%)

.Model Medium, Basic
.Code

BlockCopy Proc Uses SI DI DS, FromSeg:Word, FromAdr:Word, ToSeg:Word, ToAdr:Word, NumBytes:Word

    Mov  BX,FromAdr        ;get pointer to FromAddr%
    Mov  SI,[BX]           ;put into SI

    Mov  BX,ToSeg          ;pointer to ToSeg%
    Mov  ES,[BX]           ;put it into ES

    Mov  BX,ToAdr          ;pointer to ToAddr%
    Mov  DI,[BX]           ;put it into DI

    Mov  BX,NumBytes       ;pointer to NumBytes%
    Mov  CX,[BX]           ;put it into CX

    Mov  BX,FromSeg        ;pointer to FromSeg%
    Mov  DS,[BX]           ;put segment in DS

    Cld                    ;copy in the forward direction
    Rep  Movsb             ;do the move: [DS:SI] ---> [ES:DI]
    Ret                    ;return to BASIC

BlockCopy Endp
End
