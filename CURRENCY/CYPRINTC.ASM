;**** CYPRINTC.ASM - PDQ replacement for BASIC's B$PCCY routine

;Copyright (c) 1989 Ethan Winer

;Prints Currency values with a trailing Tab (C = Comma)


.Model Medium, Basic
    Extrn B$STCY:Proc       ;in CYSTR$.ASM, converts Currency to string
    Extrn B$PCSD:Proc       ;in PRNCOMMA.ASM, prints a string with a Tab

.Data?
    RetAddr DW 2 Dup (?)    ;pop the address to return to here

.Code

B$PCCY Proc                 ;, Value:QWord

    Pop  RetAddr            ;pop the caller's return address directly
    Pop  RetAddr + 2        ;and segment

    Call B$STCY             ;this then calls STR$ to make a string
    Push AX                 ;push the descriptor address B$STCY returns
    Call B$PCSD             ;print the number as a string with a trailing Tab

    Jmp  DWord Ptr RetAddr  ;return to caller

B$PCCY Endp
End
