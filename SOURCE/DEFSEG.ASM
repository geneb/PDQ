;********** DEFSEG.ASM - PDQ code and data to support DEF SEG, PEEK, BLOAD, etc.

;Copyright (c) 1989 Crescent Software


.Model Medium, Basic
.Data
    Extrn B$Seg: Word       ;this is in PDQDATA.ASM

.Code

B$DSG0 Proc                 ;this is called in response to a plain DEF SEG

    Mov  B$Seg,DS           ;put 'er there
    Ret                     ;return to caller

B$DSG0 Endp



B$DSEG Proc ;, NewSeg:Word  ;this sets a new DEF SEG = xxx segment

    Pop  AX                 ;pop the caller's return address
    Pop  DX                 ;and segment
    Pop  B$Seg              ;pop the new DEF SEG value
    Push DX                 ;restore the original return segment
    Push AX                 ;and address
    Ret                     ;return to BASIC

B$DSEG Endp
End
