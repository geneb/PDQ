;********* LCASE$.ASM - PDQ replacement for BASIC's B$LCAS routine

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


.Model Medium, Basic
    Extrn P$FixStr:Proc   ;this is in FIXSTR.ASM
    Extrn P$MakeTemp:Proc ;this is in MAKETEMP.ASM
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM

.Code

B$LCAS Proc Uses SI DI, Work:Word

    Push Work             ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Work,AX          ;

    Mov  SI,Work          ;get the descriptor address for Work$
    Mov  CX,[SI]          ;get the length of the string
    Call P$MakeTemp       ;let P$MakeTemp do the memory and error handling
    Jcxz Exit             ;can't process a null string (or no more pool)

    Mov  SI,Work          ;get the descriptor address for Work$ again
    Mov  SI,[SI+02]       ;and the address of its data (in case it moved)

Do:
    Lodsb                 ;get the current character
    Cmp  AL,"A"           ;is it less than "A"?
    Jb   Skip             ;yes, skip ahead
    Cmp  AL,"Z"           ;is it greater than "Z"?
    Ja   Skip             ;yes, skip that too
    Or   AL,100000b       ;set the lower case bit

Skip:
    Stosb                 ;store the character into the string pool
    Loop Do               ;loop until done

Exit:
    Mov  AX,BX            ;show the caller where the descriptor is
    Push Work             ;delete the incoming string if necessary
    Call P$FreeTemp
    Ret                   ;return to caller

B$LCAS Endp
End
