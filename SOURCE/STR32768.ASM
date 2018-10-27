;********** STR32768.ASM - PDQ DGROUP string pool data declarations

;Copyright (c) 1989 Ethan Winer


;The P.D.Q. string pool is a separate area of memory that is used to hold
;all of the strings assigned within a P.D.Q. program.  By default, a 32K
;pool size is used, which provides 32768 bytes of storage.  Several alternate
;string pool files are also provided, which lets your programs use only as
;much DOS memory as they actually need.  Please see the header comments in
;the following files: ASSIGN$.ASM, MAKETEMP.ASM, and STRDELET.ASM.

.Model Medium, Basic
    Public P$StrPool, P$BytesUsed, P$BytesFree, P$BytesShort
    PoolSize = 32768

.Data?
    Even                          ;this is needed for dynamic string arrays
    P$StrPool DB PoolSize Dup (?) ;32768 bytes of string memory -- it is
                                  ;imperative to use an even number of bytes!
.Data
    P$BytesUsed  DW 0
    P$BytesFree  DW PoolSize
    P$BytesShort DW 0

End
