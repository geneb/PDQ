;********** TIME$.ASM - PDQ replacement for BASIC's B$FTIM routine

;Copyright (c) Crescent Software 1990
;written by Paul "If you can comment it you own it" Passarelli

;This routine does not use the standard DOS Time services.  It reads the
;system timer count stored in low memory and converts it directly, to allow
;using TIME$ within any TSR.
;
;A day consists of 1,573,039 timer ticks, or 86,400 seconds.  To obtain an
;adequate resolution, this procedure uses a value five times the number of
;ticks recorded.  This code was "borrowed" from COMMAND.COM, with the steps
;to calculate 1/100th seconds purposely omitted.


.Model Medium,BASIC
    Extrn PDQTimer:Proc
    
.Data
    DescrLen DW  8
    DescrAdr DW  Offset Output
    Output   DB  "  :  :  "

.Code

B$FTIM Proc Uses SI

    Call PDQTimer               ;get ticks since midnight in DX:AX

    Push DX                     ;save the high word
    Push AX                     ;and the low word

    Shl  AX,1                   ;multiply the timer by 2
    Rcl  DX,1
    
    Shl  AX,1                   ;now this multiplies the timer by 4
    Rcl  DX,1

    Pop  BX                     ;finally this multiplies the timer by 5
    Add  AX,BX
    Pop  BX
    Adc  DX,BX

    Mov  CX,0E90Bh              ;use the constant 59659 first
    Div  CX                     ;ticks by the 1st constant
    Mov  BX,AX                  ;save the 1st quotient in BX

    Xor  AX,AX                  ;now set remainder * 65536 for next divide
    Div  CX                     ;remainder * 65536 \ 59659

    Mov  DX,BX                  ;make a new long from 1st quotient * 65536
                                ;plus 2nd quotient already in AX
    Mov  CX,00C8h               ;use the constant 200 for the 3rd divide
    Div  CX                     ;newlong  \ 200

    Cmp  DL,100                 ;is the remainder >=  100
    Jb   Tick1                  ;no, move on
    Sub  DL,100                 ;yes, subtract 100
    
Tick1:
    Cmc                     
    Rcl  AX,1                   ;multiply the 3rd quotient by 2 and
                                ;add 0 or 1 as appropriate
    Mov  DL,0                   ;clear the hi word
    Rcl  DX,1                   ;accept the possible carry from above

    Mov  CX,60                  ;because DX:AX is now in seconds
    Div  CX                     ;Seconds (0-59) are DL, AX is in minutes
    Div  CL                     ;quotient, Hours are in AL
    Mov  BL,AH                  ;remainder, Minutes in AH are saved in BL

    Mov  SI,DescrAdr            ;SI points to the output string data
    Mov  CX,3030h               ;this is "00" in ASCII

    Aam                         ;`unpack' the hours
    Xchg AH,AL                  ;make 'em "24" not "42"
    Add  AX,CX                  ;bump it into the ascii range
    Mov  [SI],AX                ;write 'em to the string

    Mov  AL,BL
    Aam                         ;`unpack' the minutes
    Xchg AH,AL                  ;make 'em "59" not "95"
    Add  AX,CX                  ;bump it into the ascii range
    Mov  [SI+3],AX              ;write 'em to the string

    Mov  AL,DL
    Aam                         ;`unpack' the seconds
    Xchg AH,AL                  ;make 'em "59" not "95"
    Add  AX,CX                  ;bump it into the ASCII range
    Mov  [SI+6],AX              ;write 'em to the string

    Mov  AX,Offset DescrLen     ;show BASIC where the descriptor is
    Ret                         ;return

B$FTIM Endp
End
