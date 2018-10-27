;********** PDQREST.ASM - fakes a RESTORE when using the PDQParse routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    Extrn P$NextChar:Word   ;this is in PDQPARSE.ASM

.Code

PDQRestore Proc             ;this resets parsing to start at the beginning

    Mov  P$NextChar,0
    Ret

PDQRestore Endp
End
