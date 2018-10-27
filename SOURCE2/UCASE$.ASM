;********* UCASE$.ASM - PDQ replacement for BASIC's B$UCAS routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$MakeTemp:Proc ;this is in MAKETEMP.ASM
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM

.Code

B$UCAS Proc Uses SI DI, Work:Word

    Mov  SI,Work          ;get the descriptor address for Work$
    Mov  CX,[SI]          ;get the length of the string
    Call P$MakeTemp       ;let P$MakeTemp do the memory and error handling
    Jcxz Exit             ;can't process a null string (or no more pool)
    Mov  SI,Work          ;get the descriptor address for Work$ again
    Mov  SI,[SI+02]       ;and the address of its data (in case it moved)


Do:
    Lodsb                 ;get the current character
    Cmp  AL,"a"           ;is it less than "a"?
    Jb   Skip             ;yes, skip ahead
    Cmp  AL,"z"           ;is it greater than "z"?
    Ja   Skip             ;yes, skip that too
    And  AL,1011111b      ;mask off the lower case bit

Skip:
    Stosb                 ;store the character into the string pool
    Loop Do               ;loop until done

Exit:
    Mov  AX,BX            ;show the caller where the descriptor is
    Push Work             ;delete the incoming string if necessary
    Call P$FreeTemp
    Ret                   ;return to caller

B$UCAS Endp
End
