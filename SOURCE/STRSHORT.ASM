;********** STRSHORT.ASM - reports how many additional bytes were needed

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    Extrn P$BytesShort:Word ;this is in STR#####.ASM

.Code

StringShort Proc

    Mov  AX,P$BytesShort    ;return the number of bytes as the function output
    Ret                     ;back to BASIC

StringShort Endp
End
