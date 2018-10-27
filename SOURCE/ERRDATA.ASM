;********* ERRDATA.ASM - the current ERR value and ERR lookup table

;Copyright (c) 1989 Ethan Winer

;Error values in P.D.Q. are stored as follows:
;
;The six "standard" DOS errors are kept in a table, and translated by the
;BASIC ERR function each time it is invoked.  Since DOS reduces all errors
;(at least the simplified errors we are accommodating) to only six values,
;this greatly reduces the amount of code needed in each DOS routine.  For
;example, if OPEN detects an error, it simply puts the DOS return value in
;the public P$PDQErr variable (below), and then exits.  All other BASIC
;errors are stored as their actual values.
;
;The only exceptions are BASIC's "Illegal function call", which is stored as
;a -1, and "Out of data" which is kept as a -2.  These substitutions are
;necessary because QuickBASIC uses 4 and 5 for these errors, but DOS also
;uses them for its "Access denied" (5) and "Too many open files" (4) errors.
;Notice that the code in ERR.ASM retrieves the -1 and -2 errors by using a
;negative offset from the ErrorTbl.
;
;When the /d Debug option is used, "RETURN without GOSUB" errors are stored
;using the value 127.  This is not used by either ERR or ERROR, however the
;PDQMessage function recognizes that value.  It just isn't worth adding yet
;more test conditions to accommodate occasional debugging.  Similarly, we had
;to make up an error number for "Overflow" for debugging, which is 125.


.Model Medium, Basic
    Public P$PDQErr, P$ErrorTbl     ;so everyone else can get at them too

.Data
    NoMoData   DB 4                 ;this is translated from a -2
    BadFunct   DB 5                 ;this is translated from a -1
    P$PDQErr   DW 0                 ;this holds the most recent error value
    P$ErrorTbl DB 54,53,76,67,75,52 ;these are the DOS errors to translate
    
End
