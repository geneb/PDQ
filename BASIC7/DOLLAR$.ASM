;********* DOLLAR$.ASM - formats a long integer as money

;written by Paul Passarelli
;Copyright (c) 1989 Crescent Software
;BC7 environment version

;This string function formats a long integer into dollars and cents.

.Model Medium, Basic
     Extrn B$STI4:Proc       ;this is in STR$.ASM
     Extrn StringAssign:Proc ;these are internal QBX routines
     Extrn StringAddress:Proc
     Extrn StringLength:Proc
     Extrn B$STDL:Proc

.Data?
     DescrLen DW  1 Dup(?)   ;this is a "home made" string descriptor
     DescrAdr DW  1 Dup(?)
     Output   DB 12 Dup(?)   ;the output string goes here

.Code

Dollar Proc Uses SI DI, Value:Word

     Push DS
     Push ES
     Mov  SI,Value           ;get the address of the long integer
     Push [SI+02]            ;pass the high word on to B$STI4
     Push [SI]               ;and then the low word
     Call B$STI4             ;let STR$() do the real work
     Pop  ES
     Push AX                 ;save this so we can delete it later
     Mov  SI,AX              ;put address of the returned descriptor in SI
     Push ES                 ;StringAddress trashes ES
     Push SI                 ;push address of descriptor
     Call StringAddress      ;get string address (SI is preserved)
     Pop  ES
     Push DX
     Push AX                 ;save the address
     Push SI
     Call StringLength
     Mov  CX,AX              ;put the length in CX
     Pop  SI                 ;pop the string address into SI
     Pop  DX

     Cld                     ;foreward ho
     Push DX                 ;push string segment
     Push DS                 ;assign ES = DS for the copy
     Pop  ES
     Pop  DS                 ;point DS at string segment

     Mov  DI,Offset SS:Output   ;where to put the string while we work

     Mov  BX,2               ;put a 2 into BX, faster when comparing later
     ;----------------------- check for a negative number
     Mov  AL,DS:[SI]         ;get the first character
     Cmp  AL,"-"             ;is it a negative number?
     Jne  Positive           ;no, move on
     Movsb                   ;yes, copy the sign
     Dec  CL                 ;mark it as moved
     Inc  BH                 ;mark it as signed

Positive:
     Cmp  CL,BL              ;compare the string length to 2
     Ja   Assign1            ;it's longer, so we don't have to add any digits
     Pushf                   ;save the comparison results
     Mov  CL,4               ;store "0.00", which is 4 characters
     Add  CL,BH              ;add one if we need a minus sign: "-0.00"
     Mov  SS:DescrLen,CX     ;now assign the output length

     Mov  AX,".0"            ;make both characters at once
     Stosw                   ;assign 'em to the output
     Popf                    ;now get the result of the earlier compare
     Je   Assign2            ;branch as appropriate
     Jb   Assign3

Assign1:
     Add  CL,BH              ;add one to account for the sign if needed
     Inc  CL                 ;add one to account for the added period
     Mov  SS:DescrLen,CX     ;assign this length to the descriptor
     Sub  CL,3               ;adjust out the pennies & decimal point
     Sub  CL,BH              ;again with the sign flag if needed
     Rep  Movsb              ;copy the dollars
     Mov  AL,"."             ;insert decimal point
     Stosb                   ;"????.  "

Assign2:
     Mov  CL,BL              ;put the cents back
     Rep  Movsb
     Jmp  Short Broke        ;(Broke - as in no more money)

Assign3:
     Mov  AL,"0"             ;make a zero
     Stosb                   ;stuff it
     Movsb                   ;move it

Broke:
     Pop  SI                 ;retrieve string descriptor save earlier
     Pop  DS                 ;retrieve segment it is stored in
     Push SI                 ;push string descriptor to delete
     Call B$STDL             ;delete the temporary that STR$ returned earlier

     Push DS                 ;push segment of source string
     Mov  AX,Offset Output   ;push offset of source string
     Push AX
     Mov  CX,DescrLen        ;get length of string
     Push CX                 ;push it

     Push DS                 ;push segment of destination descriptor
     Mov  AX,Offset Descrlen ;push address of destination decriptor
     Push AX
     Xor  AX,AX              ;tell BASIC this is a variable length string
     Push AX
     Mov  Descrlen,AX        ;also clear descrlen so BASIC won't try to 
                             ; unassign it
     Call StringAssign
     Mov  AX,Offset DescrLen ;show BASIC where the descriptor is
     Ret                     ;return

Dollar Endp
End
