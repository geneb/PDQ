;********* CVI.ASM - PDQ replacement for BASIC's B$FCVI routine

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


.Model Medium, Basic
    Extrn P$FixStr:Proc      ;this is in FIXSTR.ASM
    Extrn P$FreeTemp:Proc    ;this is in FREETEMP.ASM

.Code

B$FCVI Proc, Work:Word

    Push Work             ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Work,AX          ;

    Mov  BX,Work             ;get the address for Work$ descriptor
    Mov  BX,[BX+02]          ;get the address of the first character
    Mov  AX,[BX]             ;load both bytes into AX at once

    Push Work                ;delete the string if necessary
    Call P$FreeTemp
    Ret                      ;return to caller with the output in AX

B$FCVI Endp
End
