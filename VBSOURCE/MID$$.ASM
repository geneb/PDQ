;********** MID$$.ASM - PDQ replacement for BASIC's B$SMID routine

;Copyright (c) 1989 Ethan Winer
; 11/21/92  Thomas G. Hanlin III   added far string support


;This routine provides the statement form of MID$.


.Model Medium, Basic
    Extrn P$FixStr:Proc   ;this is in FIXSTR.ASM
    Extrn P$FMID:Proc     ;this is in MID$.ASM
    Extrn B$LSET:Proc     ;this is in LSET.ASM

.Data?
    DescrLen DW 1 Dup(?)  ;use this to pass a fixed-length string to P$FMID
    DescrAdr DW 1 Dup(?)

.Code

B$SMID Proc, DestSeg:Word, DestAdr:Word, StrLength:Word, Source:Word, NumChars:Word, StartChar:Word

    Push Source           ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Source,AX        ;

    Mov  AX,StrLength     ;get the incoming string length
    Mov  DescrLen,AX      ;save it locally in case its a fixed-length string
    Or   AX,AX            ;are they telling us that DestAdr is a descriptor?
    Jz   UseDescript      ;yes, so pass that address on to B$FMID

    Mov  AX,DestAdr       ;get the address
    Mov  DescrAdr,AX      ;and copy that to the bogus descriptor too
    Mov  AX,Offset DescrLen  ;move the descriptor address to the stack so
    Mov  DestAdr,AX          ;  it will be pushed instead of the data address

UseDescript:
    Mov  BX,Source        ;we need to use the shorter of the two lengths
    Mov  BX,[BX]          ;get the length of the source string
    Cmp  BX,NumChars      ;is that longer than NumChars?
    Ja   SourceLonger     ;yes, so skip ahead leaving NumChars where it is
    Mov  NumChars,BX      ;no, clip NumChars to the source length

SourceLonger:
    Push DestAdr          ;pass the address for the destination on to P$FMID
    Push StartChar        ;and the starting character number
    Push NumChars         ;and the number of characters to consider too
    Call P$FMID           ;P$FMID returns a pointer to the string portion

    Push Source           ;pass the address for the source string to B$LSET
    Push DestSeg          ;LSET needs a segmented address for the destination
    Push AX               ;push the descriptor address P$FMID returned
    Xor  AX,AX            ;make a zero to tell LSET to use the descriptors
    Push AX               ;push that too
    Call B$LSET           ;now we'll sit back, and let LSET do the hard part!

    Ret                   ;return to BASIC

B$SMID Endp
End
