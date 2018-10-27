;********* POINT2.ASM - PDQ replacement for BASIC's POINT function (two parm)

;POINT2.ASM  Copyright (c) 1992  Thomas G. Hanlin III


.Model Medium, Basic

.Code

B$PNI2   Proc Xcoord:Word, Ycoord:Word
    Mov  CX,Xcoord          ;X coordinate
    Mov  DX,Ycoord          ;Y coordinate
    Xor  BX,BX              ;page
    Mov  AH,0Dh             ;get pixel color
    Int  10h
    Mov  AH,0
    Ret
B$PNI2   EndP
End
