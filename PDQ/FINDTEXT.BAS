'********** FINDTEXT.BAS - text find utility searches multiple files

'Copyright (c) 1989 Ethan Winer


'To create the smallest possible file, compile and link as follows:
'
'  BC FINDTEXT /O;
'  LINK /NOE/NOD/FAR/PACKC _
'    FINDTEXT _NOVAL _NOREAD _NOERROR , , NUL, SMALLDOS PDQ
'  EXECOM FINDTEXT


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS
CONST MaxFiles% = 1000          'the maximum number of files we can search
                                '(this could be expanded to 2000 if necessary)
CONST BufMax% = 4096            'the maximum buffer length

TYPE DTA                        'this is used by DOS find first/next service
     Reserved  AS STRING * 21   'reserved for use by DOS
     Attribute AS STRING * 1    'the file's attribute
     FileTime  AS STRING * 2    'the file's time
     FileDate  AS STRING * 2    'the file's date
     FileSize  AS LONG          'the file's size
     FileName  AS STRING * 13   'the file's name
END TYPE

DIM DTAData AS DTA              'this holds the file info for DOS as it works
REDIM Array$(1 TO MaxFiles%)    'make an array to hold the file names
Zero$ = CHR$(0)                 'do this once ahead of time for speed later


'----- this function returns the maximum of two integer values
DEF FNMax% (Value1, Value2)
    FNMax% = Value1                             'assume Value1 is greater
    IF Value2 > Value1 THEN FNMax% = Value2     'we were wrong, return Value2
END DEF


'----- this function "capitalizes" an integer value
DEF FNIntUpper% (Character)
    FNIntUpper% = Character                     'assume it's already upper
    IF Character >= 97 AND Character <= 122 THEN FNIntUpper% = Character - 32
END DEF


'----- this function loads a group of matching file names into Array$()
DEF FNLoadNames%

    STATIC Count                        'this is a local variable

    Registers.DX = VARPTR(DTAData)      'show DOS where the new DTA is located
    Registers.AX = &H1A00               'specify service 1Ah in AH
    Interrupt &H21, Registers           'DOS set DTA service

    Count = 0                           'zero out the file counter
    Spec$ = Spec$ + Zero$               'make an ASCIIZ string for DOS
    Registers.DX = SADD(Spec$)          'show DOS where the file spec is
    Registers.CX = 39                   'attribute for any type of file
    Registers.AX = &H4E00               'find first matching name service

    DO
       Interrupt &H21, Registers                'see if there's a match
       IF Registers.Flags AND 1 THEN EXIT DO    'error if carry flag is set
       Count = Count + 1                        'show we found another one
       Array$(Count) = DTAData.FileName         'copy the name to the array
       Registers.AX = &H4F00                    'find next matching name
    LOOP WHILE Count < MaxFiles%                'stop if we reach MaxFiles%

    FNLoadNames% = Count                        'assign the function output

END DEF



'----- the main body of the program begins here
PRINT "FindText 1.01, Copyright (c) 1989 Crescent Software"
PRINT

Spec$ = COMMAND$                        'see if they already entered it
IF LEN(Spec$) = 0 THEN                  'they didn't, so prompt for one
   PRINT "Enter a file specification: ";
   PDQInput Spec$
END IF

PRINT "    Enter the text to find: ";   'prompt for the text to search for
PDQInput Find$
PRINT

Find$ = UCASE$(Find$)                   'search regardless of capitalization
FindLength = LEN(Find$)                 'see how long Find$ really is
IF FindLength = 0 THEN END              'bag out if they didn't enter anything

Count = FNLoadNames%                    'count and load the file names
IF Count = 0 THEN                       'none matched, so tell 'em and end
   PRINT "No matching files"
   END
END IF

FOR X = LEN(Spec$) TO 1 STEP -1         'isolate the drive/path if present
    Char = ASC(MID$(Spec$, X))          'get the current character
    IF Char = 58 OR Char = 92 THEN      'colon or backslash
       Path$ = LEFT$(UCASE$(Spec$), X)  'keep just what precedes the name
       EXIT FOR                         'bail out of the FOR/NEXT loop
    END IF
NEXT

FOR X = 1 TO Count                              'process all matching files
                                                'strip the trailing zero byte
    Array$(X) = LEFT$(Array$(X), INSTR(Array$(X), Zero$) - 1)
    PRINT "Reading "; Path$; Array$(X)          'show what's going on
    OPEN Path$ + Array$(X) FOR BINARY AS #1     'open the current file
    Length& = LOF(1)                            'get and save its length
    IF Length& < FindLength GOTO NextFile       'it can't possibly be there
    
    BufSize = BufMax%                           'assume a 4K text buffer
    IF BufSize > Length& THEN BufSize = Length& 'use the lesser size
    Buffer$ = SPACE$(BufSize)                   'create a file buffer

    LastSeek& = 1
    BaseAddr& = LastSeek&
    Bytes = 0

    DO                                          'this is the file read loop
       BaseAddr& = BaseAddr& + Bytes            'track the start of each block
       IF Length& - LastSeek& + 1 >= BufSize THEN
          Bytes = BufSize                       'at least BufSize bytes to go
       ELSE
          Bytes = Length& - LastSeek& + 1       'get just what remains
          Buffer$ = SPACE$(Bytes)               'adjust the buffer size down
       END IF

       SEEK #1, LastSeek&                       'seek to that part of the file
       GET #1, , Buffer$                        'read a chunk of the file

       Start = 1                                'this is the INSTR loop for
       DO                                       '  searching within the buffer
          Found = INSTR(Start, UCASE$(Buffer$), Find$)
          IF Found THEN                         'print it in context
             Start = Found + 1                  'to resume using INSTR later
             PRINT                              'add a blank line for clarity
             PRINT MID$(Buffer$, FNMax%(1, Found - 20), FindLength + 40)
             PRINT
            
             PRINT "Continue searching "; Array$(X); "? (Yes/No/Skip): ";
             WHILE INKEY$ <> "": WEND           'clear the keyboard buffer
             DO
                 KeyHit = FNIntUpper%(PDQInkey%)
             LOOP UNTIL KeyHit = 89 OR KeyHit = 78 OR KeyHit = 83   'Y/N/S
             PRINT CHR$(KeyHit)
             PRINT

             IF KeyHit = 78 THEN                '"No"
                END                             '  end the program
             ELSEIF KeyHit = 83 THEN            '"Skip"
                GOTO NextFile                   '  go on to the next file
             END IF

          END IF

       LOOP WHILE Found

       IF Bytes = BufSize THEN                  'still more file to examine
          BaseAddr& = BaseAddr& - FindLength    'back up a bit in case Find$
                                                '  straddles a buffer boundary
          LastSeek& = BaseAddr& + Bytes         'update the seek pointer
       END IF

    LOOP WHILE Bytes = BufSize AND BufSize = BufMax%  'still more to examine

NextFile:
    CLOSE #1
    Buffer$ = ""                                'clear the buffer for later
NEXT

