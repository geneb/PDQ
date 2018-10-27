;********* MULTLNG3.ASM - 80386 PDQ replacement for BASIC's B$MUI4 routine

;Copyright (c) 1989 Crescent Software

;This routine multiplies two long integers.


.Model Medium, Basic
.Code
.386                      ;this 386 directive MUST go after the .Code

B$MUI4 Proc, Y:DWord, X:DWord

    Mov  EAX,X            ;load EAX with the first number
    IMul DWord Ptr Y      ;multiply it times the second
    Push EAX              ;push the result onto the stack
    Pop  AX               ;retrieve it as two bytes in DX:AX
    Pop  DX
    Ret                   ;return to BASIC

B$MUI4 Endp
End
