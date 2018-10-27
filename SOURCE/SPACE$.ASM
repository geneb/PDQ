;********* SPACE$.ASM - PDQ replacement for BASIC's B$SPAC routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn B$STRI:Proc        ;this STRING$ wants both arguments to be numeric
    
.Code

B$SPAC Proc, NumBlanks:Word

    Push NumBlanks           ;pass the incoming number of blanks on to B$STRI
    Mov  AL," "              ;make a space (B$STRI looks only at AL)
    Push AX                  ;and pass it as an ASCII value to B$STRI
    Call B$STRI              ;let B$STRI do the work
    Ret

B$SPAC Endp
End
