;********** STR04096.ASM - PDQ DGROUP string pool data declarations

;Copyright (c) 1989 Ethan Winer

;See the comments in the STR32768.ASM file for more information.


.Model Medium, Basic
    Public P$StrPool, P$BytesUsed, P$BytesFree, P$BytesShort
    PoolSize = 4096

.Data?
    Even
    P$StrPool    DB PoolSize Dup (?)

.Data
    P$BytesUsed  DW 0
    P$BytesFree  DW PoolSize
    P$BytesShort DW 0

End
