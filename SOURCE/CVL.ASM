;********* CVL.ASM - PDQ replacement for BASIC's B$FCVL routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$FreeTemp:Proc    ;this is in FREETEMP.ASM
    
.Code

B$FCVL Proc, Work:Word

    Mov  BX,Work             ;get the address for Work$ descriptor
    Mov  BX,[BX+02]          ;get the address of the first character
    Mov  AX,[BX]             ;load the low word
    Mov  DX,[BX+02]          ;and then the high word

    Push Work                ;delete the string if necessary
    Call P$FreeTemp
    Ret                      ;return to caller with the output in DX:AX

B$FCVL Endp
End
