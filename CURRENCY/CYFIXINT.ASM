;*********** CYFIXINT.ASM - FIX(Cur@) and INT(Cur@)

.Model Medium, Basic
.Code

B$INTC Proc                 ;INT(Cur@)

    Mov  AX,2710
    Db   03Dh               ;fake bogus compare for an alternate entry point
    
B$INTC Endp


B$FIXC Proc                 ;FIX(Cur@)

    Xor  AX,AX
    Push BP
    Mov  BP,SP
    Push DI
    Push SI
    Xchg AX,DI
    Lea  SI,Word Ptr [BP+06]
    Push SI
    Call Near Ptr __LoadCy
    Push AX
    Call Near Ptr __CyAbsR
    Mov  BP,2710h
    Call Near Ptr __U8DivU2R
    Pop  AX
    Pop  SI
    Or   DX,DX
    Jz   Exit
    Or   AX,AX
    Jns  @F
    Neg  DX
    Add  DX,DI

@@:
    Neg  DX
    Xchg AX,DX
    Cwd
    Add  Word Ptr [SI],AX
    Adc  Word Ptr [SI+02],DX
    Adc  Word Ptr [SI+04],DX
    Adc  Word Ptr [SI+06],DX

Exit:
    Pop  SI
    Pop  DI
    Pop  BP
    Ret
    
B$FIXC Endp



__U8DivU2R Proc Near                ;unsigned divide, values in registers

    Xor  DX,DX
    Div  BP
    Xchg AX,CX
    Div  BP
    Xchg AX,CX
    Xchg AX,SI
    Div  BP
    Xchg AX,SI
    Xchg AX,BX
    Div  BP
    Xchg AX,BX
    Ret
    
__U8DivU2R Endp



__CyAbsR Proc Near                  ;ABS(Cur@) when Cur@ is in registers

    Or   AX,AX
    Jns  Exit
    Xor  DX,DX
    Not  BX
    Add  BX,1
    Not  SI
    Adc  SI,DX
    Not  CX
    Adc  CX,DX
    Not  AX
    Adc  AX,DX

Exit:
    Ret
    
__CyAbsR Endp



__loadCy Proc Near                  ;load Cur@ from memory to registers

    Lodsw
    Xchg AX,BX
    Lodsw
    Xchg AX,DX
    Lodsw
    Xchg AX,CX
    Lodsw
    Xchg SI,DX
    Ret
    
__LoadCy Endp

End
