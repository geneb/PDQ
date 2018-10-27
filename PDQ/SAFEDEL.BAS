'********* SAFEDEL.BAS - safe replacement for DEL verifies before deleting

'Copyright (c) 1992 Ethan Winer

'This program disables the DEL command, and replaces it with a "safe" version
'that confirms each file that is about to be deleted with a Yes/No prompt.
'SAFEDEL does not intercept the ERASE command, so you will have to add code
'to also check for ERASE if you want to be 100% safe.  But the real purpose
'of SAFEDEL is just to show how to disable or replace DOS commands.  (DOS 5
'provides the /P option for DEL for this same purpose, but SAFEDEL works in
'all cases and you don't have to remember to add /P.)
'
'This program taps into DOS's command control chain via the "back door" using
'multiplex interrupt &H2F.  Each time a DOS command is entered or read from a
'batch file, COMMAND.COM calls interrupt &H2F letting any TSR programs that
'have intercepted that interrupt see the command and optionally handle it.
'
'Interrupt &H2F is called two times: the first time with AX set to &HAE00 and
'the second with AX = &HAE01.  This program must capture the command and its
'arguments the first time, and also tell DOS it plans to handle the command
'by setting the AL register to &HFF.  (Since AL is not available separately
'we assign Regs.AX to &HAEFF which accomplishes the same result.)  Then, when
'interrupt &H2F is called again SAFEDEL actually handles deleting the files.
'It's important to make a copy of the command arguments on the first call,
'because DOS does not preserve the address in BX the second time (see below).
'
'DOS makes the name of the command and its arguments available by setting the
'registers to point to two data structures.  DS:SI points to the DOS command
'(only), and this command is preceded by a single length byte.  DS:BX points
'to a pair of length bytes, followed by the entire command that also includes
'the arguments.  This is shown below using DEL FILENAME.EXT as an example.
'
'   DS:SI --> CHR$(3) + "DEL"
'   DS:BX --> CHR$(128) + CHR$(16) + "DEL FILENAME.EXT"
'
'In my experiments the first length byte was always 128, which indicates the
'maximum length of the DOS command line buffer.  The second length byte holds
'the total length of the command including its arguments, which in this case
'is 16: LEN("DEL FILENAME.EXT").  If you want to experiment with SAFEDEL you
'can add calls to PDQPrint in various parts of the interrupt handler.  Since
'PDQPrint displays all characters including the special codes like CHR$(12),
'you can easily see what is pointed to by DS:SI and DS:BX this way.  You also
'should add surrounding brackets to the strings to see their exact length:
'
'   CALL PDQPrint("{" + Arg$ + "}", 1, 1, 15)
'
'In the code below the argument length is determined by peeking the second
'length byte pointed to by DS:BX, and subtracting the length of the command
'(4 including the CHR$(3) length count pointed to by DS:SI).  This works out
'because CmdLen includes the CHR$(3) length count, but when used to retrieve
'the argument it strips the space following the DEL command.
'
'Note that besides setting AL to &HFF to tell DOS we're handling the command,
'the length byte pointed to by DS:SI must also be zeroed out.  Otherwise, DOS
'would handle the command too.
'
'Unlike most manual interrupt handling TSR programs, when intercepting this
'multiplex interrupt service you are free to use any of the DOS services that
'are safe inside a simplified popup TSR.  In this program both DIR$ and PRINT
'are used, which normally would not be allowable within a manual interrupt
'handler.  Note that the DIR$ alias is used here, so it can be compiled with
'QuickBASIC 4.x instead of requiring BASIC 7 PDS.  If you do have PDS you can
'remove the two DIR$ DECLARE statements, and change DIR0$ and DIR1$ to DIR$.
'
'Note also that the technique shown here can be used to replace a DOS command
'with a new version as shown here, disable a command altogether, or even add
'your own entirely new commands.  This presents some very interesting and
'exciting possibilites.  As shown in the comments below, if you simply remove
'the code that handles the command (but still set AL to &HFF and also replace
'the command length with zero) you will disable a command altogether.
'
'You can also partially disable executable programs and batch files.  As an
'example, if the command you want to disable is FORMAT, then you can look for
'that in your interrupt &H2F handler.  Again, DOS calls interrupt &H2F every
'time it is about to execute any command or program.  However, if the user
'enters (or the batch file command is) \DOS\FORMAT, then you will not be able
'to detect this by examining the string pointed to by DS:SI because DOS does
'some preparatory parsing of the command before you get to see it.  Instead,
'you will have to look at what's pointed to by DS:BX and use INSTR to see if
'the word FORMAT is part of the command line.  To be fully safe you'd also
'have to make sure that the command is FORMAT, as opposed to a directory with
'that name: C:\FORMAT\QB
'
'This program was written using information contained in "Undocumented DOS"
'by Andrew Schulman et al. (Addison Wesley), starting on page 373.


'To minimize the amount of memory taken when this program is resident, you
'should compile and link follows:
'
'  BC safedel /o/s;
'  LINK /noe/nod/far/packc safedel str00512 _noval _noread _noerror,,nul,pdq;
'  EXE2COM safedel
'
'NOTE: THIS PROGRAM WILL NOT WORK WITHIN THE BASIC ENVIRONMENT.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DECLARE FUNCTION DIR0$ ALIAS "B$FDR0"   'REM these out if you use BASIC PDS
DECLARE FUNCTION DIR1$ ALIAS "B$FDR1" (Spec$) 'then change both below to DIR$

DIM Regs AS RegType                     'RegType is defined in PDQDECL.BAS
ID$ = "SAFEDEL Version 1.00"            'ID$ prevents multiple installs


'-- Remove the following code block through the outer END IF to disable being
'   able to uninstall SAFEDEL and save a few bytes of code while resident.
'
DGroup = TSRInstalled%(ID$)             'see if we're already installed
IF INSTR(UCASE$(COMMAND$), "/U") THEN   'do they want to uninstall?
  IF DGroup THEN                        'are we already installed?
    Okay = UnHookInt%(Regs, DGroup)     'yes try to unhook and deinstall
    Okay = Okay OR DeInstallTSR%(DGroup, ID$)  'using OR saves both results
    IF NOT Okay THEN                    'deinstallation failed, so tell them
      PRINT "Unable to uninstall SAFEDEL."
    END IF
  ELSE
    PRINT "SAFEDEL is not resident, try again without /U."
  END IF
  END                                   'either way, end the program
ELSE
  IF DGroup THEN                        'already resident, they didn't use /U
    PRINT "SAFEDEL is already installed."
    END
  END IF
END IF


'Print the sign-on message, and make sure DOS 3.3 or later is running.
'
PRINT ID$
IF DOSVer% < 330 THEN
  PRINT "Sorry, DOS 3.3 or later required."
  END
END IF


'---- Define the DOS internal command we're intercepting.  Here, DOS commands
'     are preceded by a length byte.  For example, to replace the DOS DATE
'     command you would use: Cmd$ = CHR$(4) + "DATE" because LEN("DATE") = 4.
'
Cmd$ = CHR$(3) + "DEL"          'command to look for preceded by its length
CmdLen = LEN(Cmd$)              'save the length
Tmp$ = SPACE$(CmdLen)           'this copy receives the current DOS command


'---- Specify trapping DOS Multiplex Interrupt &H2F
'
Regs.IntNum = &H2F
CALL PointIntHere(Regs)         'the standard interrupt handling setup
GOTO EndIt
10                              'this line number is needed for VB/DOS


'---- The code below receives control with each Interrupt &H2F.
'
CALL IntEntry1                  'this is the first mandatory step
CALL IntEntry2(Regs, Zero)      'and this is the second step (Zero = 0)

IF Regs.AX = &HAE00 THEN        'DOS checking for alternate command handler?
  CALL BlockCopy(Regs.DS, Regs.SI, VARSEG(Tmp$), SADD(Tmp$), CmdLen) 'get cmd
  IF Tmp$ = Cmd$ THEN           'is it our command?
    DEF SEG = Regs.DS           'yes, prepare to peek at the argument length
    ALen = PEEK(Regs.BX + 1) - CmdLen 'get length of arg (excluding command)
    IF ALen < 0 THEN ALen = 0   'trap negative length (happens if no arg)
    Arg$ = SPACE$(ALen)         'create Arg$ to hold it, then copy it to Arg$
    CALL BlockCopy(Regs.DS, Regs.BX + 6, VARSEG(Arg$), SADD(Arg$), ALen)
    '+6 above skips CHR$(128) + CHR$(CmdLen) + "DEL " to get the file name
    Regs.AX = &HAEFF            'set AL = &HFF so DOS knows we'll handle it
    CALL ReturnFromInt(Regs)    'return to caller (DOS in this case)
  END IF
ELSEIF Regs.AX = &HAE01 THEN    'is DOS now calling our alternate handler?
  DEF SEG = Regs.DS             'prepare to poke a new command length of 0
  POKE Regs.SI, 0               'clear cmd length so DOS won't handle it too

  '-- The following code handles our DEL replacement.  You may remove it or
  '   REM it out to merely disable DEL altogether.
  '
  NumFiles = 0                  'tracks how many files are deleted
  Arg$ = LTRIM$(Arg$)           'eat extra spaces between DEL and argument
  Path$ = ""                    'assume there's no drive letter or path

  FOR X = LEN(Arg$) TO 1 STEP -1            'extract drive/path if present
    ThisChar = MidChar%(Arg$, X)            'examine this character
    IF ThisChar = 58 OR ThisChar = 92 THEN  '":" or "\"
      Path$ = UCASE$(LEFT$(Arg$, X))        'isolate the drive/path
      EXIT FOR                              'UCASE$ is for cosmetics only
    END IF
  NEXT

  IF LEN(Arg$) THEN
    ThisFile$ = DIR1$(Arg$)     'get the first matching file name
  ELSE                          'IF/ELSE is needed to prevent DEL alone from
    ThisFile$ = ""              ' using the -previous- file specification or
  END IF                        ' defaulting to DEL *.* since DIR$("") is the
                                ' same as DIR$("*.*")

  IF LEN(ThisFile$) = 0 THEN PRINT "File not found"

  DO WHILE LEN(ThisFile$)
    PRINT Path$; ThisFile$; " - Okay to delete? (Yes/No/Quit) ";
    DO
      Ans = BIOSInkey%                          'see what they want to do
    LOOP UNTIL Ans
    PRINT CHR$(Ans)                             'print it on the screen
    IF Ans = 81 OR Ans = 113 THEN EXIT DO       'Q or q
    IF Ans = 89 OR Ans = 121 THEN               'Y or y
      KILL Path$ + ThisFile$                    'okay to kill the file
      NumFiles = NumFiles + 1                   'show we did one more
    END IF
    ThisFile$ = DIR0$                           'get next matching file name
  LOOP
  IF NumFiles THEN PRINT NumFiles; "file(s) deleted"
  CALL ReturnFromInt(Regs)
END IF

CALL GotoOldInt(Regs)           'not for us, continue on to the original
                                ' interrupt 2Fh handler

EndIt:
   CALL ReleaseEnv              'release the environment to save a few bytes
   CALL EndTSR(ID$)             'terminate and stay resident

