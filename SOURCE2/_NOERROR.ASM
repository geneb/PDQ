;********** _NOERROR.ASM - limited P$DoError without support for ON ERROR

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM

.Code

P$DoError Proc

    Cmp  Byte Ptr P$PDQErr,0;did the Int24 critical error handler set this?
    Jne  Exit               ;yes, so leave the error as it is
    Mov  P$PDQErr,AX        ;no, use what's in AX

Exit:
    Ret
    
P$DoError Endp
End
