'********** PDQMAKE.BAS - file date/time comparison utility for batch files
'
'Copyright (c) 1990 Don Malin & Crescent Software
'
'This program can be used in a batch file to determine whether a file is out
'of date compared to one or more dependant files.  The program does most of
'what you would use MAKE.EXE or NMAKE.EXE for, but it can be used in a batch
'file.  The program could also be turned into a callable procedure if you
'need this functionality in your own program.
'
'Notice the way a two-dimensional integer array is passed to the FileInfo
'subprogram, even though FileInfo is expecting a single TYPE variable.  While
'this precludes PDQMake from being run in the QB editing environment, this
'parameter type "aliasing" is a perfectly valid way to pass a single column
'of an array to a subprogram that doesn't expect that.
'
'Usage:
'  PDQMAKE TargetFile Dependant1 [Dependant2 .. Dependant[n]]
'
'Where:
'  TargetFile is the name of the main file that is being checked.
'  Dependant1, 2, and so forth are the names of the dependant file(s).
'
'PDQMake returns a DOS ERRORLEVEL of either 0 if the dependant files are
'current, or 1 if the date and/or time are less than any of the listed
'dependant files.
'
'Example batch file:
'
'  @ECHO OFF
'
'  REM See if the source or include files have changed since the last time
'  REM this source file was compiled, and re-compile if so.
'
'  PDQMAKE pdqmake.obj pdqmake.bas pdqdecl.bas
'  IF ERRORLEVEL 1 bc pdqmake /s/o;
'
'  REM See if any object files, stub files, or the PDQ library have changed
'  REM since the last time they were linked, and re-link if so.
'
'  PDQMAKE pdqmake.exe pdqmake.obj _noread.obj pdq.lib
'  IF ERRORLEVEL 1 link /noe/nod/ex pdqmake _noread _noval _noerror,,nul,pdq;
'
'  REM Is the COM file older than the EXE?
'
'  PDQMAKE pdqmake.com pdqmake.exe
'  IF ERRORLEVEL 1 exe2com pdqmake
'
'Compile and link this program as shown above.
'
'****************************************************************************

DEFINT A-Z

'$INCLUDE: 'PDQDECL.BAS'

DECLARE SUB FileInfo (FileName$, Info AS ANY)

'----- The following two TYPEs are used by the FileInfo subprogram
TYPE DTAType                                    'Holds DOS's file information
   Reserved  AS STRING * 21                     '  in compressed form.
   Attribute AS STRING * 1
   DTATime   AS INTEGER
   DTADate   AS INTEGER
   FileSize  AS LONG
   DTAName   AS STRING * 13
END TYPE

TYPE FInfo                                      'Holds the files information
   Year   AS INTEGER                            '  in usable form.
   Month  AS INTEGER
   Day    AS INTEGER
   Hour   AS INTEGER
   Minute AS INTEGER
   Second AS INTEGER
   Size   AS LONG
   Attrib AS INTEGER
END TYPE

Cmd$ = COMMAND$                                 'Make a copy of the command
                                                '  line arguments.
                                                
SetDelimitChar (32)                             'Set a space as the delimiter
FileName$ = PDQParse$(Cmd$)                     'Parse out the target's name

Newer = 0                                       'Assume it's up to date

IF NOT PDQExist%(FileName$) THEN                'If it isn't there, it is out
   Newer = 1                                    '  of date so set the flag.
   
ELSE
   DIM File(1 TO 9, 1 TO 2)                     'Make an array to hold the
                                                '  information for two files
                                                
   FileInfo FileName$, File(1, 1)               'Get the target files info.

   DO
      FileName$ = PDQParse$(Cmd$)               'Get the name of the next
      IF LEN(FileName$) = 0 THEN EXIT DO        '  dependant file.

      IF NOT PDQExist%(FileName$) THEN          'If it's not there then it's
         Newer = 1                              'out of date, show that
         EXIT DO                                'and bail out
      END IF

      FileInfo FileName$, File(1, 2)            'Get date, time, (and size)

      FOR N = 1 TO 6                            'Compare date numbers from
                                                '  year through seconds.
         IF File(N, 2) > File(N, 1) THEN        'If dependant is older,
            Newer = 1                           '  set the flag and bail out.
            EXIT DO
         ELSEIF File(N, 2) < File(N, 1) THEN    'If it is newer, no need to
            EXIT FOR                            '  continue comparisons.
         END IF
      NEXT
   LOOP
END IF

EndLevel Newer                                  'Assign flag to DOS ERRORLEVEL

SUB FileInfo (FileName$, Info AS FInfo)

    DIM Registers AS RegType
    DIM DTA AS DTAType          'create a Disk Transfer Area

    Registers.DX = VARPTR(DTA)  'set the DTA to use our local variable
    Registers.AX = &H1A00       'this is the DOS service to do that
    Interrupt &H21, Registers   'call DOS

    LocalName$ = FileName$ + CHR$(0)    'make an ASCIIZ string for DOS
    Registers.CX = 39                   'look for any type of file
    Registers.DX = SADD(LocalName$)     'show DOS where the file name is
    Registers.AX = &H4E00               'find first matching name service
    Interrupt &H21, Registers           'ask DOS to do it

    Info.Year = PDQShr%(DTA.DTADate AND &HFE00, 9) + 80 'compute the year
    Info.Month = PDQShr%(DTA.DTADate AND &H1E0, 5)      'compute the month
    Info.Day = DTA.DTADate AND &H1F                     'compute the day
    Info.Hour = PDQShr%(DTA.DTATime AND &HF800, 11)     'compute the hour
    Info.Minute = PDQShr%(DTA.DTATime AND &H7E0, 5)     'compute the minute
    Info.Second = PDQShl%(DTA.DTATime AND &H1F, 1)      'compute the second
    Info.Size = DTA.FileSize

END SUB

