;********* CY2FP2LI.ASM - converts Cur@ to Float![#] and LongInt& and IntVar%


;Because of the use of floating point math, assemble this file with /e.

.8087
.Model Medium, Basic

.Data
    Extrn P$10000:DWord             ;this is in CYDATA.ASM

.Code

B$FPCY Proc                         ;convert floating point from Cur@

    Push BP
    Mov  BP,SP
    Fild QWord Ptr [BP+06]
    Fdiv DWord Ptr P$10000
    Fwait
    Pop  BP
    Retf 8
    
B$FPCY Endp



B$I4CY Proc                         ;assign LongInt& = Cur@

    Push BP
    Mov  BP,SP
    Fild QWord Ptr [BP+06]
    Fdiv DWord Ptr P$10000
    Fistp DWord Ptr [BP+06]
    Fwait
    Mov  AX,Word Ptr [BP+06]
    Mov  DX,Word Ptr [BP+08]
    Pop  BP
    Retf 8
    
B$I4CY Endp



B$I2CY Proc                         ;assign IntVar% = Cur@

    Push BP
    Mov  BP,SP
    Fild QWord Ptr [BP+06]
    Fdiv DWord Ptr P$10000
    Fistp Word Ptr [BP+06]
    Fwait
    Mov  AX,Word Ptr [BP+06]
    Pop  BP
    Retf 8
    
B$I2CY Endp

End
