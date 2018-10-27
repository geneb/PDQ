;********** LSET.ASM - PDQ replacement for BASIC's B$LSET routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM
    
.Code

B$LSET Proc Uses SI DI, FromString:Word, ToString:DWord, NumBytes:Word

    Cld                   ;ensure that string moves are forward
    Mov  SI,FromString    ;get the address for the source descriptor
    Les  DI,ToString      ;and get the segmented address for the destination
    Mov  CX,NumBytes      ;load CX with the number of bytes to copy

    Or   CX,CX            ;did they specify NumBytes as non-zero?
    Jnz  FLen             ;yes, so we're assigning to a fixed-length string
    Mov  CX,[DI]          ;no, get the destination length from the descriptor
    Mov  DI,[DI+02]       ;and the destination address too

FLen:
    Mov  AX,[SI]          ;put the source length in AX
    Mov  SI,[SI+02]       ;and its address in SI

    Cmp  CX,AX            ;is the source longer?
    Ja   DestLonger       ;no, skip ahead and fill the destination in pieces
    Rep  Movsb            ;yes, fill what will fit
    Jmp  Short Exit       ;and then exit

DestLonger:
    Xchg AX,CX            ;put the destination length into AX, source in CX
    Sub  AX,CX            ;now AX holds the number of blanks to copy later
    Rep  Movsb            ;copy all of the source into the destination
    Mov  CX,AX            ;load CX with the number of blanks to pad
    Mov  AL," "           ;make a blank space
    Rep  Stosb            ;pad the remainder of the destination with blanks

Exit:
    Push FromString       ;delete the incoming string if it is a temporary
    Call P$FreeTemp
    Ret                   ;return to caller

B$LSET Endp
End
