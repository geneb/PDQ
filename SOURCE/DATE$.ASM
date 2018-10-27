;********** DATE$.ASM - PDQ replacement for BASIC's B$FDAT routine

;Copyright (c) 1989 Crescent Software
;written by Paul Passarelli


;This routine provides the function form of DATE$.


.Model Medium, BASIC
.Data
    DescrLen DW  10
    DescrAdr DW  Offset Output
    Output   DB  "  -  -    "

.Code

B$FDAT Proc Uses SI DI

    Push DS               ;assign ES=DS for Stos below
    Pop  ES
    Cld                   ;all moves below will be in the forward direction

    Mov  DI,DescrAdr      ;put the output descriptor address into DI
    Mov  SI,DI            ;keep a copy

    Mov  AH,2Ah           ;get date service
    Int  21h              ;call DOS - return codes as follows:
                          ;DH = Month (1-12)   DL = Day of month (1-31)
                          ;CX = Year 1980 - 2099   Al = Day of week

    Mov  AL,DH            ;copy Month to AL first
    Call Fmdy             ;Fmdy converts values to unpacked BCD
    Mov  AL,DL            ;now copy the Days into AL
    Call Fmdy
    Mov  AX,CX            ;finally establish the Year
    Sub  AX,2000          ;see if 21st century
    Jns  Cent21           ;no

    Mov  AL,19            ;pick a century, isolate the "19"
    Call Fmdy             ;stuff it
    Dec  DI               ;no delimiter here!  Back up 1 place
    Mov  AX,CX            ;reset
    Sub  AX,1900          ;isolate decade and year
    Call Fmdy             ;and away we go
    Jmp  Short Adjust

Cent21:
    Mov  BL,AL            ;save decade and year
    Mov  AL,20            ;pick a century, isolate the "20"
    Call Fmdy             ;stuff it
    Dec  DI               ;no delimiter here!  Back up 1 place
    Mov  AL,BL            ;reset decade and year
    Call Fmdy             ;and away we go

Adjust:
    Mov  CX,2             ;convert Month and Day positions to ASCII by
    Mov  BX,3030h         ;  adding 30h to each character
    Mov  DI,SI            ;match up the source and destination indices

Aamd:                     ;ASCII Adjust Month and Day
    Lodsw                 ;get 2 digits
    Add  AX,BX            ;make them ASCII
    Stosw                 ;put them back
    Inc  DI               ;skip the colon
    Inc  SI
    Loop Aamd             ;ad nauseum

    Mov  CX,2             ;convert Year positions to ASCII by the same method
Aay:                      ;ASCII Adjust Year
    Lodsw                 ;get 2 digits
    Add  AX,BX            ;make them ASCII
    Stosw                 ;put them back
    Loop Aay              ;isn't this fun

    Mov  AX,Offset DescrLen     ;show BASIC where the descriptor is
    Ret                         ;return

B$FDAT  Endp



Fmdy Proc Near

    Aam                   ;convert to unpacked BCD digits
    Xchg AL,AH            ;put them in the right order
    Stosw                 ;move them into the string
    Inc  DI               ;skip over the colon
    Ret

Fmdy EndP
End
