;**** CYPRINTS.ASM - PDQ replacement for BASIC's B$PSCY routine

;Copyright (c) 1989 Ethan Winer

;Prints Currency values without a terminating CRLF (S = Semicolon)


.Model Medium, Basic
    Extrn B$STCY:Proc       ;in CYSTR$.ASM, converts Currency to string
    Extrn B$PSSD:Proc       ;in PRINT.ASM, prints a string without a CRLF

.Data?
    RetAddr DW 2 Dup (?)    ;pop the address to return to here

.Data
    Extrn P$1Space:Word     ;this is in PRINTDAT.ASM

.Code

B$PSCY Proc                 ;, Value:QWord

    Pop  RetAddr            ;pop the caller's return address
    Pop  RetAddr + 2        ;and segment

    Call B$STCY             ;this then calls STR$ to make a string
    Push AX                 ;push the descriptor address B$STI2 returns
    Call B$PSSD             ;print the number as a string without a CRLF
    Mov  AX,Offset P$1Space ;show the print routine where the blank space is
    Push AX                 ;push the descriptor in anticipation of printing
    Call B$PSSD             ;print the number as a string without a CRLF

    Jmp  DWord Ptr RetAddr  ;return to caller

B$PSCY Endp
End
