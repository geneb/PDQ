;********* ASC.ASM - PDQ replacement for BASIC's B$FASC routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$FreeTemp:Proc    ;this is in FREETEMP.ASM
    
.Code

B$FASC Proc, Work:Word

    Mov  BX,Work             ;get the address for Work$ descriptor
    Mov  AX,-1               ;assume it's null
    Test AX,[BX]             ;is it?
    Jz   Exit                ;yes, exit with AX holding -1 as a flag

    Mov  BX,[BX+02]          ;no, get the address of the first character
    Mov  AL,[BX]             ;then put the first character into AL
    Inc  AH                  ;increment AH up to zero (to return an integer)

    Push Work                ;pass the incoming string address to FreeTemp
    Call P$FreeTemp          ;delete it if necessary

Exit:
    Ret                      ;return to caller

B$FASC Endp
End
