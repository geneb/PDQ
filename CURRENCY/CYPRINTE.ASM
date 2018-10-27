;**** CYPRINTE.ASM - PDQ replacement for BASIC's B$PECY routine

;Copyright (c) 1989 Ethan Winer

;Prints Currency values with a terminating CRLF (E = End-of-line)


.Model Medium, Basic
    Extrn B$STCY:Proc       ;in CYSTR$.ASM, converts Currency to string
    Extrn B$PESD:Proc       ;in PRINT.ASM, prints a string with a CRLF

.Data?
    RetAddr DW 2 Dup (?)    ;pop the address to return to here

.Code

B$PECY Proc                 ;, Value:QWord

    Pop  RetAddr            ;pop the caller's return address directly
    Pop  RetAddr + 2        ;and segment

    Call B$STCY             ;call STR$ leaving the value on the stack
    Push AX                 ;push the descriptor address B$STCY returns
    Call B$PESD             ;print the number as a string with a CRLF

    Jmp  DWord Ptr RetAddr  ;return to caller

B$PECY Endp
End
