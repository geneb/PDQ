;********** TAB.ASM - P.D.Q. replacement for BASIC's B$FTAB routine

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
    Extrn B$PSSD:Proc       ;this is in PRINT.ASM
    Extrn B$SPAC:Proc       ;this is in SPACE$.ASM

.Data
    Extrn P$TabTable:Byte   ;this is in FHANDLES.ASM
    Extrn P$PrintHandle:Word;this is in PHANDLE.ASM

.Code

B$FTAB Proc, TabCount:Word

    Mov  AX,TabCount        ;see what column they want to Tab to
    Mov  BX,P$PrintHandle   ;and which DOS handle we're printing to
    Mov  CL,P$TabTable[BX]  ;load the current Tab column
    Mov  CH,0               ;convert it to an unsigned word
    Sub  AX,CX              ;calculate how many spaces are needed
    Dec  AX                 ;there's that inevitable fudge factor again
    Js   Exit               ;they're already past this column, bag out

    Push AX                 ;pass the number of spaces on to SPACE$()
    Call B$SPAC             ;this returns a descriptor address in AX
    Push AX                 ;pass that address on to PRINT
    Call B$PSSD             ;this prints when you use a semicolon (;)

Exit:
    Ret
    
B$FTAB Endp
End
