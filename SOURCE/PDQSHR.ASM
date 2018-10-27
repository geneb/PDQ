;********* PDQSHR.ASM - shifts bits right a specified number of places

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
.Code

PDQShr Proc                 ;Value:Word, Places:Word -- show what's coming in

    Mov  BX,SP              ;address the stack manually for speed/code size
    Mov  AX,[BX+06]         ;get the value
    Mov  CX,[BX+04]         ;and the number of places
    Shr  AX,CL              ;shift 'em
    Retf 4                  ;return to BASIC popping two parameters

PDQShr Endp
End
