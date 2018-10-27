'********** WHEREIS.BAS - locates any file(s) matching a given specification

'Copyright (c) 1990 Ethan Winer


'IMPORTANT NOTE:
'
'This program makes use of some of the routines in our QuickPak Professional
'product.  Therefore, you must own QuickPak Professional to compile and link
'this program.
'
'Because this program is heavily recursive, you should link it using the
'linker /STACK: option set for 16K as follows:
'
'   BC WHEREIS /O;
'   LINK /NOE/NOD/PACKC/FAR/STACK:16384 +
'     WHEREIS _NOVAL _NOERROR _NOREAD , , NUL, PDQ PRO


DEFINT A-Z

DECLARE FUNCTION DCount% (DSpec$)
DECLARE FUNCTION FCount% (FSpec$)
DECLARE FUNCTION GetDir$ (Drive$)
DECLARE FUNCTION GetDrive% ()

DECLARE SUB CleanUp ()
DECLARE SUB Display ()
DECLARE SUB ReadDirT (Spec$, BYVAL Segment, BYVAL Address)
DECLARE SUB ReadFileI (BYVAL Address)
DECLARE SUB SetDrive (Drive$)

SaveDir$ = GetDir$(Drive$)              'save the current directory
SaveDrive = GetDrive%                   'and the current drive
Drive$ = CHR$(SaveDrive)                'assume we're using the default drive

Search$ = "*.*"                         'this matches any directory name
Spec$ = COMMAND$                        'see if they specified a file spec

IF INSTR(Spec$, ".") = 0 THEN           'if they gave only a first name
   Spec$ = Spec$ + ".*"                 '  append a wild card extension
END IF

IF LEN(Spec$) = 0 OR Spec$ = ".*" THEN  'if they didn't
   Spec$ = "*.*"                        '   use "*.*"
ELSEIF RIGHT$(Spec$, 1) = ":" THEN      'if they gave only a drive
   Spec$ = Spec$ + "*.*"                '   append "*.*" to that
   Drive$ = LEFT$(Spec$, 1)             '   and isolate the drive letter
ELSEIF INSTR(Spec$, ":") THEN           'a drive and path was specified
   Drive$ = LEFT$(Spec$, 1)             'isolate the drive letter
   Spec$ = MID$(Spec$, 3)               'and the file specification
END IF
 
IF INSTR(Spec$, "\") THEN               'they're not supposed to give a path
   PRINT "Do not specify a path -- this program searches all directories."
   END
END IF

SetDrive Drive$                         'select the appropriate disk drive
CHDIR "\"                               'start looking in the root directory
CALL Display                            'this baby does all the work

SetDrive CHR$(SaveDrive)                'restore the original drive
CHDIR SaveDir$                          'and then the original path
PRINT Total; "File(s) Found"            'print the total number of files found

SUB Display

    SHARED SaveDrive, Drive$, Spec$, Search$, Total, SaveDir$
    STATIC Null$                                'this saves a byte or two

    ThisDir$ = GetDir$(Null$)                   'save the current directory
    ThisDrv = GetDrive%                         'and the current drive

    FCnt = FCount(Spec$)                        'count the matching files
    IF FCnt THEN                                'if there are any to report
        Total = Total + FCnt                    'add to the accumulator
        DIM FArray$(FCnt)                       'dimension array accordingly

        FArray$(0) = Spec$                      'assign the spec string
        FOR X = 1 TO FCnt                       'pad each element
            FArray$(X) = SPACE$(37)             'ReadFileI needs 37 spaces
        NEXT
        ReadFileI VARPTR(FArray$(0))            'read the file names and info

        SetDrive CHR$(SaveDrive)                'restore original drive and
        CHDIR SaveDir$                          '  path if they press Ctrl-C

        PRINT Drive$; ":"; ThisDir$             'print the drive and path
        FOR X = 1 TO FCnt                       'for each file
            PRINT "  "; FArray$(X)              'tab in, print the file name
        NEXT
        PRINT                                   'add a blank lines
    END IF

    SetDrive CHR$(ThisDrv)                      'we're done printing, restore
    CHDIR ThisDir$                              '  the active drive and path
   
    DCnt = DCount(Search$)                      'count dirs under this one
    IF DCnt THEN                                'if there are any
       DIM DArray(DCnt) AS STRING * 12          'dimension array for dir names
       ReadDirT Search$, VARSEG(DArray$(0)), VARPTR(DArray$(0))    'read them
       Prefix$ = ThisDir$                       'assume we're not in the root
       IF ThisDir$ = "\" THEN Prefix$ = Null$   'if we are use a blank
       FOR X = 0 TO DCnt - 1                    'for each directory under us
           CHDIR Prefix$ + "\" + DArray$(X)     '  first change to it
           Display                              '  and then call ourselves
       NEXT                                     '  recursively again
    END IF

END SUB

