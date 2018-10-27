;********* PRINTDAT.ASM - date items used by the various PRINT/INPUT routines

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
    Public P$Cooked, P$Handle       ;these are used by INPUT$
    Public P$Descr                  ;this is used by PRINT
    Public P$NullDesc               ;all the PRINT routines can access this
    Public P$1Space                 ;the number printing routines use this

.Data?
    P$Cooked DB 1 Dup (?)           ;this remembers raw/cooked status
    P$Handle DW 1 Dup (?)           ;this remembers the file/device handle

.Data
    P$Descr     DW 2, Offset CRLF   ;a descriptor for the CRLF
    CRLF        DB 13, 10           ;the CRLF data
    P$NullDesc  DW 0                ;a null half-descriptor for anyone to use
    P$1Space    DW 1                ;to print a blank space after the number
    DescrAdr    DW Offset Blank
    Blank       DB " "

End
