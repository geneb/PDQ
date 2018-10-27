;********** STRUSED.ASM - reports how many bytes are in use by the string pool

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    Extrn P$BytesUsed:Word ;this is in STR#####.ASM

.Code

StringUsed Proc

    Mov  AX,P$BytesUsed    ;return the number of bytes as the function output
    Ret                    ;back to BASIC

StringUsed Endp
End
