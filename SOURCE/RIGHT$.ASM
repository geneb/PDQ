;********** RIGHT$.ASM - PDQ replacement for BASIC's B$RGHT routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM
    Extrn P$MakeTemp:Proc ;this is in MAKETEMP.ASM

.Code

B$RGHT Proc Uses SI DI, Work:Word, NumChars:Word

    Mov  SI,Work          ;get address of Work$
    Mov  AX,[SI]          ;put its length into AX

    Mov  CX,NumChars      ;put NumChars into CX
    Cmp  CX,AX            ;are they requesting more characters than exist?
    Jbe  Okay             ;no, so use the NumChars character count now in CX
    Mov  CX,AX            ;yes, limit the output to the length of Work$

Okay:
    Sub  AX,CX            ;this is how many characters to advance SI by
    Call P$MakeTemp       ;create temporary space in the string pool
    Mov  SI,Work          ;get address of Work$ again in case it moved
    Mov  SI,[SI+02]
    Add  SI,AX            ;point that much farther into the string
    Rep  Movsb            ;copy the characters there
    Mov  AX,BX            ;show BASIC where the output descriptor is

    Push Work             ;delete the incoming string if necessary
    Call P$FreeTemp
    Ret                   ;return to caller

B$RGHT Endp
End
