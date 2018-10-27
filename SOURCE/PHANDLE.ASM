;********** PHANDLE.ASM - this holds the current print handle, defaults to 1

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Public P$PrintHandle        ;so everyone else can find it

.Data
    P$PrintHandle DW 1          ;1 = screen, 4 = LPT1:

End
