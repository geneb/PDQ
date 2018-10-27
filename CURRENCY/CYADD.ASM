;*********** CYADD.ASM - Cur1@ + Cur2@

.Model Medium, Basic
.Code

__aFCyAdd Proc                      ;alias procedure name
__aFCyAdd Endp

__CyAdd Proc

    Push BP
    Mov  BP,SP
    Push SI
    Lea  SI,Word Ptr [BP+06]
    Lodsw
    Add  Word Ptr [BP+0Eh],AX
    Lodsw
    Adc  Word Ptr [BP+10h],AX
    Lodsw
    Adc  Word Ptr [BP+12h],AX
    Lodsw
    Adc  Word Ptr [BP+14h],AX
    Pop  SI
    Pop  BP
    Retf 8
    
__CyAdd Endp

End
