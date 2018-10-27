;********* DOSVRQLB.ASM - this version of DOSVer works within a Quick Library

;Copyright (c) 1988 Ethan Winer


.Model Medium, Basic
.Code

DOSVer Proc

    Mov  AH,30h       ;get DOS version service through DOS
    Int  21h          ;major version returns in AL, minor in AH
    Push AX           ;save minor version number for later
    Mov  CL,100       ;prepare to multiply AL * 100
    Mul  CL           ;AX = AL * CL

    Pop  BX           ;retrieve minor version
    Mov  BL,BH        ;get ready to add it to major version number
    Xor  BH,BH        ;zero out BH
    Add  AX,BX        ;add major and minor parts
    Ret               ;return to BASIC

DOSVer Endp
End
