;******** RELMEM.ASM - releases DOS memory previously allocated with AllocMem

;Copyright (c) 1989 Crescent Software

;Syntax - Error% = ReleaseMem%(Segment%)
;
;Where Segment% is the segment that was originally returned by AllocMem.
;If Error% is returned set to -1, then an error occurred (perhaps you gave
;it an invalid segment).


.Model Medium, Basic
.Code

ReleaseMem Proc, OldSeg:Word

    Mov  BX,OldSeg        ;get the address for Segment%
    Mov  ES,[BX]          ;put it into ES for DOS
    Mov  AH,49h           ;release memory service
    Int  21h              ;call DOS to do the hard stuff
    Mov  AX,0             ;assume no error happened
    Jnc  Exit             ;we were right, exit
    Dec  AX               ;there was an error, decrement AX down to -1

Exit:
    Ret                   ;return to BASIC

ReleaseMem Endp
End
