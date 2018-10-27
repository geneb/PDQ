;*********** CYASSIGN.ASM - assigns currency from other data types


;Because of the use of floating point math, assemble this file with /e.

.8087
.Model Medium, Basic

.Data
    Extrn P$10000:DWord             ;this is in CYDATA.ASM

.Code

B$CySetStack Proc Near              ;create eight bytes on the stack

    Pop  CX
    Pop  BX
    Pop  ES
    Sub  SP,8
    Push ES
    Push BX
    Push BP
    Mov  BP,SP
    Jmp  CX
    
B$CySetStack Endp



B$CYI4 Proc                         ;assign Cur@ = LongInt&

    Call Near Ptr B$CySetStack
    Push DI
    Xchg BX,DX
    Cwd
    Cmp  DX,BX
    Jz   B$CYI2+4
    Or   BX,BX
    Pushf
    Jns  @F
    Neg  AX
    Adc  BX,0
    Neg  BX

@@:
    Mov  CX,2710h
    Mul  CX
    Xchg AX,BX
    Mov  DI,DX
    Mul  CX
    Add  AX,DI
    Adc  DX,0
    Xor  CX,CX
    Popf
    Jns  @F
    Not  BX
    Add  BX,1
    Not  AX
    Adc  AX,CX
    Not  DX
    Adc  DX,CX
    Dec  CX

@@:
    Lea  DI,Word Ptr [BP+06]
    Push SS
    Pop  ES
    Xchg AX,BX
    Stosw
    Xchg AX,BX
    Stosw
    Xchg AX,DX
    Stosw
    Xchg AX,CX
    Stosw
    Pop  DI
    Pop  BP
    Ret
    
B$CYI4 Endp



B$CYI2 Proc                         ;assign Cur@ = IntVar%

    Call Near Ptr B$CySetStack
    Push DI
    Mov  CX,2710h
    Imul CX
    Lea  DI,Word Ptr [BP+06]
    Push SS
    Pop  ES
    Stosw
    Xchg AX,DX
    Stosw
    Cwd
    Xchg AX,DX
    Stosw
    Stosw
    Pop  DI
    Pop  BP
    Ret
    
B$CYI2 Endp



B$CYFP Proc                         ;assign Cur@ = Float![#]

    Call Near Ptr B$CySetStack
    Fmul DWord Ptr P$10000
    Fistp QWord Ptr [BP+06]
    Fwait
    Pop  BP
    Ret
    
B$CYFP Endp

End
