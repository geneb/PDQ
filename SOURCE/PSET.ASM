;********* PSET.ASM - PDQ replacement for BASIC's PRESET and PSET routines

;PSET.ASM  Copyright (c) 1992  Thomas G. Hanlin III



Extrn P$Plot: far           ;in PLOT.ASM


.Model Medium, Basic

.Data

   Extrn P$GXPos1: Word     ;X coordinate       in POINTS.ASM
   Extrn P$GYPos1: Word     ;Y coordinate       in POINTS.ASM
   Extrn b$ForeColor: Byte  ;foreground color   in COLORDAT.ASM

.Code

B$PRST   Proc               ; PRESET(x,y)

    Xor  AX,AX              ;color
    Jmp  CommonCode         ;

Public B$PSET
B$PSET   Label Far          ; PSET(x,y)

    Mov  AL,b$ForeColor     ;color
CommonCode:
    Mov  CX,P$GXPos1        ;X coordinate
    Mov  DX,P$GYPos1        ;Y coordinate
    Jmp  P$Plot             ;  go plot it

B$PRST   Endp



B$PSTC   Proc Color:Byte    ; PSET(x,y),color  or  PRESET(x,y),color

    Mov  AL,Color           ;color
    Mov  CX,P$GXPos1        ;X coordinate
    Mov  DX,P$GYPos1        ;Y coordinate
    Call P$Plot             ;plot it
    Ret                     ;return to caller

B$PSTC   Endp
End
