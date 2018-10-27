;********* DOLLAR$.ASM - formats a long integer as money

;written by Paul Passarelli
;Copyright (c) 1989 Crescent Software
;modified by Myrna Traver, 6/28/90

;This string function formats a long integer into dollars and cents.

.Model Medium, Basic
     Extrn B$STI4:Proc       ;this is in STR$.ASM
     Extrn B$STDL:Proc       ;this is in STRDELET.ASM

.Data?
     DescrLen DW  1 Dup(?)   ;this is a "home made" string descriptor
     DescrAdr DW  1 Dup(?)
     Output   DB 12 Dup(?)   ;the output string goes here

.Code

Dollar Proc Uses SI DI, Value:Word

     Mov  SI,Value           ;get the address of the long integer
     Push [SI+02]            ;pass the high word on to B$STI4
     Push [SI]               ;and then the low word
     Call B$STI4             ;let Jay's STR$() do the real work
     Push AX                 ;save this so we can delete it later

     Mov  SI,AX              ;put address of the returned descriptor in SI
     Mov  CX,[SI]            ;put the length in CX
     Mov  SI,[SI+2]          ;put the string address into SI

     Cmp  Byte Ptr [SI],32   ;is there a leading blank?
     Jne  @F                 ;no, so they must be using _STR$.OBJ
     Inc  SI                 ;yes, bump SI past the blank
     Dec  CX                 ;and show the length being one less

@@:
     Cld                     ;foreward ho
     Push DS                 ;address of formatted string
     Pop  ES                 ; ES = DS
     Mov  DI,Offset Output   ; at offset Output

     Mov  BX,2               ;# dec places to BX, faster when comparing later

     Mov  AL,[SI]            ;look at 1st char
     Cmp  AL,"-"             ;is it a negative number?
     Jne  Positive           ;no, move on
     Movsb                   ;yes, copy the sign
     Dec  CL                 ;mark it as moved

Positive:
     Cmp  CL,BL              ;compare the string length to 2
     Jle  PadLeft

Left:                        ;length is greater than 2
     Sub  CL,BL              ;chars to left of dp = CL-BL
     Rep  Movsb
     Mov  AL,"."             ;insert dp
     Stosb
     Jmp  Short Right        ;and go do right side

PadLeft:                     ;need to add leading zero plus dp
     Mov  AX,".0"            ;AL = '0', AH = '.'
     Stosw
     Jz   Right              ;when CL = BL

PadRight:                    ;need to add zeroes right of dp, too
     Xchg CL,BL              ;now CL = digits needed, BL = how many we have
     Sub  CL,BL              ;CL = how many zeroes to add
     Rep  Stosb              ;store the '0' already in AL

Right:
     Mov  CL,BL              ;move chars on the right side
     Rep  Movsb

Done:
     Sub  DI,Offset Output
     Mov  DescrLen,DI
     Mov  DescrAdr,Offset Output

     Call B$STDL             ;delete the STR$() temporary we pushed earlier
     Mov  AX,Offset DescrLen ;show BASIC where the descriptor is
     Ret                     ;return

Dollar Endp
End
