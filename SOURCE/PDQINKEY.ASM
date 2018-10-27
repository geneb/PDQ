;********** PDQINKEY.ASM - PDQ alternate for BASIC's INKEY$ routine

;Copyright (c) 1989 Ethan Winer


;Syntax - Pressed = PDQInkey%
;         IF Pressed = 0 THEN ...    'no character pending
;         IF Pressed > 0 THEN ...    'regular ASCII character
;         IF Pressed < 0 THEN ...    'negative version of an extended key


.Model Medium, Basic
.Code

PDQInkey Proc Uses BX

    Xor  BX,BX            ;assume no characters
    
    Mov  AH,6             ;keyboard/display function
    Mov  DL,0FFh          ;specify keyboard input
    Int  21h              ;call DOS
    Jz   Exit             ;no, exit with BX set to zero

    Mov  BL,AL            ;yes, remember the character
    Or   AL,AL            ;is it an extended key?
    Jnz  Exit             ;no, so we're all done

    Mov  AH,6             ;yes, now get the extended portion
    Mov  DL,0FFh          ;this probably isn't necessary again....
    Int  21h              ;call DOS
    Mov  BL,AL            ;now BL holds the extended key
    Neg  BX               ;flip it to a negative value

Exit:
    Mov  AX,BX            ;assign the function output
    Ret                   ;return to BASIC

PDQInkey Endp
End
