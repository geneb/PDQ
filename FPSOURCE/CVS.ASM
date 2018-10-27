;********* CVS.ASM - PDQ replacement for BASIC's B$FCVS routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$FreeTemp:Proc   ;this is in FREETEMP.ASM

.Data?
   Output DW 4 Dup (?)      ;a copy of the data goes here

.Code

B$FCVS Proc
    Mov  CX,2               ;we'll copy 2 words into Output
    Db   3Bh                ;this fakes the Mov CX,4 below to a bogus compare
B$FCVS Endp

B$FCVC Proc                 ;this is the CVC entry point
B$FCVC Endp                 ;fall into B$FCVD which the same thing

B$FCVD Proc
    Mov  CX,4               ;we'll copy 4 words into Output
B$FCVD Endp

P$CVBoth Proc Uses SI DI, String:Word

    Cld                     ;ensure that string moves are forward
    Push DS                 ;copy DS into ES
    Pop  ES
    
    Mov  BX,String          ;get the address for String's descriptor
    Mov  SI,[BX+02]         ;now SI points to String's data
    Mov  DI,Offset Output   ;and DI points to Output
    Rep  Movsw              ;copy the data
    
    Push String             ;delete the incoming string if it's a temporary
    Call P$FreeTemp

    Mov  AX,Offset Output   ;show BASIC where the Output is located
    Ret

P$CVBoth Endp
End
