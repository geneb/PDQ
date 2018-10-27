;********** COLORSR.ASM - saves/restores the current color settings

;Copyright (c) 1990 Ethan Winer


;Syntax:
;   SaveColor = ColorSave%      ;save the foreground/background at one time
;   CALL ColorRest(SaveColor)   ;restore both colors in one operation

.Model Medium, Basic
.Data
    Extrn P$Color: Byte     ;this is in COLORDAT.ASM

.Code

ColorSave Proc

    Mov  AL,P$Color         ;get the current color value
    Xor  AH,AH              ;convert to a full word
    Ret                     ;return to BASIC with the function output in AX

ColorSave Endp


ColorRest Proc, Color:Word

    Mov  BX,Color           ;get the address for the new color value
    Mov  AL,[BX]            ;load it into AL
    Mov  P$Color,AL         ;store that in PDQ's data area
    Ret                     ;return to BASIC

ColorRest Endp
End
