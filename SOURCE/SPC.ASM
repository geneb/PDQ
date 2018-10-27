;********* SPC.ASM - PDQ replacements for BASIC's B$FSPC routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn B$STRI:Proc        ;STRING$ function
    Extrn B$PSSD:Proc        ;print string routine

.Code

B$FSPC Proc, NumBlanks:Word

    Push NumBlanks           ;pass the incoming number of blanks on to B$SPAC
    Mov  AL," "              ;make a blank space
    Push AX                  ;pass that along too
    Call B$STRI              ;B$STRI will create STRING$(NumBlanks, 32)
    Push AX                  ;pass the descriptor address on to B$PSSD
    Call B$PSSD              ;this prints without adding a CRLF
    Ret                      ;return to caller

B$FSPC Endp
End
