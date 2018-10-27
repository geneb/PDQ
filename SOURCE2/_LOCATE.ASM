;********* _LOCATE.ASM - reduced capability LOCATE, requires 2 parameters

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Code

B$LOCT Proc, Hey:Word, Row:Word, Nice:Word, Col:Word, Legs:Word

    Mov  AH,0Fh           ;get the current video page
    Push BP               ;some old PC BIOS's trash BP
    Int  10h              ;through the BIOS
    Pop  BP
    Mov  DX,Col           ;load DL with the column
    Mov  AX,Row           ;get the row
    Mov  DH,AL            ;and put it into DH
    Dec  DH               ;adjust 1-25 to 0-24
    Dec  DL               ;ditto for the column
    Mov  AH,2             ;specify the BIOS service to locate the cursor
    Int  10h              ;call the BIOS
    Ret                   ;return to caller

B$LOCT Endp
End
