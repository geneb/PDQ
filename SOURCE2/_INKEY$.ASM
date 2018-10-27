;********** _INKEY$.ASM - BIOS-only replacement INKEY$, uses same public name

;This routine is intended to be used as a "stub file", so normal references
;to BASIC's INKEY$ function will use the BIOS instead of DOS.

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
.Data
    DescrLen DW 0               ;this is the function's descriptor length
    DescrAdr DW Offset Output   ;this is its address

.Data?
    Output   DB 2 Dup (?)       ;this is where the output characters are put

.Code

B$INKY Proc

    Xor  AX,AX              ;make a zero the fastest/smallest way possible
    Mov  DescrLen,AX        ;assume no characters

    Mov  AH,1               ;now see if a character is pending
    Int  16h                ;call the BIOS
    Jz   Exit               ;no, exit with DescrLen set to a null string

    Inc  DescrLen           ;there is one, assume it's not extended
    Mov  AH,0               ;get a character service
    Int  16h                ;call the BIOS
    Mov  Word Ptr Output,AX ;assign the character(s) to the function output

    Or   AL,AL              ;is it an extended key?
    Jnz  Exit               ;no, so we're all done
    Inc  DescrLen           ;yes, set the function to return two characters

Exit:
    Sti                     ;reenable interrupts, this should NOT be necessary
    Mov  AX,Offset DescrLen ;show BASIC where the descriptor is located
    Ret                     ;return to BASIC

B$INKY Endp
End
