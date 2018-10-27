;********** INKEY$.ASM - PDQ replacement for BASIC's B$INKY routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    DescrLen DW 0               ;this is the function's descriptor length
    DescrAdr DW Offset Output1  ;this is its address

.Data?
    Output1  DB 1 Dup (?)       ;this is where the output characters are put
    Output2  DB 1 Dup (?)

.Code

B$INKY Proc

    Xor  AX,AX              ;make a zero the fastest/smallest way possible
    Mov  DescrLen,AX        ;assume no characters are pending
    
    Mov  AH,6               ;keyboard/display function
    Mov  DL,0FFh            ;specify keyboard input
    Int  21h                ;call DOS
    Jz   Exit               ;no key pending, exit with DescrLen set to null

    Inc  DescrLen           ;there is one, assume it's not extended
    Mov  Output1,AL         ;assign the character to the function output
    Or   AL,AL              ;is it an extended key?
    Jnz  Exit               ;no, so we're all done

    Inc  DescrLen           ;yes, set the function to return two characters
    Mov  AH,6               ;now get the extended portion
    Mov  DL,0FFh            ;this probably isn't necessary again....
    Int  21h                ;call DOS
    Mov  Output2,AL         ;now the function is complete

Exit:
    Mov  AX,Offset DescrLen ;show BASIC where the descriptor is located
    Ret                     ;return to BASIC

B$INKY Endp
End
