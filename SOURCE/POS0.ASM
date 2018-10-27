;********* POS0.ASM - PDQ replacement for BASIC's B$FPOS routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Code

B$FPOS Proc, Dummy:Word   ;the "0" in POS(0) is an ignored argument

    Mov  AH,0Fh           ;get the current video page
    Int  10h              ;through the BIOS
    Mov  AH,3             ;get cursor position service
    Int  10h              ;call the BIOS
    Mov  AL,DL            ;put the returned column number in AL
    Inc  AL               ;adjust 0-79 to 1-80
    Xor  AH,AH            ;clear AH so we can use all of AX
    Ret                   ;return to caller

B$FPOS Endp
End
