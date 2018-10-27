;********** PDQSETWD.ASM - sets the screen width for PDQPrint and PDQCPrint

;Copyright (c) 1989 Ethan Winer

;syntax: CALL PDQSetWidth(NewWidth)


.Model Medium, Basic
.Data
    Extrn P$PrintWidth:Word ;this is in PDQPWIDE.ASM

.Code

PDQSetWidth Proc, NewWidth:Word

    Mov  BX,NewWidth        ;get the address for NewWidth
    Mov  BX,[BX]            ;get the actual width value in columns
    Shl  BX,1               ;convert columns to bytes (to include attribute)
    Mov  P$PrintWidth,BX    ;save it where PDQPrint and PDQCPrint can find it
    Ret                     ;back to BASIC

PDQSetWidth Endp
End
