;*********** CYSTORE.ASM - store Cur@ from the stack

.Model Medium, Basic
.Code

__aFCySt Proc                       ;alias procedure name
__aFCySt Endp

__CySt Proc

    Pop  CX
    Pop  DX
    Pop  Word Ptr [BX]
    Pop  Word Ptr [BX+02]
    Pop  Word Ptr [BX+04]
    Pop  Word Ptr [BX+06]
    Push DX
    Push CX
    Ret
    
__CySt Endp

End
