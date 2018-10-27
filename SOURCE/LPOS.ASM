;********** LPOS.ASM - PDQ replacement for BASIC's LPOS function
;
;LPOS.ASM  Copyright (c) 1992  Thomas G. Hanlin III



.Model Medium, Basic

.Data
    Extrn P$TabTable:Byte           ;this is in FHANDLES.ASM

.Code

B$LPOS Proc, PrtPort:Word

    Mov  AX,PrtPort       ;get printer port
    Cmp  AX,1             ;PRN?
    Mov  AX,0             ;(assume not)
    Ja   Done             ;  no, exit and return zero (LPT2-3 not supported)
    Mov  AL,P$TabTable+4  ;get column from tab tracker
Done:
    Ret                   ;return to caller

B$LPOS Endp
End
