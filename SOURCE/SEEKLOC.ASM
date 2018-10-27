;********* SEEKLOC.ASM - calculates the SEEK offset for use with SMALLDOS.LIB

;Copyright (c) 1989 Ethan Winer


;The algorithm used in this routine is as follows:
;
;   SeekLoc& (RecNumber, RecLength) = ((RecNumber - 1) * RecLength) + 1

.Model Medium, Basic
.Code

SeekLoc Proc, RecNumber:Word, RecLength:Word

    Mov  BX,RecNumber       ;get the address for the record number parameter
    Mov  AX,[BX]            ;put it in AX
    Dec  AX                 ;adjust to zero-based

    Mov  BX,RecLength       ;get the address for the record length parameter
    Mov  BX,[BX]            ;put it into BX
    
    Mul  BX                 ;now DX:AX holds the zero-based answer
    Add  AX,1               ;adjust to BASIC's one-based method
    Adc  DX,0

    Ret                     ;return to BASIC

SeekLoc Endp
End
