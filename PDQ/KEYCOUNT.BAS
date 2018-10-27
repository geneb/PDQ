'******** KEYCOUNT.BAS

'Copyright (c) 1993 Ethan Winer

'KeyCount is a TSR program that counts keypresses, and that count can be read
'and reset from an underlying program.  The segment and address of the Count
'variable is written to a file when KeyCount begins, and subsequent programs
'can open that file to know where to PEEK and POKE Count to read and reset it
'respectively.  Note that the file is deleted when KeyCount is uninstalled,
'and it is assumed that your program will not have changed directories in the
'interim.  If a directory change is possible your program should have code to
'detect the current directory on startup, and specify that directory when it
'deletes the file.  A minimal test/demo program is presented in the comments
'at the end of this file.
'
'For the smallest resident memory usage compile and link KeyCount as follows:
'
'  BC KEYCOUNT /O;
'  LINK /NOD/NOE KEYCOUNT _NOVAL _NOREAD _NOERROR _KILL STR00256, , NUL, _
'    SMALLDOS PDQ;
'  EXE2COM KEYCOUNT

DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Regs AS RegType                    'RegType is defined in PDQDECL.BAS
Regs.IntNum = &H16                     'intercept the BIOS keyboard interrupt
ID$ = "KeyCount"                       'all TSR programs need an ID string
PRINT ID$                              'say hello

DGroup = TSRInstalled%(ID$)            'see if we're already loaded (hic)
IF INSTR(UCASE$(COMMAND$), "/U") THEN  'then see if they want to uninstall
  IF DGroup = 0 THEN                   'yes, but we're not resident!
    PRINT "KeyCount is not resident!"  'say so
  ELSEIF UnHookInt%(Regs, DGroup) THEN 'try to unhook the interrupt
    IF DeInstallTSR%(DGroup, ID$) THEN 'then try to remove the TSR
      KILL "KEYCOUNT.DAT"              'no directory is specified (see above)
      PRINT "KeyCount uninstalled."    'the uninstall went okay, say so
    ELSE                               'we couldn't uninstall
      PRINT "Can't uninstall KeyCount. System Unstable. Reboot."
    END IF
  ELSE                                 'we couldn't unhook the interrupt
    PRINT "Can't unhook interrupt 16h. Remove other TSRs and try again."
  END IF
  END                                  'no matter what, end the program
END IF

IF DGroup THEN                         'KeyCount is already resident and they
  PRINT "KeyCount is already installed."    '  are not trying to uninstall
  END
END IF

OPEN "KEYCOUNT.DAT" FOR OUTPUT AS #1   'write the segment/address of Count
  Temp = VARSEG(Count)                 '  which other programs can then read
  PUT #1, , Temp                       '  to be able to PEEK and POKE Count
  Temp = VARPTR(Count)
  PUT #1, , Temp
CLOSE #1

CALL PointIntHere(Regs)
GOTO EndIt
10                                     'this line number is needed for VB/DOS

CALL IntEntry1                         'mandatory interrupt handling code
CALL IntEntry2(Regs, Action)

Service = Regs.AX                      'save the service number now in AH
CALL CallOldInt(Regs)                  'then call the original Int handler

'---- (Service AND &HEF00) below tests if the service was either 0 or &H10,
'     which is either of the two ways a program can request keyboard input.
IF (Service AND &HEF00) = 0 THEN Count = Count + 1

CALL ReturnFromInt(Regs)               'return to the underlying program

EndIt:
CALL EndTSR(ID$)                       'exit while staying resident



'******* TESTKC.BAS - tests the KEYCOUNT.BAS program
'
'Copyright (c) 1993 Ethan Winer
'
'
'DEFINT A-Z
'OPEN "KEYCOUNT.DAT" FOR BINARY AS #1
'IF LOF(1) = 0 THEN                    'the file was not there
'  PRINT "KeyCount not resident.  Run KeyCount and try again"
'  END
'END IF
'GET #1, , Segment
'GET #1, , Address
'CLOSE #1
'
'Again:
'DEF SEG = Segment                     'clear the current key count
'POKE Address, 0                       'or you could use PDQPoke2
'POKE Address + 1, 0
'
'PRINT : PRINT : PRINT
'PRINT "Press some keys, and then press Escape to read the count."
'Escape$ = CHR$(27)
'DO: LOOP UNTIL INKEY$ = Escape$
'
'Count = PEEK(Address) + PEEK(Address + 1)  'or use PDQPeek2%()
'PRINT "You pressed"; Count; "keys (including Escape)"
'PRINT "Go again (Y/N)? ";
'DO
'  Ans$ = UCASE$(INKEY$)
'  IF Ans$ = "Y" GOTO Again
'  IF Ans$ = "N" THEN END
'LOOP

