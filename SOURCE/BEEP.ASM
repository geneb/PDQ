;********** BEEP.ASM - PDQ replacement for BASIC's B$BEEP routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Code

B$BEEP Proc Uses BP       ;some old PC BIOS's trash BP

    Mov  AX,0E07h         ;service 0Eh, character 7 (beep)
    Int  10h              ;let the BIOS handle it
    Ret                   ;return to caller

B$BEEP Endp
End
