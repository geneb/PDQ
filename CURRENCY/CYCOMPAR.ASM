;*********** CYCOMPAR.ASM - IF Cur1@ <=> Cur2@ THEN (Compare Currency)

.Model Medium, Basic
.Code

B$CPCY Proc

    Push BP
    Mov  BP,SP
    Mov  AX,Word Ptr [BP+14h]
    Cmp  AX,Word Ptr [BP+0Ch]
    Jnz  Exit
    Push SI
    Lea  BX,Word Ptr [BP+06]
    Lea  SI,Word Ptr [BP+0Eh]
    Jns  @F
    Xchg SI,BX

@@:
    Mov  AX,Word Ptr [SI+04]
    Cmp  AX,Word Ptr [BX+04]
    Jnz  @F
    Mov  AX,Word Ptr [SI+02]
    Cmp  AX,Word Ptr [BX+02]
    Jnz  @F
    Mov  AX,Word Ptr [SI]
    Cmp  AX,Word Ptr [BX]

@@:
    Pop  SI
    Lahf
    And  AX,4100h
    Shr  AX,1
    Shl  AH,1
    Or   AH,AL
    Sahf

Exit:
    Pop  BP
    Retf 10h
    
B$CPCY Endp

End
