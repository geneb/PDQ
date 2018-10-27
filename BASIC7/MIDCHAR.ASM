;********** MIDCHAR.ASM - alternate MID$ function, returns an integer value

;Copyright (c) 1990 Ethan Winer


;syntax: Char = MidChar%(Work$, Position)
;        IF Char = -1 THEN ...      'Position is negative, or past the end


.Model Medium, Basic
    Extrn StringLength:Proc     ;these are QBX internal routines
    Extrn StringAddress:Proc

.Code

MidChar Proc Uses SI DI ES, String:Word, Position:Word

    Mov  SI,String        ;get the address for String's descriptor
    Push SI               ;show StringLength where the descriptor is
    Call StringLength     ;this returns the length in AX
    Mov  CX,AX            ;copy the length to CX

    Push SI               ;now call StringAddress to find string data
    Call StringAddress    ;this is returned in DX:AX
    Mov  ES,DX            ;copy the segment to ES
    Mov  SI,AX            ;and the address to SI

    Mov  BX,Position      ;get the address for Position
    Mov  BX,[BX]          ;and load it into BX
    Mov  AX,-1            ;assume they're asking for an illegal character

    Or   BX,BX            ;are they asking for the zero character?
    Jz   Exit             ;yes, return -1
    Cmp  BX,CX            ;is Position past the end of the string?
    Ja   Exit             ;yes, as above
    
    Dec  BX               ;adjust the character position to an address offset
    Mov  AL,ES:[BX+SI]    ;load the character into AX for the function output
    Mov  AH,0             ;clear AH so we can use all of AX

Exit:
    Ret                   ;return to caller

MidChar Endp
End
