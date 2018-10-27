;********** PDQPRINT.ASM - Quick print routine that accepts a color argument

;Copyright (c) 1989 Ethan Winer
;BC7 conversion 3/90 J.Munro

;Syntax - CALL PDQPrint(Work$, Row%, Column%, Colr%)
;
;Where Work$ will be printed quickly at Row%, Column% in the color specified.


.Model Medium, Basic
    Extrn P$MonSetUp: Proc  ;this is in MONSETUP.ASM
    Extrn StringLength:Proc ;these are QBX internal routines
    Extrn StringAddress:Proc

.Data
    Extrn P$MonSeg:Word     ;this is in MONSETUP.ASM
    Extrn P$PrintWidth:Word ;this is in PDQPWIDE.ASM
    
.Data?
    Extrn P$CGAPort: Word

.Code

PDQPrint Proc Uses DS ES SI DI, Work:Word, Row:Word, Column:Word, Color:Word

    Call P$MonSetUp     ;make sure we have a valid video segment to write to
    Mov  BX,Row         ;get the address for Row%
    Mov  AX,[BX]        ;put it into AX
    Dec  AX             ;adjust 1-25 to 0-24

    Mov  CX,P$PrintWidth    ;get the current screen width
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

    Push AX
    Push ES
    Push SI
    Call StringLength   
    Mov  CX,AX          ;put LEN(Work$) into CX for loop counter
    Pop  ES
    Push SI
    Call StringAddress
    Mov  SI,AX          ;put address of first character in Work$ into SI
    Pop  AX

    Jcxz Exit           ;it's a null string, get out now
    Push DX
    Mov  ES,P$MonSeg    ;put the appropriate monitor segment into ES
    Cld                 ;all string moves below will be forward
    Mov  DX,P$CGAPort   ;put the CGA port address into DX for the In below
    Pop  DS
    Or   DL,DL          ;are we doing monochrome or EGA?
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
