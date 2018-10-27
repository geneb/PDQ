;********** PDQPRINT.ASM - Quick print routine that accepts a color argument

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support

;Syntax - CALL PDQPrint(Work$, Row%, Column%, Colr%)
;
;Where Work$ will be printed quickly at Row%, Column% in the color specified.


.Model Medium, Basic
    Extrn P$FixStr:Proc     ;this is in FIXSTR.ASM
    Extrn P$MonSetUp: Proc  ;this is in MONSETUP.ASM

.Data
    Extrn P$CGAPort:Word    ;these are in MONSETUP.ASM
    Extrn P$MonSeg:Word
    Extrn P$PrintWidth:Word ;this is in PDQPWIDE.ASM

.Code

PDQPrint Proc Uses SI DI, Work:Word, Row:Word, Column:Word, Color:Word

    Push Work             ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Work,AX          ;

    Call P$MonSetUp     ;make sure we have a valid video segment to write to
    Mov  ES,P$MonSeg    ;put the appropriate monitor segment into ES

    Mov  BX,Row         ;get the address for Row%
    Mov  AX,[BX]        ;put it into AX
    Dec  AX             ;adjust 1-25 to 0-24
    Mov  CX,P$PrintWidth;get the current screen width
    Mul  CX             ;multiply to get the base address of the current row

    Mov  BX,Column      ;get the address for Column%
    Mov  DX,[BX]        ;put it into DX
    Dec  DX             ;adjust 1-80 to 0-79
    Shl  DX,1           ;multiply times 2 to consider the attribute byte
    Add  AX,DX          ;now AX holds the correct screen address
    Mov  DI,AX          ;transfer to DI for Stos below

    Mov  BX,Color       ;get the color that was passed
    Mov  AH,[BX]        ;put it into AH for direct screen writing below
    Mov  SI,Work        ;get address of Work$ descriptor and put it into SI
    Mov  CX,[SI]        ;put LEN(Work$) into CX for loop counter
    Jcxz Exit           ;it's a null string, get out now
    Mov  SI,[SI+02]     ;put address of first character in Work$ into SI

    Cld                 ;all string moves below will be forward
    Mov  DX,P$CGAPort   ;put the CGA port address into DX for the In below
    Or   DL,DL          ;are we doing monochrome or EGA/VGA?
    Je   Mono           ;yes, go do it

No_Retrace:
    In   AL,DX          ;get the video status byte
    Test AL,1           ;test just the horizontal retrace bit
    Jnz  No_Retrace     ;if doing a retrace, wait until it's not
    Cli                 ;disable interrupts until we're done writing to screen

Retrace:
    In   AL,DX          ;get the status byte again
    Test AL,1           ;are we currently doing a retrace?
    Jz   Retrace        ;no wait until we are

    Lodsb               ;get the current character from Work$
    Stosw               ;store the character and attribute into screen memory
    Sti                 ;re-enable interrupts
    Loop No_Retrace     ;loop until we're finished
    Jmp  Short Exit     ;skip over and get out

Mono:
    Lodsb               ;get the current character from Work$
    Stosw               ;store the character and attribute into screen memory
    Loop Mono           ;until done CX times

Exit:
    Ret                 ;return to BASIC

PDQPrint Endp
End
