'********** DISKUSED.BAS - utility determines file sizes and disk space used

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS

TYPE DTA                        'this is used by DOS find first/next service
     Reserved  AS STRING * 21   'reserved for use by DOS
     Attribute AS STRING * 1    'the file's attribute
     FileTime  AS STRING * 2    'the file's time
     FileDate  AS STRING * 2    'the file's date
     FileSize  AS LONG          'the file's size
     FileName  AS STRING * 13   'the file's name
END TYPE

DIM DTAData AS DTA              'this holds the file info for DOS as it works
DIM ThisName AS STRING * 13     'this holds each file's name
DIM ThisSize AS STRING * 8      'this holds each file's size
Q$ = CHR$(34)                   'make a quote once for speed/size below


'----- this is the main function, it processes each file
DEF FNMain%

    Registers.DX = VARPTR(DTAData)      'show DOS where the new DTA is located
    Registers.AX = &H1A00               'specify service 1Ah in AH
    Interrupt &H21, Registers           'DOS set DTA service

    Count = 0                           'zero out the file counter
    Spec$ = Spec$ + CHR$(0)             'make an ASCIIZ string for DOS
    Registers.DX = SADD(Spec$)          'show DOS where the file spec is
    Registers.CX = 39                   'attribute for any type of file
    Registers.AX = &H4E00               'find first matching name service

    DO
       Interrupt &H21, Registers                'see if there's a match
       IF Registers.Flags AND 1 THEN EXIT DO    'error if carry flag is set

       ThisName$ = DTAData.FileName             'copy name into a real string
       ThisName$ = LEFT$(ThisName$, INSTR(ThisName$, CHR$(0)) - 1) 'strip junk
       PRINT Path$; ThisName$;                  'print the name on the screen
       RSET ThisSize$ = STR$(DTAData.FileSize)  'right justify the size
       PRINT ThisSize$                          'and its size too

       Count = Count + 1                        'we found another one

       '---- accumulate the totals and calculate the file slack for each disk
       IF DTAData.FileSize THEN                 'ignore zero-length files
          TotalSize& = TotalSize& + DTAData.FileSize
          FileSlack = BytesPerCluster - (DTAData.FileSize MOD BytesPerCluster)
          TotalUsed& = TotalUsed& + DTAData.FileSize + FileSlack
          IF Dest THEN                             'do this only if needed
             DestSlack = DestBytes - (DTAData.FileSize MOD DestBytes)
             DestUsed& = DestUsed& + DTAData.FileSize + DestSlack
          END IF
       END IF

       Registers.AX = &H4F00                    'find next matching name
    LOOP

    FNMain% = Count                             'assign the function output

END DEF



'----- the main body of the program begins here
PRINT "DiskUsed - Copyright (c) 1989 Crescent Software"
PRINT

Spec$ = COMMAND$                        'see if they already entered a spec
IF LEN(Spec$) = 0 OR RIGHT$(Spec$, 1) = "\" OR RIGHT$(Spec$, 1) = ":" THEN
   Spec$ = Spec$ + "*.*"                'they didn't, so use *.*
END IF

X = INSTR(Spec$, " ")                   'see if there are two parameters
IF X THEN                               'yes, grab the next non-blank letter
   Dest = ASC(MID$(Spec$, X + 1))       'this had better be a drive letter!
   Spec$ = LEFT$(Spec$, X - 1)          'and keep only what precedes the drive

   IF Dest >= 97 AND Dest <= 122 THEN   '"capitalize" the character
      Dest = Dest - 32
   END IF

   Registers.AX = &H3600                'DOS Disk Free Space service
   Registers.DX = Dest - 64             'tell DOS which drive
   Interrupt &H21, Registers            'get the drive characteristics
   IF Registers.AX = -1 THEN            'if AX is -1 there was an error
      PRINT "Invalid destination drive"
      END
   END IF

   '----- calculate bytes per cluster, and available space on destination
   DestBytes = Registers.CX * Registers.AX
   DestAvail& = CLNG(DestBytes) * Registers.BX
END IF

FOR X = LEN(Spec$) TO 1 STEP -1         'isolate the drive/path if present
    Char = ASC(MID$(Spec$, X))          'get the current character
    IF Char = 58 OR Char = 92 THEN      'colon or backslash
       Path$ = LEFT$(UCASE$(Spec$), X)  'keep only what precedes the delimiter
       EXIT FOR                         'bail out of this FOR/NEXT loop
    END IF
NEXT

IF INSTR(Path$, ":") THEN               'if they specified a different drive
   Drive = ASC(Path$) - 64              'adjust the drive letter down to 1-n
END IF                                  'ELSE Drive is already 0 (use default)

Registers.AX = &H3600                   'DOS Disk Free Space service
Registers.DX = Drive                    'tell DOS which drive
Interrupt &H21, Registers               'go get 'em
IF Registers.AX = -1 THEN               'if AX is -1 there was an error
   PRINT "You can't do that!"
   END
END IF
BytesPerCluster = Registers.CX * Registers.AX   'calculate bytes per cluster

Count = FNMain%                         'count the files and remember sizes
IF Count = 0 THEN                       'none matched, so tell 'em and end
   PRINT "No matching files"
   END
END IF

PRINT
PRINT Count;                                            'print the number of
PRINT "file(s) found matching "; Q$; RTRIM$(Spec$); Q$  '  files found
PRINT "Total of all file sizes: "; TotalSize&   'print the sum of the sizes
PRINT "Total disk space in use: "; TotalUsed&   'print what's actually taken

TotalSlack& = (TotalUsed& - TotalSize&) * 100   'print the percentage slack
PRINT TotalSlack& \ TotalUsed&; "percent is wasted"

IF Dest THEN                                    'if they gave a destination
   PRINT
   PRINT DestUsed&; "bytes are needed on drive "; CHR$(Dest); ":"
   PRINT DestAvail&; "bytes are available"
   IF DestUsed& <= DestAvail& THEN
      PRINT "Enough";
   ELSE
      PRINT "Insufficient";
   END IF
   PRINT " space on destination disk"
END IF

