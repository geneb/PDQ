;*********** CYMUL.ASM - Cur1@ * Cur2@


;Because of the use of floating point math, assemble this file with /e.

.8087
.Model Medium, Basic

.Data
    Extrn P$10000:DWord             ;this is in CYDATA.ASM

.Code

__aFCyMul Proc                      ;alias procedure name
__aFCyMul Endp

__CyMul Proc

    Push BP
    Mov  BP,SP
    Fild QWord Ptr [BP+0Eh]
    Fild QWord Ptr [BP+06]
    Fmulp ST(1),ST
    Fdiv DWord Ptr P$10000
    Fistp QWord Ptr [BP+0Eh]
    Fwait
    Pop  BP
    Retf 8
    
__CyMul Endp

End
