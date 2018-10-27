;********** SETMEM.ASM - "empty" replacement for SETMEM, satisifies Stay-Res

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
.Code

B$SETM Proc             ;this routine is passed four bytes on the stack

    Ret  4              ;return to caller

B$SETM Endp
End
