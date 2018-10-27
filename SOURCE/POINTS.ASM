;********* POINTS.ASM - PDQ replacement for BASIC's internal pixel support

;POINTS.ASM  Copyright (c) 1992  Thomas G. Hanlin III


.Model Medium, Basic

.Data

  Public  P$GXPos1, P$GYPos1
  Public  P$GXPos2, P$GYPos2

  P$GXPos1  dw 0      ; default X1 coordinate
  P$GYPos1  dw 0      ; default Y1 coordinate
  P$GXPos2  dw 0      ; default X2 coordinate
  P$GYPos2  dw 0      ; default Y2 coordinate


.Code

B$N1I2   Proc Xcoord:Word, Ycoord:Word

    Mov  AX,Xcoord
    Mov  P$GXPos1,AX
    Mov  AX,Ycoord
    Mov  P$GYPos1,AX
    Ret                     ;return to caller

B$N1I2   Endp



B$N2I2   Proc Xcoord:Word, Ycoord:Word

    Mov  AX,Xcoord
    Mov  P$GXPos2,AX
    Mov  AX,Ycoord
    Mov  P$GYPos2,AX
    Ret                     ;return to caller

B$N2I2   Endp



B$S2I2   Proc Xcoord:Word, Ycoord:Word

    Mov  AX,Xcoord          ;convert relative X coordinate to absolute
    Add  AX,P$GXPos1
    Mov  P$GXPos2,AX
    Mov  AX,Ycoord          ;convert relative Y coordinate to absolute
    Add  AX,P$GYPos1
    Mov  P$GYPos2,AX
    Ret                     ;return to caller

B$S2I2   Endp
End
