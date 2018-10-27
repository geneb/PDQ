;********* COMPARE$.ASM - PDQ replacement for BASIC's B$SCMP routine

;Copyright (c) 1989 Ethan Winer


;This routine handles all of BASIC's string comparisons.


.Model Medium, Basic
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM
    
.Code

B$SCMP Proc Uses SI DI, Str1:Word, Str2:Word

    Cld                   ;ensure that all string moves are forward
    Push DS               ;assign ES=DS for Compsb below
    Pop  ES

    Mov  SI,Str1          ;get the address for the first string
    Mov  AX,[SI]          ;put its length into AX
    Mov  SI,[SI+02]       ;and its address into SI

    Mov  DI,Str2          ;get the address for the second string
    Mov  DX,[DI]          ;put its length into DX
    Mov  DI,[DI+02]       ;and its address into DI

    Mov  CX,DX            ;put the length of the second string into CX
    Cmp  AX,DX            ;compare it against the length of the first string
    Ja   Comp1            ;DX was shorter, so CX is already correct
    Mov  CX,AX            ;we guessed wrong, AX is shorter so use it instead

Comp1:
    Repz Cmpsb            ;do the comparison
    Jz   Comp2            ;strings are equal thus far, decide based on length
    Jmp  Short ExitComp   ;they're different so the flags are already correct

Comp2:
    Sub  AX,DX            ;set the flags based on the original lengths

ExitComp:
    Pushf                 ;save the result of the comparison for a moment
    Push Str1             ;delete the string(s) if necessary
    Call P$FreeTemp
    Push Str2
    Call P$FreeTemp
    Popf                  ;get the flags back again
    Ret                   ;return to caller

B$SCMP Endp
End
