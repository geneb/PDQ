;********* LEN.ASM - PDQ replacement for BASIC's B$FLEN routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$FreeTemp:Proc    ;this is in FREETEMP.ASM
    
.Code

STRINGLENGTH Proc            ;this does the same thing as LEN
    Nop                      ;forces Codeview to display the correct name
STRINGLENGTH Endp            ;fall into the code below

B$FLEN Proc Uses BX, Work:Word

    Mov  BX,Work             ;get the address for Work$
    Mov  AX,[BX]             ;put its length into AX for the function output
    Push Work                ;delete the incoming string if necessary
    Call P$FreeTemp
    Ret                      ;return to caller

B$FLEN Endp
End
