'************* MAKEPDQ.BAS - Compiler interface

'Copyright (c) Pierre Connolly 1990, 1991


DEFINT A-Z
'$INCLUDE: 'PDQDECL'

DECLARE SUB BLOP ()
DECLARE SUB QUIT ()

DECLARE FUNCTION BARRE (NBARRES, ITEM$(), POSIT)
DECLARE FUNCTION CHOOSE (NITEMS, ITEM$(), COL, POSIT, FLAG1)
DECLARE FUNCTION LDEXEC (FILENAME$, PARAMETER$)
DECLARE FUNCTION FINDPATH$ (FILENAME$)
DECLARE FUNCTION DIR$ ALIAS "B$FDR1" (FileSpec$)  'remove this for BASIC 7

DIM REGS AS REGTYPE             'We will need this when calling interrupts
DIM SHARED One: One = 1         'for less code when calling PDQPrint
DIM SHARED Seventy1: Seventy1 = 71  'ditto
DIM FILENAME$(20)               'Temp storage for dir lists
DIM ITEM$(10)
DIM SHARED SOUNDOK

'----- Initialize some variables
IF PDQMonitor < 3 THEN          'If we have a monochrome monitor,
   VIDSEG = &HB000              '  then video segment is B000h
   HLT = 112                    'Highlight for mono adapter
ELSE
   VIDSEG = &HB800              'Else it is B800h
   IF (PDQMonitor MOD 2) THEN
      HLT = 67                  'Highlight for color adapter with mono monitor
   ELSE
      HLT = 112                 'Highlight for color adapter with color monitor
   END IF
END IF

BUFSEG = AllocMem%(4000)        'Set aside 4K for video saves
CLEAR$ = STRING$(80, 32)        'We will use this to blank lines
POSIT = 1                       'Position on menu bar:start at left
WOPEN = 0                       'Windows open: 0 = false  -1 = true

NBARRES = 8                     'Number of items on menu bar
DIM BITEM$(NBARRES)             'Dim array to proper value
BITEM$(1) = " COMPILER "        'List each item with leading/trailing space
BITEM$(2) = " LINKER "
BITEM$(3) = " LIBRARY "
BITEM$(4) = " STUB "
BITEM$(5) = " STRING "
BITEM$(6) = " EDIT "
BITEM$(7) = " SETOPT "
BITEM$(8) = " COMPILE "


'------------------
'Reading config file.
'------------------

A$ = FINDPATH$("MAKEPDQ.CNF")   'Locate cnf file in system path
OPEN A$ FOR INPUT AS #1
SOUNDOK = 0                     'Default to nosound
GOSUB CONFIG
K = ASC(A$) AND 95              'Get ASCII code and get rid of lower case bit
IF K = 89 THEN SOUNDOK = -1     'Set soundok to true
GOSUB CONFIG                    'Get a line, keep data only
BCFIL$ = A$                     'Full path/filename of BC compiler
GOSUB CONFIG
LINKFIL$ = A$                   'Full path/filename of linker
GOSUB CONFIG
EDITFIL$ = A$                   'Full path/filename of text editor
GOSUB CONFIG
COMPRESFIL$ = A$                'Full path/filename of file compresser
GOSUB CONFIG
SOURCEPATH$ = A$                'Full path for source files
GOSUB CONFIG
ANCILDIR$ = A$                  'Directory of ancillary files
GOSUB CONFIG
NCOMP = PDQValI(A$)             'Number of options in "compiler" window
DIM COMPITEM$(NCOMP)            'Dim array to proper value
FOR I = 1 TO NCOMP              'Read in COMPILER WINDOW options block
    GOSUB CONFIG
    COMPITEM$(I) = A$
NEXT I
GOSUB CONFIG
NLINK = PDQValI(A$)             'Number of options in "linker" window
DIM LINKITEM$(NLINK)            'Dim array to proper value
FOR I = 1 TO NLINK              'Read in LINKER WINDOW options block
    GOSUB CONFIG
    LINKITEM$(I) = A$
NEXT I
CLOSE 1                         'End reading config file


'----------------------------------------------------
'Option names beginning with a check mark (û) are
'default options. Replace û with a space to deselect,
'or replace first space with a û to select.
'----------------------------------------------------

NLAST = 7                       'Number of options in "compile" window
DIM LASTITEM$(NLAST)            'Dim array to proper value
LASTITEM$(1) = "û COMPILE"      'List all options with leading "û " for
LASTITEM$(2) = "û LINK"         'options selected by default, or with
LASTITEM$(3) = "û EXE2COM"      'leading double space for options which
LASTITEM$(4) = "  REN to COM"   'are to be unselected by default
LASTITEM$(5) = "  COMPRESS"
LASTITEM$(6) = "  ANNOTATE"
LASTITEM$(7) = "  ABORT"        'Note: ABORT has highest priority when selected

'--------------- IMPORTANT:
'If you modify the default options above or the default options listed
'in the original config file, do not forget to reflect your changes in
'the appropriate string(s) below. Those strings list the options that are
'to be selected by default when starting the pgm.
'--------------------------

COMPOPT$ = " /o"                'List default compiler options here
LINKOPT$ = " /nod /noe /packcode /far /ex"  'List default linker opts here
LINKSTUB$ = " "                 'Default to no stub files
LINKLIB$ = " " + ANCILDIR$ + "PDQ"'assume the program must link with PDQ.LIB
LINKSTR$ = ""                   'Default to no string pool file


'------ GET SOURCE FILENAME FROM COMMAND LINE OR KEYBOARD

CLS
FIL$ = COMMAND$                     'see if they gave a file name
IF FIL$ = "" THEN                   'If none given, ask for one
   LINE INPUT "Filename to compile? ", FIL$
   IF FIL$ = "" THEN END
END IF
FIL$ = LTRIM$(UCASE$(FIL$))         'Strip out leading spaces, ucase only

K = INSTR(FIL$, ".")
IF K THEN                           'Strip out any extension
   FIL$ = LEFT$(FIL$, K - 1)
END IF
FILB$ = SOURCEPATH$ + FIL$ + ".BAS" 'This will be full path/fname of src. file

IF NOT PDQExist(FILB$) THEN         'Check if source file exists
    PRINT FILB$; " does not exist!" 'If not, ask if we have to ceate it
    PRINT "Create it (Y/N)? ";
    R$ = "YN"
    GOSUB GET1KEY
    IF R = 1 THEN                   'Create it if requested
        OPEN FILB$ FOR OUTPUT AS 1
        PRINT #1, "'"; FIL$; ".BAS" 'Print filename as rem
        PRINT #1, "DEFINT A-Z"      'Add usual statements
        PRINT #1, "'$INCLUDE: 'PDQDECL'"
        PRINT #1,
        CLOSE 1
        POSIT = 6                   'Force menu select to EDIT
    ELSE
        END                         'Job's over: quit now!
    END IF
END IF


'-------- GET STUBS, STRING AND LIBRARY FILENAMES

MASK$ = ANCILDIR$ + "STR*.OBJ"      'STR*.OBJ is the string pool file mask
GOSUB GETDIR                        'Get the list from active directory
NSTRING = COUNT + 1                 'Number of string pool files available
DIM STRINGITEM$(NSTRING)            'Dim array to proper value
STRINGITEM$(1) = "û DEFAULT"        'Initialize the first one (32K default)
FOR I = 1 TO COUNT
    STRINGITEM$(I + 1) = "  " + FILENAME$(I)'Add the others
NEXT I

MASK$ = ANCILDIR$ + "_*.OBJ"        '_*.OBJ is the stub file mask
GOSUB GETDIR                        'Get the list from active directory
NSTUB = COUNT                       'Number of available stub files
DIM STUBITEM$(NSTUB)                'Dim array to proper value
FOR I = 1 TO COUNT
    STUBITEM$(I) = "  " + FILENAME$(I)  'Build the list
NEXT I

MASK$ = ANCILDIR$ + "*.LIB"         '*.LIB is the library file mask
GOSUB GETDIR                        'Get the list from active directory
NLIB = COUNT                        'Number of library files
DIM LIBITEM$(NLIB)                  'Dim array to proper value
FOR I = 1 TO COUNT
    IF INSTR(FILENAME$(I), "PDQ.LIB") THEN  'PDQ.LIB HAS TO BE selected
        LIBITEM$(I) = "û " + FILENAME$(I)
    ELSE
        LIBITEM$(I) = "  " + FILENAME$(I)   'Others are unselected
    END IF
NEXT I


'------- Define some ancillary functions

'=== FNFILES will be used to extract the base filename for string pool,
'===         stub files and libraries from options listed in the windows
DEF FNFILE$ (A$)                'Strip file name
    IF ASC(A$) = 251 THEN       'If this filename is selected,
        K = INSTR(A$, ".")      ' locate end of base filename
        B$ = MID$(A$, 2, K - 2) ' and keep filename only
    ELSE                        'Otherwise
        B$ = ""                 ' return a blank string
    END IF
    FNFILE$ = B$
END DEF

'=== FNITEM will be used to extract the selected options names
'===        from option lists given in the windows
DEF FNITEM$ (A$)
    IF ASC(A$) = 251 THEN           'If this option is selected,
        K = INSTR(3, A$, " ")       'Locate first space after option name
        FNITEM$ = MID$(A$, 2, K - 2)' then extract option name
    ELSE                            'Otherwise
        FNITEM$ = ""                ' return a blank string
    END IF
END DEF


'-------- Prepare to execute main loop
'=== This prints the screen frame

COLOR 7, 1                      'Set foreground/background colors
CLS                             'This will clear to white chars on blue bkgnd
LineLen = (80 - (LEN(FILB$) + 20)) \ 2
A$ = STRING$(LineLen, 196) + "´ Working on file " + FILB$ + " Ã" + STRING$(LineLen, 196)
PDQPrint A$, 3, One, 23
PDQPrint CLEAR$, 4, One, 112    'Clear line #4 in reverse video
CURSOROFF                       'Turn cursor off


'-------- Main program loop begins
DO
    PDQPrint " P.D.Q. COMPILER FRONT END ", One, 26, Seventy1
    PDQPrint STRING$(80, 196), 5, One, 52

    FOR I = 6 TO 17             'Clear text lines to make room for new text
        PDQPrint CLEAR$, I, One, 23
    NEXT I
    LOCATE 6, 1
    PRINT "BC "; FIL$; " "; COMPOPT$; ";"    'Print COMPILER command line
    PRINT                                    'And then LINKER command line
    PRINT "LINK "; FIL$; LINKSTUB$; LINKSTR$; LINKOPT$; " , , nul ,"; LINKLIB$; ";"

    BLOCKCOPY VIDSEG, 0, BUFSEG, 0, 4000'Save video screen to buffer
    '-----------------------
    'The following line allows the user to select a menu bar option and
    'to open the corresponding window. On return, POSIT=item number selected
    '-----------------------
    POSIT = BARRE(NBARRES, BITEM$(), POSIT)
    SELECT CASE POSIT
        CASE 8                  'Compile menu option
            PRINT
            '-----------------------
            'The next line allows the user to select the options he wants
            'from the open window. On return, K=number of menu bar option
            'that was selected. This had to be so that user may move from one
            'window to another without closing the previously opened one.
            '-----------------------
            K = CHOOSE(NLAST, LASTITEM$(), 67, POSIT, 0)
            POSIT = K               'This is the new active menu bar option
            IF K <> 8 THEN GOTO KEEPLOOPING 'User has moved to another option
            IF ASC(LASTITEM$(NLAST)) = 251 GOTO PGMEXIT 'ABORT is selected
            '--------------------------
            'Menu bar option #8 is different from the others: each of its
            'window options has to be processed separately.
            'Each one is examined below.
            '--------------------------
            IF ASC(LASTITEM$(6)) = 251 THEN 'ANNOTATE option
                OPEN FILB$ FOR BINARY AS 1  'Open source file
                SEEK 1, LOF(1) + 1          'Move to end of file
                PRINT #1, "'This file was last compiled with:"  'Print info
                PRINT #1, "'BC "; FILB$; " "; COMPOPT$; ";"     'there.
                PRINT #1, "'LINK "; FIL$; "+"
                IF LEN(LINKSTUB$) > 1 THEN
                    PRINT #1, "'     "; LTRIM$(LINKSTUB$); "+"
                END IF
                IF LEN(LINKSTR$) > 1 THEN
                    PRINT #1, "'     "; LTRIM$(LINKSTR$); "+"
                END IF
                PRINT #1, "'     "; LTRIM$(LINKOPT$)
                PRINT #1, "'"
                PRINT #1, "'     nul"
                PRINT #1, "'     "; LTRIM$(LINKLIB$)
                CLOSE 1
            END IF

            IF ASC(LASTITEM$(1)) = 251 THEN     'COMPILE option
                '------------------
                'The next line executes the BC compiler with the active
                'options from the COMPILER window.
                'On return, K=exit code from compiler (if error signaled)
                '------------------
                K = LDEXEC(BCFIL$, FILB$ + " " + COMPOPT$ + ";")
                A$ = "Compiler"         'Signal that error was from compiler
                IF K THEN GOSUB COMPERR 'If there has been a BC error
            END IF

            IF ASC(LASTITEM$(2)) = 251 THEN     'LINKER option
                '---------------------
                'The linker often has too many options to be listed on a
                'single command line. So we have to build a response file
                '---------------------
                OPEN "J0B1M0.RSP" FOR OUTPUT AS 2   'Open response file
                PRINT #2, FIL$; "+"     'and print linker commands to that file
                IF LEN(LINKSTUB$) THEN              'Any stub files?
                    PRINT #2, LTRIM$(LINKSTUB$); "+"
                END IF
                IF LEN(LINKSTR$) THEN               'Any string pool file?
                    PRINT #2, LTRIM$(LINKSTR$); "+"
                END IF
                PRINT #2, LTRIM$(LINKOPT$)
                PRINT #2,
                PRINT #2, "nul"
                PRINT #2, LTRIM$(LINKLIB$)
                CLOSE 2
                '---------------------
                'The next line executes the linker with its response file
                'On return, K=exit code from LINK.EXE in case there was
                'a linker error.
                '---------------------
                K = LDEXEC(LINKFIL$, " @J0B1M0.RSP")
                KILL "J0B1M0.RSP"       'Delete the response file
                A$ = "Linker"           'Signal that the error is from linker
                IF K THEN GOSUB COMPERR 'If there was an error
                EXEC$ = FIL$ + ".EXE"   'Executable file is now *.EXE
                A$ = FIL$ + ".OBJ"      'OBJ file no more needed cuz there
                KILL A$                 'was no error: delete it!
            END IF

            IF ASC(LASTITEM$(3)) = 251 THEN 'EXE2COM option
                A$ = FINDPATH$("EXE2COM.COM")'Locate EXE2COM.COM in system path
                K = LDEXEC(A$, " " + FIL$)  'and execute it
                A$ = "EXE2COM"              'Signal error is from EXE2COM
                IF K THEN GOSUB COMPERR     'If there was an error
                EXEC$ = FIL$ + ".COM"       'Executable file is now *.COM
            END IF

            IF ASC(LASTITEM$(4)) = 251 THEN 'NAME TO COM option
                IF NOT PDQExist(FIL$ + ".EXE") THEN 'If *.EXE not there,
                    A$ = "RENAME"           'Signal error is from NAME TO COM
                    PRINT FIL$ + ".EXE not found"
                    GOSUB COMPERR           'Goto error handler
                END IF
                IF INSTR(EXEC$, ".COM") = 0 THEN 'Skip if allready renamed
                    B$ = FIL$ + ".COM"          'Build new filename
                    IF PDQExist(B$) THEN KILL B$    'Delete if exists
                    NAME EXEC$ AS B$            'Rename to .COM
                    EXEC$ = B$          'New executable file is *.COM
                 END IF
             END IF

            IF ASC(LASTITEM$(5)) = 251 THEN 'COMPRESS option
                '---------------------------
                'Different compression pgms require different command line
                'switches and/or arguments.
                'If you compression pgm requires some command line parameter
                ' (such as the registered version of PKLITE, you will need
                ' to edit the folloing line, such as:
                ' K = LDEXEC(COMPRESFIL$," -r "+EXEC$ for example
                '----------------------------
                K = LDEXEC(COMPRESFIL$, " " + EXEC$)
                '----------------------------
                'LZEXE renames original file to *.OLD
                'Other pgms may not do so. Edit or rem out the following
                '2 lines as needed by your compresser
                '----------------------------
                A$ = FIL$ + ".OLD"  'Prepare to delete *.OLD created by LZEXE
                KILL A$
             END IF
             GOTO PGMEXIT

        CASE 7                  'SETOPT option
            '----------------------- Info:
            'Down arrow is a shortcut key for SETOPT and EDIT options.
            'If down arrow is pressed while window is closed, it is
            'assumed you will execute the option without needing to first
            'open the window. If you find this confusing, you can
            'rewrite the following code to omit checking for WOPEN=true.
            'Operator will have to select YES and press ENTER to execute
            'this option.
            '------------------------
            IF WOPEN THEN           'If window allready open, then
               ITEM$(1) = "  YES"   'get confirmation from user
               ITEM$(2) = "  NO "
               K = CHOOSE(2, ITEM$(), 60, POSIT, -1)
               POSIT = K
               IF ASC(ITEM$(1)) <> 251 THEN GOTO KEEPLOOPING'User selects NO
            END IF
            F = FREEFILE                'Request free handle from DOS
            OPEN FILB$ FOR INPUT AS #F  'Open source file
            IF LOF(F) < 402 THEN
                GOTO NOANNOTATION       'File is too short
            END IF
            SEEK #F, LOF(F) - 400       'Position towards end of file
            A$ = INPUT$(401, F)         'Read in 401 last bytes
                                        'and look for annotation
            K = INSTR(A$, "'This file was last compiled with:")
            IF K = 0 THEN               'If annotation not found
NOANNOTATION:
                CLOSE #F                'Close file
                PRINT "No previous annotation available!"
                PRINT "Press SPACE to continue"
                R$ = " "
                GOSUB GET1KEY
                GOTO KEEPLOOPING        'Return to main loop
            END IF
            'Ok, we've got what we're looking for.
            'Maybe it's not the "last" annotation!
            I = K
            DO
                K = I                   'Remember previous pointer
                I = INSTR(I + 1, A$, "'This file was last compiled with:")
                IF I = 0 THEN EXIT DO   'That was the "last" one
            LOOP                        'Loop till we find the last one
            SEEK #F, LOF(F) - 401 + K   'Position to last annotation
            LINE INPUT #F, A$           'Skip over 1st line
            LINE INPUT #F, A$           'Read in "BC ..." line
            K = INSTR(5, A$, " ")       'Point past source filename
            A$ = MID$(A$, K)
            A$ = LTRIM$(A$)             'Strip off any leading spaces
            A$ = LEFT$(A$, LEN(A$) - 1) 'Get rid of trailing ";" char
            COMPOPT$ = " " + A$         'Add 1 leading space
            LINE INPUT #F, A$           'Skip over 1st "LINK ... " line
            LINKSTUB$ = ""              'Clear stub list
            LINKSTR$ = ""               'Clear string pool list
            LINKOPT$ = ""               'Clear linker options list
            DO
                LINE INPUT #F, A$           'This may be any of 4 things:
                                            '1. Stub files line
                                            '2. String pool file lines
                                            '3. Linker switches line
                                            '4. Empty line
                A$ = LTRIM$(MID$(A$, 2)) 'Skip over REM char and leading spaces
                IF LEN(A$) = 0 THEN
                    EXIT DO                 'This is last LINKER line
                ELSEIF INSTR(A$, "STR") THEN '"STR" means string pool file
                    IF MIDCHAR(A$, LEN(A$)) = 43 THEN 'Discard trailing "+"
                        A$ = LEFT$(A$, LEN(A$) - 1)
                    END IF
                    LINKSTR$ = " " + A$
                ELSEIF ASC(A$) = 47 THEN    '"/" means linker switches line
                    LINKOPT$ = " " + A$     'Must add leading space!
                ELSE                        'Stub files and others
                    IF MIDCHAR(A$, LEN(A$)) = 43 THEN 'Discard trailing "+"
                        A$ = LEFT$(A$, LEN(A$) - 1)
                    END IF
                    LINKSTUB$ = " " + A$
                END IF
            LOOP
            LINE INPUT #F, A$               'Skip over "nul" line
            LINE INPUT #F, A$               'Read in LIB list line
            LINKLIB$ = " " + LTRIM$(MID$(A$, 2))'Skip over REM and blank chars
            CLOSE #F
            FOR I = 1 TO NCOMP                  'Set COMPILER options
                K = INSTR(3, COMPITEM$(I), " ") 'Look for space delimiter
                A$ = MID$(COMPITEM$(I), 3, K - 3)'Extract option
                IF INSTR(COMPOPT$, A$) THEN     'Is it part of our COMPOPT$?
                    MID$(COMPITEM$(I), 1) = "û" 'Yes, add check mark
                ELSE
                    MID$(COMPITEM$(I), 1) = " " 'No, clear any check mark
                END IF
            NEXT I
            FOR I = 1 TO NLINK                  'Ditto for linker options
                K = INSTR(3, LINKITEM$(I), " ")
                A$ = MID$(LINKITEM$(I), 3, K - 3)
                IF INSTR(LINKOPT$, A$) THEN
                    MID$(LINKITEM$(I), 1) = "û"
                ELSE
                    MID$(LINKITEM$(I), 1) = " "
                END IF
            NEXT I
            FOR I = 1 TO NSTRING                   'Ancillary files are different:
                K = INSTR(3, STRINGITEM$(I), ".")  'Strip out file extension
                A$ = MID$(STRINGITEM$(I), 3, K - 3)'Rest is the same as previous
                IF INSTR(LINKSTR$, A$) THEN
                    MID$(STRINGITEM$(I), 1) = "û"
                ELSE
                    MID$(STRINGITEM$(I), 1) = " "
                END IF
            NEXT I
            FOR I = 1 TO NSTUB                  'Stub files
                K = INSTR(3, STUBITEM$(I), ".")
                A$ = MID$(STUBITEM$(I), 3, K - 3)
                IF INSTR(LINKSTUB$, A$) THEN
                    MID$(STUBITEM$(I), 1) = "û"
                ELSE
                    MID$(STUBITEM$(I), 1) = " "
                END IF
            NEXT I
            FOR I = 1 TO NLIB                   'Library files
                K = INSTR(3, LIBITEM$(I), ".")
                A$ = MID$(LIBITEM$(I), 3, K - 3)
                IF INSTR(LINKLIB$, A$) THEN
                    MID$(LIBITEM$(I), 1) = "û"
                ELSE
                    MID$(LIBITEM$(I), 1) = " "
                END IF
            NEXT I

        CASE 6                  'EDIT option
            '--------------------- Info:
            'See comments for option #7 above concerning the
            'Down Arrow shortcut key.
            '---------------------
            IF NOT WOPEN THEN   'Check if window allready open, and
                K = LDEXEC(EDITFIL$, " " + FILB$)'execute editor on source file
            ELSE                'If window not allready open, open it and
                ITEM$(1) = "  YES"  '  get confirmation from user
                ITEM$(2) = "  NO "
                K = CHOOSE(2, ITEM$(), 50, POSIT, -1)
                POSIT = K
                'If user has selected item #1 (YES) then execute editor
                IF ASC(ITEM$(1)) = 251 THEN
                   K = LDEXEC(EDITFIL$, " " + FILB$)
                END IF
            END IF
            CURSOROFF           'Shut off cursor again

        CASE 5                  'STRING POOL FILE option
            '----------------------------
            'The -1 option in the param list below signals that only ONE
            'item may be selected at once. Go and get selected item
            '----------------------------
            K = CHOOSE(NSTRING, STRINGITEM$(), 40, POSIT, -1)
            POSIT = K               'In case user selected another menu option
            LINKSTR$ = ""           'Clear old linker string pool list
            FOR I = 1 TO NSTRING    'Check each one and get selected one
                IF INSTR(STRINGITEM$(I), "û") THEN
                   LINKSTR$ = LINKSTR$ + " " + ANCILDIR$ + LTRIM$(FNFILE$(STRINGITEM$(I)))
                END IF
            NEXT I
            IF INSTR(LINKSTR$, "DEFAULT") THEN LINKSTR$ = ""'No file needed

        CASE 4                  'STUB FILES option
            '-----------------------------
            'The 0 option in the param list below signals that more than one
            'item may be selected at once. Go and get selected items
            '-----------------------------
            K = CHOOSE(NSTUB, STUBITEM$(), 30, POSIT, 0)
            POSIT = K               'In case user has selected another menu opt
            LINKSTUB$ = ""          'Clear old linker stub file list
            FOR I = 1 TO NSTUB      'Add selected stub file names to list
                IF INSTR(STUBITEM$(I), "û") THEN
                   LINKSTUB$ = LINKSTUB$ + " " + ANCILDIR$ + LTRIM$(FNFILE$(STUBITEM$(I)))
                END IF
            NEXT I

        CASE 3                  'LIBRARIES option
            '------------------------------
            'The 0 option in the param list below signals that more than one
            'item may be selected at once. Go and get selected items
            '------------------------------
            K = CHOOSE(NLIB, LIBITEM$(), 20, POSIT, 0)
            POSIT = K               'In case user has selected another menu opt
            LINKLIB$ = ""           'Clear old linker lib list
            FOR I = 1 TO NLIB       'Add selected lib file names to list.
                IF INSTR(LIBITEM$(I), "PDQ.LIB") = 0 AND INSTR(LIBITEM$(I), "û") THEN
                    LINKLIB$ = LINKLIB$ + " " + ANCILDIR$ + LTRIM$(FNFILE$(LIBITEM$(I)))
                END IF
            NEXT I
            LINKLIB$ = LINKLIB$ + " " + ANCILDIR$ + "PDQ" 'add PDQ to end

        CASE 2                  'LINKER option
            K = CHOOSE(NLINK, LINKITEM$(), 10, POSIT, 0) 'See above
            POSIT = K
            LINKOPT$ = ""         'Clear old linker options list
            FOR I = 1 TO NLINK    'Add selected linker options to list
                LINKOPT$ = LINKOPT$ + FNITEM$(LINKITEM$(I))
            NEXT I

        CASE 1                  'COMPILER options
            K = CHOOSE(NCOMP, COMPITEM$(), One, POSIT, 0)  'See above
            POSIT = K
            COMPOPT$ = " /o"    'Clear old compiler list to " /o"
            FOR I = 1 TO NCOMP  'and add selected compiler options to list
                COMPOPT$ = COMPOPT$ + FNITEM$(COMPITEM$(I))
            NEXT I

        END SELECT
       
KEEPLOOPING:
        IF POSIT < 1 THEN POSIT = NBARRES  'Wrap around on menu bar as needed
        IF POSIT > NBARRES THEN POSIT = 1  'Ditto above
        BLOCKCOPY BUFSEG, 0, VIDSEG, 0, 4000     'Restore video screen
LOOP                    'Main pgm loop ends here


PGMEXIT:                'Program exit point
CURSORON                'Turn cursor on before exit
END

COMPERR:                'There has been a compiler/linker error
PRINT
PRINT A$; " error."     'Print error source and ask user what to do next
PRINT "Return to compiler,  or  Abort (R/A)? ";
R$ = "RA"
GOSUB GET1KEY
IF R = 1 THEN           'Return to PDQ.COM
    WOPEN = -1          'User will likely want to edit. So flag window as open,
    POSIT = 6           'select menu bar option #6 (EDIT)
    RETURN KEEPLOOPING  'and keep looping inside main pgm loop
ELSE                    'Otherwise, get out
    RETURN PGMEXIT
END IF


GET1KEY:                'Get a key from kbd
'-----------------------------
'This sub waits for a single keypress from user.
'On entry:
'   Question printed to screen
'   Cursor located at correct position to print answer
'   R$= list of acceptable keypresses, UCASE only
'On exit:
'   User keypress converted to UCASE
'   User keypress printed with CR
'   R=position of user keypress within R$
'------------------------------
DO
    DO
        A$ = UCASE$(INKEY$) 'Check keyboard
    LOOP WHILE LEN(A$) = 0  'Loop till we get a key
    R = INSTR(R$, A$)       'Is it a good one?
LOOP UNTIL R                'Loop till we have a good keypress
PRINT A$                    'Print it
RETURN

GETDIR:         'Build a dir of MASK$
'-----------------------
'This sub builds a directory from MASK$ (may use DOS wildcards)
'On entry:
'   MASK$ = directory mask
'On exit:
'   FILENAME$() holds files that match MASK$
'   COUNT = number of matching files
'------------------------
COUNT = 0
A$ = DIR$(MASK$)
DO WHILE LEN(A$)
   IF A$ <> "DONOTUSE.LIB" THEN     'disallow DONOTUSE.LIB
     COUNT = COUNT + 1
     FILENAME$(COUNT) = A$
   END IF
   A$ = DIR$("")
LOOP
RETURN


CONFIG:         'Read one valid config file line
'-----------------------------
'This sub reads the config file up to the next non-comment line
'It returns that part of the line following the "=" if it is present, or
'the whole line if no "=" char is found
'-----------------------------
DO
    LINE INPUT #1, A$
LOOP WHILE ASC(A$) = 39             'Skip over comment lines
K = INSTR(A$, "=")
IF K THEN
   A$ = LTRIM$(MID$(A$, K + 1))     'Strip out what's left after "="
END IF
RETURN

'This file was last compiled with:
'BC C:\PDQ\SRC\MAKEPDQ.BAS  /o /s;
'LINK MAKEPDQ+
'     _KILL _LOCATE _NOERROR _NOREAD _NOVAL _PDQVAL+
'     /ex /nod /noe /packcode /far
'
'     nul
'     PDQ

FUNCTION BARRE (NBARRES, ITEM$(), POSIT)
'-----------------------------
'This is one of the two major functions of this pgm. It allows user to
'select a menu bar option. If a window is open, we exit this function
'after reprinting the new menu bar.
'POSIT = number (left to right) of currently selected menu bar option
'WOPEN = flags window open (0 = false, -1 = true)
'On return, BARRE = number of currently selected menu bar option
'There are three ways of exiting this function:
' ENTER returns to caller
' ESC gives user a chance of quitting the program
' Down Arrow returns to caller as short cut for certain options
'------------------------------
SHARED WOPEN                                'Get flag from main module
DO
    FOR I = 1 TO NBARRES                    'Start by printing all options
        PDQPrint ITEM$(I), 4, (I - 1) * 10 + 1, 112'in reverse video on menu bar
    NEXT I
    K = 10 * (POSIT - 1) + 1                'Compute position of selected opt
    PDQPrint ITEM$(POSIT), 4, K, Seventy1   'Highlight selected option
    IF WOPEN THEN EXIT DO                   'If window open, get out
    DO                                      'Wait for keypress
        K = BIOSInkey
    LOOP UNTIL K
    SELECT CASE K                           'Process keypress
        CASE 27                             'ESC key gets us out
            QUIT
        CASE -80                            'Dwn arrow gets out of function
            EXIT DO                         'Exit without opening window
        CASE 13                             'ENTER key
            WOPEN = -1                      'Open window
            EXIT DO                         'Exit function
        CASE -77                            'Right arrow
            POSIT = POSIT + 1               'Move to next menu bar option
        CASE -75                            'Left arrow
            POSIT = POSIT - 1               'Move to previous menu bar opt
        CASE ELSE                           'Any other key is not acceptable
            BLOP                            '"bad" sound
    END SELECT
    IF POSIT < 1 THEN POSIT = NBARRES       'Wrap around menu bar if needed
    IF POSIT > NBARRES THEN POSIT = 1       'Ditto above
LOOP                                        'End of main loop
BARRE = POSIT                               'Return val of selected option
END FUNCTION

SUB BLOP                'Signals any undefined keypress: "bad" sound
  IF SOUNDOK THEN
    CALL PDQSound(800, One)
    CALL PDQSound(1200, One)
    CALL PDQSound(400, One)
  END IF
END SUB

FUNCTION CHOOSE (NITEMS, ITEM$(), COL, POSIT, FLAG1)
'----------------------------
'This is the second major function of this pgm. It allows user to open a
'closed window, to select items in an open window or to select a different
'menu bar option.
'FLAG1 when true tells CHOOSE that one and only one option may be selected
'      at any given time so that selecting a new item means that CHOSSE has
'      to deselect any previously selected item. If FLAG1 is false, then
'      any number of items may be selected.
'On return, CHOOSE = number of selected menu bar option
'-----------------------------
SHARED WOPEN            'Get window open flag from other module
SHARED HLT              'Get highlight color from main module
WOPEN = -1              'Force open window

'We need to know the max length of the longest item in ITEM$()
'Minimum is forced to 10 if all items are shorter
L = 0                   'Start with a length of 0

FOR I = 1 TO NITEMS     'Check all items and keep max length
    IF LEN(ITEM$(I)) > L THEN L = LEN(ITEM$(I))     'Keep longest ITEM$
NEXT I
IF L < 10 THEN L = 10   'Force at least 10 as max length


A$ = "POINT"                    'Set A$ according to FLAG1
IF FLAG1 THEN A$ = "CHOOSE ONE"
A$ = LEFT$(A$ + STRING$(L, 32), L)  ' and build top of window
PDQPrint "´" + A$ + "Ã", 5, COL, 52
PDQPrint "Ã" + STRING$(L, 196) + "´", 6, COL, 52
PT = 1                          'PT=pointer to highlighted item- Start with #1

FIRST = 1                       'First window item
LAST = NITEMS                   'Last window item
IF LAST > 16 THEN LAST = 16     'Put no more than 16 items in 1 window

DO                   'MAIN LOOP
    FOR I = FIRST TO LAST                               'Print each window item
        A$ = LEFT$(ITEM$(I) + STRING$(L, 32), L)        'and complete window
        IF PT = I THEN                                  'Don't forget to print
            PDQPrint "³" + A$ + "³", 7 + I - FIRST, COL, 52'selected item in
            PDQPrint A$, 7 + I - FIRST, COL + One, HLT  'highlight color
        ELSE
            PDQPrint "³" + A$ + "³", 7 + I - FIRST, COL, 52'other items normal
        END IF
    NEXT I
    PDQPrint "À" + STRING$(L, 196) + "Ù", 7 + I - FIRST, COL, 52'Print bottom line

    DO                          'Get a keypress and process it
        DO
            K = BIOSInkey       'Wait for a key
        LOOP UNTIL K
        SELECT CASE K
            CASE 27             'ESC key gets us out of pgm
                QUIT
            CASE -79                        'End key
                LAST = NITEMS               'LAST=end of item list
                FIRST = LAST - 15           'Adjust FIRST pointer
                IF FIRST < 1 THEN FIRST = 1
                PT = LAST                   'Highlight LAST
                EXIT DO
            CASE -71                        'Home key
                FIRST = 1                   'FIRST=start of list
                PT = FIRST                  'Highlight FIRST item
                LAST = FIRST + 15           'Adjust LAST pointer
                IF LAST > NITEMS THEN LAST = NITEMS
                EXIT DO
            CASE -80                        'Down arrow
                PT = PT + 1                 'Point to next item
                IF PT > LAST THEN           'Past last window item?
                    IF LAST < NITEMS THEN   'More items in the list?
                        LAST = PT           'New last = PT
                        FIRST = LAST - 15   'Adjust first item
                        IF FIRST < 1 THEN FIRST = One   'Can't be < 1!
                    ELSE                    'No more items in list, so
                        PT = 1              'Wrap around to 1st item
                        FIRST = 1           'Adjust window pointers
                        LAST = NITEMS
                        IF LAST > 16 THEN LAST = 16
                    END IF
                END IF
                EXIT DO         'quit this loop and go to "get keypress" loop
            CASE -72            'Up arrow
                PT = PT - 1     'Select previous item
                IF PT < FIRST THEN          'Below 1st window item?
                    IF FIRST > 1 THEN       'Fist window item>1st list item?
                        FIRST = PT          'New First window item
                        LAST = FIRST + 15   'Adjust Last item
                        IF LAST > NITEMS THEN LAST = NITEMR
                    ELSE                    'First = 1st list item
                        PT = NITEMS         'Wrap around to end of list
                        LAST = NITEMS       'Adjust window pointers
                        FIRST = NITEMS - 15
                        IF FIRST < 1 THEN FIRST = 1
                    END IF

                END IF
                EXIT DO             'Return to "get keypress" loop
            CASE -77                'Right arrow
                POSIT = POSIT + 1   'Select next menu bar option
                CHOOSE = POSIT      'New selected item no
                EXIT FUNCTION       'Return to main module
            CASE -75                'Left arrow
                POSIT = POSIT - 1   'Select previous menu bar option
                CHOOSE = POSIT      'New selected item no
                EXIT FUNCTION       'Return to main module
            CASE 13                 'ENTER
                WOPEN = 0           'Close window
                CHOOSE = POSIT      'New selected item no
                EXIT FUNCTION       'Return to main module
            CASE 32                 'SPACE BAR = select item
                IF FLAG1 THEN       'If only one selected item allowed
                    K = -1          'Suppose item is selected
                    IF ASC(ITEM$(PT)) = 251 THEN K = 0 'Reset flag if not so
                    FOR I = 1 TO NITEMS                'Deselect all items
                        MID$(ITEM$(I), 1, 1) = " "     'by forcing blank in col 1
                    NEXT I
                    IF K THEN MID$(ITEM$(PT), 1, 1) = "û" 'Reselect
                                                        'highligthed item
                ELSE                'More than 1 selected item allowed
                    IF ASC(ITEM$(PT)) = 251 THEN        'If already selected,
                        MID$(ITEM$(PT), 1, 1) = " "     ' then deselect it
                    ELSE                                'Otherwise,
                        MID$(ITEM$(PT), 1, 1) = "û"     'select this item
                    END IF
                END IF
                IF SOUNDOK THEN             'If user has set sound to "ON",
                    CALL PDQSound(400, One) 'Audible tone to signal all is ok
                    CALL PDQSound(200, One)
                END IF
                EXIT DO                 'Goto get keypress loop
            CASE ELSE                   'Keypress is not valid
                BLOP                    '"bad" sound
        END SELECT
    LOOP
LOOP
END FUNCTION

'--------------------------
'This functions locates the file
'FIL$ in your system Path.
'Function returns complete path
'to specified filename if found
'This is a must if you want to use
'the LDEXEC function, since LDEXEC
'needs the complete path name to
'the pgm file it has to execute.
'--------------------------
FUNCTION FINDPATH$ (FIL$) STATIC
A$ = ENVIRON$("PATH")
CALL PDQRESTORE                     'Reset parser pointer
CALL SETDELIMITCHAR(59)             'Ensure correct delimiter
PATH$ = "."                         'First search active dir
DO WHILE LEN(PATH$)
    PATH$ = PATH$ + "\" + FIL$      'Fill in filename
    IF PDQExist(PATH$) THEN EXIT DO 'If found here
    PATH$ = PDQParse(A$)            'Check with next path
LOOP
FINDPATH$ = PATH$
END FUNCTION

'-----------------------------------
'This one is handy. It allows to load and
'execute FILENAME$ with command line given
'in PARAMETER$. Pgm name in FILENAME$ must
'contain full path and extension.
'The function returns the exit code (if
'any) generated by the executed pgm.
'It is a bit faster than shelling to DOS,
'uses a little less memory and gives you
'access to the subordinate pgm exit code.
'-----------------------------------
FUNCTION LDEXEC (FILENAME$, PARAMETER$)
DIM REGS AS REGTYPE
REGS.AX = &H4B00                        'Function 4Bh
FILENAME$ = FILENAME$ + CHR$(0)         'Transform to ASCIIZ string
K = LEN(PARAMETER$)                     'Get length of command string
PARAMETER$ = CHR$(K) + PARAMETER$ + CHR$(13)'Prepare parameter string for processing
C$ = CHR$(0) + CHR$(0) + "            " 'This is the parm block for this int
K1 = VARSEG(PARAMETER$)                 'Get segment of parm string
K2 = SADD(PARAMETER$)                   'Get offset of parm string
DEF SEG = VARSEG(C$)                    'Set seg of parm block
K = SADD(C$)                            'Get offset of parm block
PDQPOKE2 K + 2, K2                      'Put offset into parm block, bytes 3/4
PDQPOKE2 K + 4, K1                      'Put segment into parm block, bytes 5/6
DEF SEG                                 'Restore basic segment

REGS.DX = SADD(FILENAME$)               'Offset of pgm name into DX
REGS.ES = VARSEG(C$)                    'Segment of parm block into ES
REGS.BX = SADD(C$)                      'Offset of parm block into BX
REGS.DS = -1                            'Set DS to Basic segment
INTERRUPT &H21, REGS                    'Execute pgm as subordinate process

'Retreive subordinate process exit code
REGS.AX = &H4D00                        'Function 4Dh
INTERRUPT &H21, REGS
LDEXEC = REGS.AX                        'Set function value to exit code
END FUNCTION

SUB QUIT                    'Pressing the ESC key brings you here
'------------------------------
'This is the common exit routine called from within BARRE and CHOOSE
'It gives user a chance of regretting his keypress!
'------------------------------
SHARED CLEAR$               'Get CLEAR$ from main module
PDQPrint "É" + STRING$(30, 205) + "»", 20, 25, Seventy1 'make Confirm window
A$ = "º" + STRING$(30, 32) + "º"
PDQPrint A$, 21, 25, Seventy1
PDQPrint "º  Do you wish to quit (Y/N)?  º", 22, 25, Seventy1
PDQPrint A$, 23, 25, Seventy1
PDQPrint "È" + STRING$(30, 205) + "¼", 24, 25, Seventy1
DO                          'Wait for user answer
    DO
        A$ = UCASE$(INKEY$) 'Convert any keypress to Ucase
    LOOP UNTIL LEN(A$)
IF A$ = "N" THEN            'If user will not quit, exit this loop
    EXIT DO
ELSEIF A$ = "Y" THEN        'If he wishes to quit, then
    CURSORON                'Turn on cursor
    LOCATE 24, 1            'and locate it at bottom of screen
    END                     'Now, get out!
END IF
LOOP                        'Keep looping until valid keystroke
FOR I = 20 TO 24            'Clear our window in order to return to caller
    CALL PDQPrint(CLEAR$, I, One, 23)
NEXT I
END SUB                     'All ok, keep going buddy

