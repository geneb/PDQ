;********* EXITFUNC.ASM - this exits a BASIC 7 FUNCTION when ON ERROR is used

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Code

B$EXTS Proc                 ;we don't actually need to do anything here
    Ret                     ;so simply return
B$EXTS Endp
End
