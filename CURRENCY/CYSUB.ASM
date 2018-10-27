;*********** CYSUB.ASM - Cur1@ - Cur2@

.Model Medium, Basic
.Code

__aFCySub Proc                      ;alias procedure name
__aFCySub Endp

__CySub Proc

    Push BP
    Mov  BP,SP
    Push SI
    Lea  SI,Word Ptr [BP+06]
    Lodsw
    Sub  Word Ptr [BP+0Eh],AX
    Lodsw
    Sbb  Word Ptr [BP+10h],AX
    Lodsw
    Sbb  Word Ptr [BP+12h],AX
    Lodsw
    Sbb  Word Ptr [BP+14h],AX
    Pop  SI
    Pop  BP
    Retf 8
    
__CySub Endp

End
