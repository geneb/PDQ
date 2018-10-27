;********* CSRLIN.ASM - PDQ replacement for BASIC's B$CSRL routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Code

B$CSRL Proc Uses BP       ;some old PC BIOS's trash BP

    Mov  AH,0Fh           ;get the current video page
    Int  10h              ;through the BIOS
    Mov  AH,3             ;get cursor position service for page now in BH
    Int  10h              ;call the BIOS
    Mov  AL,DH            ;put the returned row number in AL
    Inc  AL               ;adjust 0-24 to 1-25
    Cbw                   ;convert to a word in AX
    Ret                   ;return to caller

B$CSRL Endp
End
