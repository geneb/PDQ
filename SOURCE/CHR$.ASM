;********* CHR$.ASM - PDQ replacement for BASIC's B$FCHR routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$MakeTemp:Proc ;this is in MAKETEMP.ASM
    
.Code

B$FCHR Proc Uses DI, Char:Word

    Mov  CX,1             ;request 1 byte in the string pool
    Call P$MakeTemp       ;let P$MakeTemp do the memory and error handling
    Jcxz Exit             ;out of memory, return a null string
    Mov  AX,Char          ;get the incoming character
    Stosb                 ;stick it into the string pool

Exit:
    Mov  AX,BX            ;show the caller where the descriptor is
    Ret                   ;return to caller

B$FCHR Endp
End
