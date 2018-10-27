;********** MIDCHARS.ASM - alternate MID$ statement accepts an integer value

;Copyright (c) 1991 Ethan Winer


;syntax: CALL MidCharS(Work$, Position, Character)

.Model Medium, Basic
    Extrn StringInfo:Proc ;this is Jay's far strings "helper" routine
    
.Code

MidCharS Proc Uses DS SI, String:Word, Position:Word, Char:Word

    Mov  SI,String        ;get the descriptor address for Work$
    Call StringInfo       ;length returns in CX, segment and address in DX:AX
    
    Cmp  CX,Position      ;are they trying to insert off the end?
    Jb   Exit             ;yes, ignore

    Mov  BX,AX            ;now BX points to the start of Work$
    Mov  DS,DX            ;and DS holds the correct segment
    Add  BX,Position      ;point that far into the string
    Dec  BX               ;adjust to a zero-based address
    
    Mov  AX,Char          ;get the character to assign
    Mov  [BX],AL          ;assign the character

Exit:
    Ret                   ;return to caller

MidCharS Endp
End
