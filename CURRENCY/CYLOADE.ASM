;*********** CYLOADE.ASM - load ES:[Cur@] onto the stack

.Model Medium, Basic
.Code

__aFCyLdE Proc                      ;alias procedure name
__aFCyLdE Endp

__CyLdE Proc

    Pop  CX
    Pop  DX
    Push Word Ptr ES:[BX+06]
    Push Word Ptr ES:[BX+04]
    Push Word Ptr ES:[BX+02]
    Push Word Ptr ES:[BX]
    Push DX
    Push CX
    Ret
    
__CyLdE Endp

End
