;********** FREEFILE.ASM - PDQ replacement for BASIC's B$FREF routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    Extrn P$HandleTbl:Word  ;this is in FHANDLES.ASM

.Code

B$FREF Proc

    Xor  BX,BX              ;start by looking at the first entry

Search:
    Cmp  P$HandleTbl[BX],0  ;is this one available?
    Jz   Exit               ;yes, so we're all done
    Inc  BX                 ;no, consider the next entry
    Inc  BX                 ;two Inc's are faster and less code than Add BX,2

    Cmp  BX,14 * 2          ;have we hit the end?
    Jbe  Search             ;no, keep trying
    Mov  AX,-1              ;yes, force a -1
    Ret                     ;and exit

Exit:
    Shr  BX,1               ;convert number of words to a byte count
    Inc  BX                 ;adjust 0-14 to 1-15
    Mov  AX,BX              ;put the function output into AX
    Ret                     ;return to BASIC

B$FREF Endp
End
