;********* ENDLEVEL.ASM - PDQ "END with ERROR LEVEL" service

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn B$CEND:Proc       ;this is in PDQ.ASM
    
.Data
    Extrn P$TermCode:Byte   ;this is in PDQDATA.ASM

.Code

EndLevel Proc               ;, Level:Word

    Mov  BX,SP              ;address the stack directly
    Mov  BX,[BX+04]         ;now get the address of the Level they used
    Mov  AL,[BX]            ;and then get the actual level
    Mov  P$TermCode,AL      ;put it where B$CEND can find it
    Call B$CEND             ;and end the program

EndLevel Endp
End
