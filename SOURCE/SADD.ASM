;********** SADD.ASM - PDQ replacement for BASIC's B$SADD routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Code

STRINGADDRESS Proc          ;this does the same thing as SADD
    Nop                     ;this forces CodeView to show the correct name
STRINGADDRESS Endp          ;fall into the code below


B$SADD Proc                 ;, Work:Word

    Mov  BX,SP              ;address the stack directly for less code
    Mov  BX,[BX+04]         ;get the address for Work$'s descriptor
    Mov  AX,[BX+02]         ;return the address in AX for the function output
    Mov  DX,DS              ;BASIC 7 expects the segment to be returned in DX
    Retf 2                  ;return discarding the stack argument manually

B$SADD Endp
End
