;********** LEFT$.ASM - PDQ replacement for BASIC's B$LEFT routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$MakeTemp:Proc   ;this is in MAKETEMP.ASM
    Extrn P$FreeTemp:Proc   ;this is in FREETEMP.ASM

.Code

B$LEFT Proc Uses SI DI, Work:Word, NumChars:Word

    Mov  SI,Work            ;get the address of Work$
    Mov  AX,[SI]            ;put its length into AX
    Mov  SI,[SI+02]         ;now SI points to the first character in Work$

    Mov  CX,NumChars        ;see how many characters they are requesting
    Cmp  CX,AX              ;do they want more characters than exist?
    Jbe  Okay               ;no, use the NumChars character count now in CX
    Mov  CX,AX              ;yes, limit it to the length of Work$

Okay:
    Call P$MakeTemp         ;claim temporary space in the string pool
    Mov  SI,Work            ;get the address of Work$ again in case it moved
    Mov  SI,[SI+02]
    Rep  Movsb              ;copy the characters there
    Mov  AX,BX              ;show BASIC where the output descriptor is

    Push Work               ;delete the incoming string if necessary
    Call P$FreeTemp
    Ret                     ;return to BASIC

B$LEFT Endp
End
