;********** DOSVER.ASM - retrieves the current DOS version number

;Copyright (c) 1989 Ethan Winer

;Syntax - Version = DosVer%
;
;  where Version receives the DOS version number * 100
;  Example: if DOS version = 3.10 then Version = 310


.Model Medium, Basic
.Data
    Extrn P$DOSVer:Word     ;this is in PDQDATA.ASM

.Code

DOSVer Proc

    Mov  AX,P$DOSVer  ;get the version obtained in the P.D.Q. startup code
    Push AX           ;save it for later
    Mov  CL,100       ;multiply AL * 100
    Mul  CL           ;AX = AL * CL
    Pop  BX           ;retrieve minor version (was AX when pushed)
    Mov  BL,BH        ;get ready to add it to major version number
    Xor  BH,BH        ;zero out BH
    Add  AX,BX        ;add major and minor parts
    Ret               ;return to BASIC

DOSVer Endp
End
