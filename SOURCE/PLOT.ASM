;********* PLOT.ASM - PDQ support for graphics points

;PLOT.ASM  Copyright (c) 1992  Thomas G. Hanlin III


.Model Medium, Basic

.Code

P$PLOT   Proc ; plot point at (CX,DX) in color AL

    Push AX             ;save registers
    Push BX
    Push CX
    Push DX
    Xor  BX,BX          ;page #
    Mov  AH,0Ch         ;select "set pixel color" routine
    Int  10h            ;let the BIOS handle it
    Pop  DX             ;restore registers
    Pop  CX
    Pop  BX
    Pop  AX
    Ret

P$PLOT   Endp
End
