'********** PDQCOPY.BAS - smart COPY utility that copies only newer files

'Copyright (c) 1991 Ethan Winer

'Notice the clever way that an integer array is passed to a subprogram that
'expects a TYPE variable.  This idea is stolen from Don Malin's PDQMake.


'To create the smallest possible file, compile and link as follows:
'
'bc pdqcopy /o/s;
'link /noe/nod/ex/far/packc pdqcopy _noval _noread _noerror,,nul,smalldos pdq
'exe2com pdqcopy


DEFINT A-Z
DECLARE SUB CopyFile (InFile$, OutFile$, DTA AS ANY)
DECLARE SUB FileInfo (Info AS ANY, DTA AS ANY)

'$INCLUDE: 'PDQDECL.BAS'

TYPE DTAType                    'this is used by DOS find first/next service
     Reserved  AS STRING * 21   'reserved for use by DOS
     Attribute AS STRING * 1    'the file's attribute
     FileTime  AS INTEGER       'the file's time
     FileDate  AS INTEGER       'the file's date
     FileSize  AS LONG          'the file's size
     FileName  AS STRING * 13   'the file's name
END TYPE

TYPE FInfo                      'translates each file's information
   Year   AS INTEGER            '  into a usable form
   Month  AS INTEGER
   Day    AS INTEGER
   Hour   AS INTEGER
   Minute AS INTEGER
   Second AS INTEGER
'  Size   AS LONG
'  Attrib AS INTEGER
END TYPE

'The Size and Attribute TYPE members above are not needed here, but they're
'shown so you can add them to the comparisons.  If you do that, change the
'DIM below to DIM File(1 TO 9, 1 TO 2).  Then change the FOR/NEXT loop to
'go from 1 to 9 instead of 1 to 6.

PRINT "PDQCOPY 1.00 Copyright (c) 1991 Crescent Software"
PRINT

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS
DIM SourceDTA AS DTAType        'this DTA holds the source file information
DIM TargetDTA AS DTAType        'and this one is for the destination files
DIM File(1 TO 6, 1 TO 2)        'this holds the information for both files
Zero$ = CHR$(0)                 'do this once ahead of time for speed later


Cmd$ = COMMAND$                 'work with a copy of COMMAND$
CALL SetDelimitChar(32)         'we're using a space as a separator
Source$ = PDQParse$(Cmd$)       'read the source file specification
Target$ = PDQParse$(Cmd$)       'and the destination drive/path

IF LEN(Source$) = 0 OR LEN(Target$) = 0 THEN  'both arguments are mandatory
   PRINT "Usage: PDQCOPY filespec destpath"
   END
END IF
Source$ = Source$ + Zero$                'make an ASCIIZ string for DOS

IF RIGHT$(Target$, 1) <> ":" AND RIGHT$(Target$, 1) <> "\" THEN
   Target$ = Target$ + "\"               'we need a path\file separator
END IF

FOR X = LEN(Source$) TO 1 STEP -1        'isolate the drive/path if present
    Char = ASC(MID$(Source$, X))         'get the current character
    IF Char = 58 OR Char = 92 THEN       'colon or backslash
       SourcePath$ = LEFT$(UCASE$(Source$), X) 'keep what precedes the name
       EXIT FOR                                'bail out of the FOR/NEXT loop
    END IF
NEXT


DO                                       'process all matching source files
   Updated = 0                           'assume the two files are current
   LSET SourceDTA.FileName = ""          'clean out any old name remnants

   Registers.DX = VARPTR(SourceDTA)      'show DOS where the source DTA goes
   Registers.AX = &H1A00                 'specify service 1Ah in AH
   CALL Interrupt(&H21, Registers)       'DOS set DTA service

   IF FilesRead = 0 THEN                 'if this is the first time
      Registers.AX = &H4E00              'find first matching name service
      Registers.DX = SADD(Source$)       'show DOS where the file spec is
      Registers.CX = 39                  'attribute for any type of file
   ELSE
      Registers.AX = &H4F00              'otherwise find next matching file
   END IF

   CALL Interrupt(&H21, Registers)       'see if there's a match
   IF Registers.Flags AND 1 THEN EXIT DO 'if carry flag is set we're done
   FilesRead = FilesRead + 1             'otherwise show we read another one
   CALL FileInfo(File(1, 1), SourceDTA)  'get the source file's date and time
  
   Registers.DX = VARPTR(TargetDTA)      'create 2nd DTA for the destination
   Registers.AX = &H1A00                 'specify service 1Ah in AH
   CALL Interrupt(&H21, Registers)       'DOS set DTA service

   Dest$ = Target$ + SourceDTA.FileName  'concatenate the target and the name
   Registers.AX = &H4E00                 'find first matching destination file
   Registers.DX = SADD(Dest$)            'show DOS where the new file spec is
  
   CALL Interrupt(&H21, Registers)       'see if there's a match
   IF Registers.Flags AND 1 THEN         'if carry is set the file's not there
      Updated = 1                        'so we'll have to update it
   ELSE
      CALL FileInfo(File(1, 2), TargetDTA) 'get the target file date and time
      FOR X = 1 TO 6                       'compare from year through seconds
          IF File(X, 1) > File(X, 2) THEN       'if the target is older
             Updated = 1                        '  set the flag and exit
             EXIT FOR
          ELSEIF File(X, 1) < File(X, 2) THEN   'if newer there's no need
             EXIT FOR                           '  to continue comparing
          END IF
      NEXT
   END IF

   IF Updated THEN                       'copy only if necessary
      SourceFile$ = SourcePath$ + SourceDTA.FileName
      IF Skipped THEN PRINT              'so the name starts on a new line
      PRINT "copying "; SourceFile$; " to "; Target$
      CALL CopyFile(SourceFile$, Target$ + SourceDTA.FileName, SourceDTA)
      FilesCopied = FilesCopied + 1      'show that we copied another one
      Skipped = 0
   ELSE
      PRINT ".";                         'show that a file was just skipped
      Skipped = -1
   END IF
LOOP

IF Skipped THEN PRINT
PRINT FilesRead; "files examined"
PRINT FilesCopied; "files copied"

SUB CopyFile (InFile$, OutFile$, DTAInfo AS DTAType) STATIC

    SHARED Registers AS RegType

    File1 = FREEFILE
    OPEN InFile$ FOR INPUT AS #File1            'open the source file

    File2 = FREEFILE
    OPEN OutFile$ FOR OUTPUT AS #File2          'open/create the destination

    Remaining& = LOF(File1)                     'how many bytes remain to be
    DO                                          '  copied
       IF Remaining& > 4096 THEN                'copy in 4K blocks
          ThisPass = 4096
       ELSE
          ThisPass = Remaining&                 'except the last block may
       END IF                                   '  be smaller

       IF LEN(Buffer$) <> ThisPass THEN         'make a new buffer only
          Buffer$ = SPACE$(ThisPass)            '  if necessary
       END IF

       GET #File1, , Buffer$                    'read from Peter
       PUT #File2, , Buffer$                    'write to Paul
       Remaining& = Remaining& - ThisPass       'show that we read that much
    LOOP WHILE Remaining&                       'until there ain't no more

    CLOSE File1                                 'close the input file

    Registers.AX = &H5701                       'set the target date and time
    Registers.BX = FILEATTR(File2, 1)           ' the same as the source file
    Registers.DX = DTAInfo.FileDate
    Registers.CX = DTAInfo.FileTime
    CALL Interrupt(&H21, Registers)
   
    CLOSE File2                                 'close the target file

END SUB

SUB FileInfo (Info AS FInfo, DTA AS DTAType) STATIC

    Info.Year = PDQShr%(DTA.FileDate AND &HFE00, 9) + 80 'compute the year
    Info.Month = PDQShr%(DTA.FileDate AND &H1E0, 5)      'compute the month
    Info.Day = DTA.FileDate AND &H1F                     'compute the day
    Info.Hour = PDQShr%(DTA.FileTime AND &HF800, 11)     'compute the hour
    Info.Minute = PDQShr%(DTA.FileTime AND &H7E0, 5)     'compute the minute
    Info.Second = PDQShl%(DTA.FileTime AND &H1F, 1)      'compute the second

END SUB

