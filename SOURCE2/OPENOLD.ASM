;********** OPENOLD.ASM - PDQ support for the "old" OPEN syntax

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
    Extrn B$OPEN:Proc       ;this is in OPEN.ASM (it does the real work)
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Code

B$OOPN Proc, Mode:Word, FileNum:Word, FileName:Word, RecLength:Word

    Mov  BX,Mode            ;first look at the Mode ("i", "o", "r", "b", "a")
    Mov  BX,[BX+02]         ;point to the first character in the string
    Mov  BL,[BX]            ;get it
    And  BL,95              ;capitalize it

    Mov  AX,1               ;assume it's an "I" for INPUT
    Cmp  BL,"I"             ;is it?
    Je   Done               ;yes, almost done

    Inc  AX                 ;assume it's an "O" for OUTPUT
    Cmp  BL,"O"             ;is it?
    Je   Done               ;yes

    Mov  AL,4               ;okay, let's try "R" for RANDOM
    Cmp  BL,"R"             ;well?
    Je   Done

    Mov  AL,8               ;how 'bout APPEND?
    Cmp  BL,"A"
    Je   Done               ;yup

    Mov  AL,20h             ;it better be "B" for BINARY
    Cmp  BL,"B"
    Je   Done               ;that's the ticket

    Mov  AL,1               ;none of the above, make an appropriate error
    Call P$DoError          ;handle the error as needed
    Jmp  Short Exit         ;and get out

Done:
    Push FileName           ;pass the file name on to B$OPEN
    Push FileNum            ;and the file number
    Push RecLength          ;and the record length
    Push AX                 ;and finally the open mode
    Call B$OPEN             ;let the standard OPEN routine do the rest

Exit:
    Ret                     ;back to BASIC

B$OOPN Endp
End
