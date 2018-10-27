;********** FHANDLES.ASM - table of file handles used by OPEN, GET, etc.

;Copyright (c) 1989 Ethan Winer


;The Handle and Record tables are organized to correspond to BASIC file
;numbers.  That is, [PRINT #4] gets the DOS handle from the fourth entry in
;the Handle table, and [PUT #4, RecordNumber, DataStuff] obtains the record
;length from the fourth entry in the Record table.  However, the Tab table
;holds the current print column for the specified *DOS handle*.  Therefore,
;[PRINT #4, TAB(20)] needs to know the DOS handle that goes with BASIC file
;number 4, in order to access the correct entry in the Tab table.  This is
;all handled automatically by PRINT, which knows the current DOS handle by
;looking at P$PrintHandle (in the PHANDLE.ASM file).  The Tab table is also
;referenced in the CLS.ASM, TAB.ASM, OPEN.ASM, and PRNCOMMA.ASM source files.
;
;Note that the first entry in the Tab table is for the keyboard and is never
;used.  Wasting a byte here saves many bytes in all of the routines that
;reference the Tab table and treat it as being 1-based rather than 0-based.
;(Values in the table are 0-based but the offsets to each entry are 1-based.)
;
;Also note that values in the Tab table are allowed to wrap around past 255.
;Therefore, if you use a statement such as PRINT #2, STRING$(300, 65); and
;then follow that with PRINT #1, TAB(anything); the PRINT TAB statement will
;print less spaces than you expected.  Tests with regular QuickBASIC show
;that it too handles unlikely TAB values in a quirky manner.  But what would
;you expect to happen in such a case?


.Model Medium, Basic
    Public P$HandleTbl        ;so everyone else can get at them too
    Public P$RecordTbl
    Public P$TabTable

.Data
    P$HandleTbl DW 15 Dup (0) ;table of 15 DOS file handles, initialized to 0
    P$RecordTbl DW 15 Dup (0) ;table of 15 record lengths, initialized to 0
    P$TabTable  DB 20 Dup (0) ;table of 20 current Tab column positions

End
