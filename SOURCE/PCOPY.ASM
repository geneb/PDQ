;********* PCOPY.ASM - PDQ replacement for BASIC's PCOPY routine

;PCOPY.ASM  Copyright (c) 1992  Thomas G. Hanlin III


.Model Medium, Basic

.Code

B$PCPY   Proc Uses SI DI DS, SrcPage:Word, DestPage:Word
    Mov  AH,0Fh         ;get video mode
    Int  10h            ;
    Mov  CX,2048        ;assume 40x25 pages
    Cmp  AH,40          ;is it?
    Je   GotPageSize    ;  yep, rock'n'roll
    Shl  CX,1           ;assume 80x25 pages

GotPageSize:
    Mov  AX,SrcPage     ;source page
    Mul  CX
    Mov  SI,AX          ;source offset
    Mov  AX,DestPage    ;destination page
    Mul  CX
    Mov  DI,AX          ;destination offset
    Xor  AX,AX
    Mov  DS,AX
    Mov  AX,0B000h      ;default to mono segment
    Cmp  Byte Ptr DS:[0463h],0B4h ;is it mono?
    Je   GotVidSeg      ;  yep, we're rollin'
    Mov  AH,0B8h        ;set to color segment

GotVidSeg:
    Mov  DS,AX
    Mov  ES,AX
    Shr  CX,1
    Rep  Movsw          ;copy source page to dest page
    Ret                 ;return to caller

B$PCPY   Endp
End
