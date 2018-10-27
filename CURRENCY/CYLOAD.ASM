;*********** CYLOAD.ASM - load Cur@ onto the stack

.Model Medium, Basic
.Code

__aFCyLd Proc                       ;alias procedure name
__aFCyLd Endp

__CyLd Proc

    Pop  CX
    Pop  DX
    Push Word Ptr [BX+06]
    Push Word Ptr [BX+04]
    Push Word Ptr [BX+02]
    Push Word Ptr [BX]
    Push DX
    Push CX
    Ret
    
__CyLd Endp

End
