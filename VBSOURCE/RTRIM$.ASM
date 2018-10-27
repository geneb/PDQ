;********** RTRIM$.ASM - PDQ replacement for BASIC's B$RTRM routine

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


.Model Medium, Basic
    Extrn P$FixStr:Proc   ;this is in FIXSTR.ASM
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM
    Extrn P$MakeTemp:Proc ;this is in MAKETEMP.ASM

.Code

B$RTRM Proc Uses SI DI, Work:Word

    Push Work             ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Work,AX          ;

    Mov  SI,Work          ;get address of Work$
    Mov  CX,[SI]          ;put its length into CX
    Jcxz Done             ;we can't process a null string, get out now!
    Std                   ;set the direction to backwards

    Mov  SI,[SI+02]       ;now SI points to the first character in Work$
    Add  SI,CX            ;now SI points just past the end of the string
    Dec  SI               ;now it's at the last character

More:
    Lodsb                 ;get the current character from Work$
    Or   AL,AL            ;is it a null CHR$(0)?
    Jz   Next             ;yes, continue scanning for more blanks

    Sub  AL," "           ;no, but is it a CHR$(32) blank space?
    Jz   Next             ;yes, keep searching
    Jmp  Short Done       ;no, so we're all done

Next:
    Loop More             ;keep looking

Done:
    Call P$MakeTemp       ;claim temporary space in the string pool
    Mov  SI,Work          ;get the starting address again in case it moved
    Mov  SI,[SI+02]
    Rep  Movsb            ;copy the characters there
    Mov  AX,BX            ;show where the output descriptor is
    Cld                   ;we're in *big* trouble if we don't restore this

    Push Work             ;delete the incoming string if necessary
    Call P$FreeTemp
    Ret                   ;return to BASIC

B$RTRM Endp
End
