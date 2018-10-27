;********** FHANDLES.ASM - SMALLDOS table of handles used by OPEN, GET, etc.

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Public P$HandleTbl        ;so everyone else can get at it too

.Data
    P$HandleTbl DW 15 Dup (0) ;table of 15 DOS file handles, initialized to 0

End
