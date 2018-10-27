' PDQZIP (c) 1990 Dan Moore & Crescent Software, Inc.
'
' Demo of functions to access directory of file compressed via PKZIP.
'
'NOTE: This program should be linked using the _STR$.OBJ stub file:
'
'  bc pdqzip /o/s;
'  link /ex/noe/nod/far/packc +
'    pdqzip _str$ _noval _noerror _noread, , nul, smalldos pdq
'
' The PDQZIP program contains the code required to read a .ZIP file
' directory into a TYPE array.  The ZIPCount function and ReadZIPX
' subroutine (inspired from the QuickPak Professional FCount function
' and ReadFileX subroutine) return the number of files stored in the
' .ZIP file, and read the .ZIP file directory into a TYPE array.
'
' The ZIPHdr TYPE variable defines the fields in a .ZIP local file
' header (and partially define those in the .ZIP global directory).
'
' The ZIP TYPE variable defines the fields in the fixed-length array
' into which the ZIP file info will be stored.
'
' The LocalHeader$ and DirHeader$ variables define a .ZIP local file
' and global directory header, and are SHARED by the ZIPCount function
' and the ReadZIPX subroutine.
'
' The GetComment function (added 10-4-92 by EW) returns the ZIP file comment.
'
' The ZIPCount function and ReadZIPX suroutine return the following
' error codes:
'
' Ercd = 0  successful completion
'        1  not a .ZIP file (first file header invalid)
'        2  open error
'        3  read error
'        4  corrupted .ZIP (invalid header other than first)
'
' Note that on DOS errors, the standard ERR variable will also be set
' by P.D.Q.
'
'컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴� PDQZIP.Bas
DEFINT A-Z

'$INCLUDE: 'PDQDECL.BAS'                        'PDQ declarations

DECLARE FUNCTION CvtFDate$ (DateStamp%)         'convert filedate to string
DECLARE FUNCTION CvtFTime$ (FTime%)             'convert filetime to string
DECLARE FUNCTION ZIPCount% (ZipName$, Ercd%)    'returns #files in .ZIP
DECLARE FUNCTION GetComment$ (ZipName$)         'returns ZIP file comment
                                                'reads .ZIP dir into array
DECLARE SUB ReadZIPX (ZipName$, ZIPArray() AS ANY, Ercd%)

'컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
' Each file in a .ZIP archive is preceded by a fixed-length local file
' header and a variable-length filename and "extra info" field.  A central
' directory header immediately follows the last file.
'
' A local file header starts with the identifier X"504b0304".
' The central directory header start with the identifier X"504b0102".
'컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

TYPE ZIPHdr                                     'local file header (30 bytes)
   ID AS STRING * 4                             'file header id
   Ver AS INTEGER                               'ZIP version req. to extract
   GPBits AS INTEGER                            'general purpose bits
   CmpType AS INTEGER                           'compression type
   FTime AS INTEGER                             'last mod file date
   FDate AS INTEGER                             'last mod file time
   CRC32 AS LONG                                'file 32-bit CRC
   CmpSize AS LONG                              'compressed size
   NormSize AS LONG                             'uncompressed size
   NameLen AS INTEGER                           'filename length
   XFldLen AS INTEGER                           'extra field length
END TYPE

TYPE Zip                                        'ZIP array type (38 bytes)
   FileName AS STRING * 12                      'file name
   FileSize AS LONG                             'uncompressed size
   FileTime AS STRING * 8                       'last mod time hh:mm:ss
   FileDate AS STRING * 10                      'last mod date mm-dd-yyyy
   FileCRC AS LONG                              '32-bit file CRC
   ZIPMethod AS INTEGER                         'the compression method
END TYPE

LocalHeader$ = "PK" + CHR$(3) + CHR$(4)         'local file header
DirHeader$ = "PK" + CHR$(1) + CHR$(2)           'central directory header
ZIPExt$ = ".ZIP"                                '.ZIP file extension

ZipFile$ = UCASE$(COMMAND$)                     'get command line
                                                'then the macho stuff
PRINT "PDQZIP 1.1 Copyright (c) 1990 Dan Moore & Crescent Software"

IF LEN(ZipFile$) = 0 THEN                       'nothing in command line
   PRINT                                        'space
   PRINT "File name: ";                         'prompt
   ZipFile$ = SPACE$(64)                        'allocate dummy filename
   BIOSInput ZipFile$, &H1F                     'and go get it
   ZipFile$ = UCASE$(LTRIM$(RTRIM$(ZipFile$)))  'cap. and deblank the sucker
   PRINT                                        'blank line
END IF

IF LEN(ZipFile$) = 0 THEN END                   'no file, get out
IF INSTR(ZipFile$, ".") = 0 THEN                'no extension
   ZipFile$ = ZipFile$ + ZIPExt$                'so add one
END IF

IF NOT PDQExist%(ZipFile$) THEN                 'it ain't there so
   PRINT                                        'just say no
   PRINT "File not found"
   END
END IF

Cmt$ = GetComment$(ZipFile$)                    'display the ZIP file comment
IF LEN(Cmt$) THEN                               'but only if there is one
  PRINT "ZIP file comment: "; Cmt$;
END IF

Z = ZIPCount%(ZipFile$, Ercd)                   'get .ZIP filecount
IF Ercd THEN GOTO ZIPError                      'error, tell 'em and exit
REDIM ZIPArray(1 TO Z) AS Zip                   'allocate info array
ReadZIPX ZipFile$, ZIPArray(), Ercd             'read .ZIP directory
IF Ercd THEN GOTO ZIPError                      'error, tell 'em and exit

PRINT                                           'blanque line
PRINT "ZIP directory listing for: "; ZipFile$   'print zip name
GOSUB PrintHdr
'TotalSize& = 0

FOR I = 1 TO Z                                  'do each element
    PRINT ZIPArray(I).FileName; " ";            'file name, size
    ThisSize& = ZIPArray(I).FileSize
    TotalSize& = TotalSize& + ThisSize&
    PRINT RIGHT$(SPACE$(11) + STR$(ThisSize&), 11); "  ";
    PRINT ZIPArray(I).FileTime; "  ";                   'time stamp
    PRINT ZIPArray(I).FileDate; "  ";                   'date stamp
    PRINT RIGHT$("0" + HEX$(ZIPArray(I).FileCRC), 8);   'CRC, force 8 places
    LOCATE , 59                                         'align
    SELECT CASE ZIPArray(I).ZIPMethod           'display compression method
      CASE 0
         PRINT "Stored"
      CASE 1
         PRINT "Shrunk"
      CASE 2, 3, 4, 5                           'reduced by a factor of 1, 2,
         PRINT "Reduced"                        '  3, or 4
      CASE 6
         PRINT "Imploded"
      CASE 8
         PRINT "Deflated"
      CASE ELSE
         PRINT "Unknown!"
    END SELECT
    IF I MOD 23 = 0 THEN
      PRINT "--more-- ";
      SLEEP
      GOSUB PrintHdr
    END IF
NEXT

PRINT
PRINT "Total size of files in "; ZipFile$; " = "; TotalSize&
END


PrintHdr:
PRINT
PRINT "--FileName----------Size----Time-------Date------CRC32----Method--"
RETURN


ZIPError:                                       'oh no, it broke!
PRINT                                           'space
SELECT CASE Ercd                                'let's check the error
   CASE 1                                       'not a .ZIP
     PRINT "Not a .ZIP file"
   CASE 2                                       'open error
     PRINT "File open error"
   CASE 3                                       'read error
     PRINT "File read error"
   CASE 4                                       'file is corrupted
     PRINT "Corrupted file"
   CASE ELSE
END SELECT
END

FUNCTION CvtFDate$ (Dat) STATIC

'컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
' The file header date is stored in a binary word as follows:
'
' YYYYYYYMMMMDDDDD
'
' Bits 0-4  = day (1-31)
' Bits 5-8  = month (1-12)
' Bits 9-15 = year (relative to 1980)
'
' To extract each value, non-significant bits must be masked first,
' then the value must be shifted right to the low-order position of
' the word.  Shifting is performed using a simple division by the
' equivalent power of 2 -- ie., to shift right 5 bits, the integer
' is divided by 2^5, or 32.  Since the date is an unsigned binary
' value, it is converted to a long integer to ignore the BASIC
' integer sign bit.
'컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
                                                     
IF Dat < 0 THEN                                 'convert to long
   Dat& = 65536 + Dat
ELSE
   Dat& = Dat
END IF
                                                'to get day, simply
Dy = Dat& AND &H1F                              '  mask out yr/mo bits
                                                'for year, mask mo/day
Yr = 1980 + (Dat& AND &HFE00) \ 512             'bits and shift 9 bits
                                                'for month, mask yr/day
Mo = (Dat& AND &H1E0) \ 32                      'bits and shift 5 bits
Mo$ = RIGHT$("0" + STR$(Mo), 2)                 'convert month to string
Dy$ = RIGHT$("0" + STR$(Dy), 2)                 'convert day to string
CvtFDate$ = Mo$ + "-" + Dy$ + "-" + STR$(Yr)    'and assemble the date

END FUNCTION

FUNCTION CvtFTime$ (Tim) STATIC

'컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
' The file header time is stored in a binary word as follows:
'
' HHHHHMMMMMMSSSSS
'
' Bits 0-4   = 2-second increments (0-29)
' Bits 5-10  = minutes (0-59)
' Bits 11-15 = hours (0-23)
'
' To extract each value, non-significant bits must be masked first,
' then the value must be shifted right to the low-order position of
' the word.  Shifting is performed using a simple division by the
' equivalent power of 2 -- ie., to shift right 5 bits, the integer
' is divided by 2^5, or 32.  Since the time is an unsigned binary
' value, it is converted to a long integer to ignore BASIC's integer
' sign bit.
'컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

IF Tim < 0 THEN                                 'convert to long
   Tim& = 65536 + Tim
ELSE
   Tim& = Tim
END IF
                                                'mask out all but sec
Sec = 2 * (Tim& AND &H1F)                       '  and multiply by 2
                                                'mask out min/sec
Hr = (Tim& AND &HF800) \ 2048                   'and shift right 11
                                                'mask hr/sec
Min = (Tim& AND &H7E0) \ 32                     'and shift 5
Hr$ = RIGHT$("0" + STR$(Hr), 2)                 'convert hr to string
Min$ = RIGHT$("0" + STR$(Min), 2)               'convert min to string
Sec$ = RIGHT$("0" + STR$(Sec), 2)               'convert sec to string
CvtFTime$ = Hr$ + ":" + Min$ + ":" + Sec$       'build the time string

END FUNCTION

FUNCTION GetComment$ (Zip$) STATIC  'read comment from file named in Zip$
 
  ZipID$ = "PK" + CHR$(5) + CHR$(6)     'this identifies a file as a ZIP file

  OPEN Zip$ FOR BINARY AS #1            'open the .ZIP file
  FileSize& = LOF(1)                    'get and save its length
  BufferSize = 3072                     'the default header size
  IF BufferSize > FileSize& THEN BufferSize = FileSize&
  Temp$ = SPACE$(BufferSize)            'make buffer to receive ZIP header

  GET #1, FileSize& - BufferSize + 1, Temp$
  CLOSE #1

  Temp = 0                              'find the last occurrence of PK ID
  DO
     HeaderOffset = Temp                'remember where this one is
     Temp = INSTR(Temp + 1, Temp$, ZipID$)      'find the next one
  LOOP WHILE Temp                               'until no more

  IF HeaderOffset THEN                  'if there's a comment, extract it
    CommentLen = CVI(MID$(Temp$, HeaderOffset + 20, 2))
    GetComment$ = MID$(Temp$, HeaderOffset + 22, CommentLen)
  END IF

  Temp$ = ""                            'free up the memory

END FUNCTION

SUB ReadZIPX (ZipName$, ZIPArray() AS Zip, Ercd) STATIC

SHARED LocalHeader$, DirHeader$                   '.ZIP internal headers
DIM Hdr AS ZIPHdr                                 'allocate file/dir header

OPEN ZipName$ FOR BINARY AS #1                    'open file
IF ERR THEN                                       'open error
   Ercd = 2                                       'set error code
   CLOSE #1                                       'close file
   EXIT SUB                                       'and get out
END IF
FilCount = 0                                      'initialize file count

DO                                                '.ZIP read loop
  GET #1, , Hdr                                   'read header
  IF ERR THEN Ercd = 3: EXIT DO                   'read error
  IF Hdr.ID = LocalHeader$ THEN                   'this is a file header
     FilCount = FilCount + 1                      'increment file count
     ZFName$ = STRING$(Hdr.NameLen, 32)           'allocate filename field
     GET #1, , ZFName$                            'read file name
     ZIPArray(FilCount).FileName = ZFName$        'move file name to array
     ZIPArray(FilCount).FileSize = Hdr.NormSize   'move file size to array
                                                  'convert/move date & time
     ZIPArray(FilCount).FileDate = CvtFDate(Hdr.FDate)
     ZIPArray(FilCount).FileTime = CvtFTime(Hdr.FTime)
     ZIPArray(FilCount).FileCRC = Hdr.CRC32       'move file date to array
     ZIPArray(FilCount).ZIPMethod = Hdr.CmpType   'move compression method
                                                  'next header position
     NextHdr& = LOC(1) + Hdr.XFldLen + Hdr.CmpSize + 1
     SEEK #1, NextHdr&                            'position file there
  ELSEIF Hdr.ID = DirHeader$ THEN                 'directory header
     EXIT DO                                      'we're done, exit
  ELSE                                            'invalid header
     IF FilCount = 0 THEN                         'first time around
        Ercd = 1                                  'not a .ZIP file
     ELSE                                         'not first time
        Ercd = 4                                  'bad .ZIP file
     END IF
     EXIT DO                                      'exit
   END IF
LOOP                                              'go look for next file

CLOSE #1                                          'close the .ZIP file

END SUB

FUNCTION ZIPCount% (ZipName$, Ercd) STATIC

SHARED LocalHeader$, DirHeader$                   '.ZIP internal headers
DIM Hdr AS ZIPHdr                                 'allocate file/dir header

OPEN ZipName$ FOR BINARY AS #1                    'open file
IF ERR THEN                                       'open error
   Ercd = 2                                       'set error code
   CLOSE #1                                       'close file
   EXIT FUNCTION                                  'and get out
END IF
FilCount = 0                                      'initialize file count

DO
  GET #1, , Hdr                                   'read header
  IF ERR THEN Ercd = 3: EXIT DO                   'read error
  IF Hdr.ID = LocalHeader$ THEN                   'this is a file header
     FilCount = FilCount + 1                      'increment file count
                                                  'next header position
     NextHdr& = LOC(1) + Hdr.NameLen + Hdr.XFldLen + Hdr.CmpSize + 1
     SEEK #1, NextHdr&                            'position file there
  ELSEIF Hdr.ID = DirHeader$ THEN                 'directory header
     EXIT DO                                      'we're done, exit
  ELSE                                            'invalid header
     IF FilCount = 0 THEN                         'first time around
        Ercd = 1                                  'not a .ZIP file
     ELSE                                         'not first time
        Ercd = 4                                  'bad .ZIP file
     END IF
     EXIT DO                                      'exit
  END IF
LOOP                                              'go look for next file

CLOSE #1                                          'close .ZIP file
ZIPCount% = FilCount                              'return file count value

END FUNCTION

