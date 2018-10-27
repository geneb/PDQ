;********** PDQSETMS.ASM - routine to set the monitor segment for PDQCPrint

;Copyright (c) 1989 Ethan Winer

;syntax: CALL PDQSetMonSeg(NewSegment)
;
;where NewSegment will be used for subsequent calls to PDQPrint and PDQCPrint


.Model Medium, Basic
.Data
    Extrn P$MonSeg: Word  ;this is in MONSETUP.ASM

.Code

PDQSetMonSeg Proc, NewSeg:Word

    Mov  BX,NewSeg        ;get the address for NewSeg
    Mov  BX,[BX]          ;get the actual segment value
    Mov  P$MonSeg,BX      ;save it within the PDQCPrint data area
    Ret                   ;back to BASIC

PDQSetMonSeg Endp
End
