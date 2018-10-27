;*********** CYSTOREE.ASM - store ES:[Cur@] from the stack

.Model Medium, Basic
.Code


__aFCyStE Proc                      ;alias procedure name
__aFCyStE Endp

__CyStE Proc

    Pop  CX
    Pop  DX
    Pop  Word Ptr ES:[BX]
    Pop  Word Ptr ES:[BX+02]
    Pop  Word Ptr ES:[BX+04]
    Pop  Word Ptr ES:[BX+06]
    Push DX
    Push CX
    Ret
    
__CyStE Endp

End
