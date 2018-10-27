;********** RSET.ASM - PDQ replacement for BASIC's B$RSET routine

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


.Model Medium, Basic
    Extrn P$FixStr:Proc   ;this is in FIXSTR.ASM
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM

.Code

B$RSET Proc Uses SI DI, FromString:Word, ToString:DWord, NumBytes:Word

    Push FromString       ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  FromString,AX    ;

    Std                   ;ensure that string moves are backward
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

    Add  DI,CX            ;point to the end of the destination string
    Dec  DI               ;the inevitable fudge factor
    Dec  SI               ;prepare for the same thing on the source

    Cmp  CX,AX            ;is the source longer?
    Ja   DestLonger       ;no, skip ahead and fill ToString in pieces
    Add  SI,CX            ;yes, use the left-most portion of the source
    Rep  Movsb            ;and fill only what will fit
    Jmp  Short Exit       ;all done

DestLonger:
    Add  SI,AX            ;point to the end of the source string

    Xchg AX,CX            ;put the destination length into AX, source in CX
    Sub  AX,CX            ;now AX holds the number of blanks to copy later
    Rep  Movsb            ;copy all of the source into the destination

    Mov  CX,AX            ;load CX with the number of blanks to pad
    Mov  AL," "           ;make a blank space
    Rep  Stosb            ;pad the remainder of the destination with blanks

Exit:
    Cld                   ;I'm not your mother, clean up after yourself
    Push FromString       ;delete the incoming string if it is a temporary
    Call P$FreeTemp
    Ret                   ;return to caller

B$RSET Endp
End
