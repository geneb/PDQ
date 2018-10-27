;********** MIDCHARS.ASM - alternate MID$ statement accepts an integer value

;Copyright (c) 1991 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


;syntax: CALL MidCharS(Work$, BYVAL Position%, BYVAL Character%)

.Model Medium, Basic
    Extrn P$FixStr:Proc      ;this is in FIXSTR.ASM

.Code

MidCharS Proc, String:Word, Position:Word, Char:Word

    Push String           ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  String,AX        ;

    Mov  AX,Char          ;get the character to assign
    Mov  CX,Position      ;see how far in we are to insert
    Jcxz Exit             ;ignore a zero position

    Mov  BX,String        ;get the descriptor address for Work$
    Cmp  CX,[BX]          ;are they trying to insert off the end?
    Ja   Exit             ;yes, ignore that too

    Mov  BX,[BX+02]       ;now BX points to the start of Work$
    Add  BX,CX            ;point that far into the string
    Dec  BX               ;adjust to a zero-based address
    Mov  [BX],AL          ;assign the character

Exit:
    Ret                   ;return to caller

MidCharS Endp
End
