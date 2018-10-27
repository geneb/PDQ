;********* CVI.ASM - PDQ replacement for BASIC's B$FCVI routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$FreeTemp:Proc    ;this is in FREETEMP.ASM
    
.Code

B$FCVI Proc, Work:Word

    Mov  BX,Work             ;get the address for Work$ descriptor
    Mov  BX,[BX+02]          ;get the address of the first character
    Mov  AX,[BX]             ;load both bytes into AX at once
    
    Push Work                ;delete the string if necessary
    Call P$FreeTemp
    Ret                      ;return to caller with the output in AX

B$FCVI Endp
End
