;******** ENDBC7.ASM - routine to service END and STOP with a level (BASIC 7)

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
    Extrn B$CEND:Proc       ;this is in PDQ.ASM
    
.Data
    Extrn P$TermCode:Byte   ;this is in PDQDATA.ASM

.Code

B$CENC Proc                 ;this is the name BASIC 7 uses for END [level]
B$CENC Endp                 ;fall into the code below


B$STP1 Proc                 ;this is the name BASIC 7 uses for STOP [level]

    Mov  BX,SP              ;address the stack directly
    Mov  AL,[BX+04]         ;now get the level they used
    Mov  P$TermCode,AL      ;put it where B$CEND can find it
    Call B$CEND             ;and end the program
    
B$STP1 Endp
End
