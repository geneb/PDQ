;*********** CYSGN.ASM - SGN(Cur@)

.Model Medium, Basic
.Code

B$SGCY Proc

    Push DI
    Push SS
    Pop  ES
    Mov  DI,SP
    Add  DI,6
    Mov  AX,Word Ptr [DI+06]
    Cwd
    Xchg AX,DX
    Or   AX,AX
    Mov  AX,0D8F0h
    Jnz  @F
    Or   DX,Word Ptr [DI+04]
    Or   DX,Word Ptr [DI+02]
    Or   DX,Word Ptr [DI]
    Xor  AX,AX
    Neg  DX
    Jnb  @F
    Mov  AX,2710

@@:
    Cwd
    Stosw
    Xchg AX,DX
    Stosw
    Stosw
    Stosw
    Pop  DI
    Retf
    
B$SGCY Endp

End
