;********** LTRIM$.ASM - PDQ replacement for BASIC's B$LTRM routine

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


.Model Medium, Basic
    Extrn P$FixStr:Proc   ;this is in FIXSTR.ASM
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM
    Extrn P$MakeTemp:Proc ;this is in MAKETEMP.ASM

.Code

B$LTRM Proc Uses SI DI, Work:Word

    Push Work             ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Work,AX          ;

    Mov  SI,Work          ;get address of Work$
    Mov  CX,[SI]          ;put its length into CX
    Jcxz Done             ;a null string, exit with a null output
    Mov  SI,[SI+02]       ;now SI points to the first character in Work$
    Xor  DX,DX            ;clear DX to show how far we scanned

More:
    Lodsb                 ;get the current character from Work$
    Or   AL,AL            ;is it a null CHR$(0)?
    Jz   Next             ;yes, continue scanning for more blanks

    Sub  AL," "           ;no, but is it a CHR$(32) blank space?
    Jz   Next             ;yes, keep searching
    Jmp  Short Done       ;no, so we're all done

Next:
    Inc  DX               ;show that we advanced one more character
    Loop More             ;and keep looking

Done:
    Call P$MakeTemp       ;claim temporary memory in the string pool
    Mov  SI,Work          ;get address of Work$ again in case it moved
    Mov  SI,[SI+02]
    Add  SI,DX            ;now SI points the start of what we're keeping
    Rep  Movsb            ;copy the characters there
    Mov  AX,BX            ;show where the output descriptor is

    Push Work             ;delete the incoming string if necessary
    Call P$FreeTemp
    Ret                   ;return to BASIC

B$LTRM Endp
End
