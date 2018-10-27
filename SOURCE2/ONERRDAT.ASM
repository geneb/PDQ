;********** ONERRDAT.ASM - data for ON ERROR/RESUME and the /d debug option

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
    Public P$OnErrStack, P$ErrAdr, P$ErrSeg, P$OnErrBP
    Public P$NextAdr, P$NextSeg, P$NextStack, P$NextBP

.Data?
    P$OnErrStack DW 1 Dup(?) ;this remembers the stack at the point that
                             ;  ON ERROR was first used (in the main)
    P$OnErrBP    DW 1 Dup(?) ;this saves what BP should be in the main
    P$NextAdr    DW 1 Dup(?) ;this saves the address at which to RESUME NEXT
    P$NextSeg    DW 1 Dup(?) ;this is the segment (these are set in DOERROR)
    P$NextStack  DW 1 Dup(?) ;restore the stack to this value on RESUME NEXT
    P$NextBP     DW 1 Dup(?) ;this saves what BP was when DoError was called

.Data
    P$ErrAdr     DW -1     ;the address and segment to GOTO upon an error
    P$ErrSeg     DW -1     ;  (ON ERROR GOTO 0 default is indicated with -1)

End
