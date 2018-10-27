;*********** CYABS.ASM - ABS(Cur@) where Cur@ is on the stack

.Model Medium, Basic
.Code

__aFCyAbs Proc                      ;alias procedure name
__aFCyAbs Endp

__CyAbs Proc

    Push BP
    Mov  BP,SP
    Test Byte Ptr [BP+0Dh],80h      ;test highest bit in Cur@
    Jnz  __Cychs + 3                ;it's negative so go change sign below
    Pop  BP
    Ret
    
__CyAbs Endp



__aFCyChs Proc                      ;alias procedure name
__aFCyChs Endp

__CyChs Proc                        ;Change Sign of Cur@ on the stack
    Push BP
    Mov  BP,SP

;__CyChs+3:
    Xor  DX,DX
    Mov  AX,1
    Not  Word Ptr [BP+06]
    Add  Word Ptr [BP+06],AX
    Not  Word Ptr [BP+08]
    Adc  Word Ptr [BP+08],DX
    Not  Word Ptr [BP+0Ah]
    Adc  Word Ptr [BP+0Ah],DX
    Not  Word Ptr [BP+0Ch]
    Adc  Word Ptr [BP+0Ch],DX
    Pop  BP
    Retf
__CyChs Endp

End
