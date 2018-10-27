;********* STRING$.ASM - PDQ replacement for BASIC's B$STRI routine

;Copyright (c) 1989 Ethan Winer


;This routine provides the STRING$ function, when both arguments are numeric.


.Model Medium, Basic
    Extrn P$MakeTemp:Proc ;this is in MAKETEMP.ASM

.Code

B$STRI Proc Uses DI, NumChars:Word, CharNum:Word

    Mov  CX,NumChars      ;get the number of characters requested
    Call P$MakeTemp       ;let P$MakeTemp do the memory and error handling
    Mov  AX,CharNum       ;get the incoming character
    Rep  Stosb            ;fill that many bytes in the string pool

Exit:
    Mov  AX,BX            ;show the caller where the descriptor is
    Ret                   ;return to caller

B$STRI Endp
End
