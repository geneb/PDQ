;********** MIDCHAR.ASM - alternate MID$ function, returns an integer value

;Copyright (c) 1990 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


;syntax: Char = MidChar%(Work$, Position)
;        IF Char = -1 THEN ...      'Position is negative, or past the end

.Model Medium, Basic
    Extrn P$FixStr:Proc      ;this is in FIXSTR.ASM

.Code

MidChar Proc, String:Word, Position:Word

    Push String           ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  String,AX        ;

    Mov  AX,-1            ;assume they're asking for an illegal character
    Mov  BX,Position      ;get the address for Position
    Mov  CX,[BX]          ;and load it into CX

    Mov  BX,String        ;get the descriptor address for String
    Mov  DX,[BX]          ;put the length into DX
    Mov  BX,[BX+02]       ;now BX points to the start of StrArg$

    Jcxz Exit             ;they asked for the zero character, return -1
    Cmp  CX,DX            ;is Position past the end of the string?
    Ja   Exit             ;yes, as above

Okay:
    Dec  CX               ;fudge since length is one-based, address is zero
    Add  BX,CX            ;now BX points at the character
    Mov  AL,[BX]          ;load it into AX for the function output
    Mov  AH,0             ;clear AH so we can use all of AX

Exit:
    Ret                   ;return to caller

MidChar Endp
End
