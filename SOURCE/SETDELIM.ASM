;********** SETDELIM.ASM - allows use of any delimiter with PDQParse

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    Extrn P$DelimitChar:Byte  ;this is in PDQPARSE.ASM

.Code

SetDelimitChar Proc, Char     ;this lets you use any delimiter, not just a ";"

    Mov  BX,Char              ;get the address for Char
    Mov  BL,[BX]              ;put the character into BL
    Mov  P$DelimitChar,BL     ;save it for PDQParse to use
    Ret                       ;return to BASIC

SetDelimitChar Endp
End
