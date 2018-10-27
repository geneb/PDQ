;********** DIVLONG3.ASM - 80386 PDQ replacement for BASIC's B$DVI4 routine

;Copyright (c) 1989 Crescent Software

;This routine divides two long integers.


.Model Medium, Basic
.Code
.386                      ;this 386 directive MUST go after the .Code

B$DVI4 Proc, Y:DWord, X:DWord

    Mov  EAX,X            ;load EAX with the number to divide
    Xor  EDX,EDX          ;clear EDX so we don't confuse the issue
    IDiv DWord Ptr Y      ;divide it
    Push EAX              ;push the answer onto the stack
    Pop  AX               ;retrieve it as two bytes in DX:AX
    Pop  DX
    Ret                   ;return to BASIC

B$DVI4 Endp
End
