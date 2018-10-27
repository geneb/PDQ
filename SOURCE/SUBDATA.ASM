;********* SUBDATA.ASM - PDQ data for SUB and FUNCTION support

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic

Public P$RetAdr, P$RetSeg, B$CurFrame   ;so everyone else can get at them

.Data?
    P$RetAdr   DW 1 Dup(?)  ;SUBs & FUNCTIONs do a long jump to this address
    P$RetSeg   DW 1 Dup(?)
    B$CurFrame DW 1 Dup(?)  ;this provides addressability to local variables

End
