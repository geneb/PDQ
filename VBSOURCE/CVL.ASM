;********* CVL.ASM - PDQ replacement for BASIC's B$FCVL routine

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


.Model Medium, Basic
    Extrn P$FixStr:Proc      ;this is in FIXSTR.ASM
    Extrn P$FreeTemp:Proc    ;this is in FREETEMP.ASM

.Code

B$FCVL Proc, Work:Word

    Push Work             ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Work,AX          ;

    Mov  BX,Work             ;get the address for Work$ descriptor
    Mov  BX,[BX+02]          ;get the address of the first character
    Mov  AX,[BX]             ;load the low word
    Mov  DX,[BX+02]          ;and then the high word

    Push Work                ;delete the string if necessary
    Call P$FreeTemp
    Ret                      ;return to caller with the output in DX:AX

B$FCVL Endp
End
