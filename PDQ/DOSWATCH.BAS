'********* DOSWATCH.BAS

'Copyright (c) 1989 Ethan Winer

'DOSWatch is a TSR program that displays information about the current DOS
'service number at the top of the screen everytime an INT 21H is executed.
'To minimize the amount of memory taken when this program is resident, you
'should link with the STR00512 and other object files as follows:
'
'  LINK /ex/noe/nod/far/packc doswatch +
'    str00512 _noval _noread _noerror, , nul, pdq
'
'THIS PROGRAM WILL NOT WORK WITHIN THE BASIC EDITOR.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Regs AS RegType             'RegType is defined in PDQDECL.BAS

ID$ = "DOSWatch Ver. 2.00"      'ID$ prevents multiple installs

DGroup = TSRInstalled%(ID$)             'see if we're already installed
IF INSTR(UCASE$(COMMAND$), "/U") THEN   'do they want to uninstall?
  IF DGroup THEN                        'are we already installed?
    Okay = UnhookInt%(Regs, DGroup)     'yes try to unhook and deinstall
    Okay = Okay OR DeinstallTSR%(DGroup, ID$)  'using OR saves both results
    IF NOT Okay THEN                    'deinstallation failed, so tell them
      PRINT "Unable to uninstall DOSWatch."
    END IF
  ELSE
    PRINT "DOSWatch is not resident, try again without /U."
  END IF
  END                                   'either way, end the program
ELSE
  IF DGroup THEN                        'already resident, they didn't use /U
    PRINT "DOSWatch is already installed."
    END
  END IF
END IF

Row = CSRLIN                            'print at the current cursor location
Column = POS(0)
CALL PDQPrint(ID$, Row, Column, 7)      'print the installation message

DIM Message AS STRING * 66
DIM DOSName AS STRING * 50

Zero$ = CHR$(0)                 'this is faster than using CHR$(0) repeatedly
Fifty = 50                      'this is faster to pass to BlockCopy
Row = 1                         'where to print the message details
Colr = 9                        'use bright blue on black for the message
                                '  (9 is bright underlined on mono systems)

Regs.IntNum = &H21              'Regs is a TYPE defined in PDQDECL.BAS
                                'specify trapping Int 21h
CALL PointIntHere(Regs)         'load Regs with what it needs, and pass
GOTO EndIt                      '  control to the next line at each Int. 21h
10                              'this line number is needed for VB/DOS


'----- the code below receives control with each Interrupt 21h

CALL IntEntry1                  'this is the first mandatory step
CALL IntEntry2(Regs, Zero)      'and this is the second one (Zero is known 0)

Ticks = 0                       'assume we won't pause to read the display
Service = Regs.AX \ 256         'get the current service number in AH

SELECT CASE Service             'print some useful information
   CASE &HE
      Message$ = "Set disk drive to " + CHR$(Regs.DX + 65)

   CASE &H2C
      Message$ = "Get the DOS time"

   CASE &H30
      Message$ = "Get DOS version"

   CASE &H36
      Message$ = "Get disk free space"

   CASE &H3B
      GOSUB GetDOSName                              'load DOSName$ from DS:DX
      Message$ = "Change directory to " + DOSName$

   CASE &H3C
      GOSUB GetDOSName
      Message$ = "Create file " + DOSName$

   CASE &H3D
      GOSUB GetDOSName
      Message$ = "Open file " + DOSName$

   CASE &H3E
      Message$ = "Close handle" + STR$(Regs.BX)

   CASE &H3F
      Message$ = "Read from handle" + STR$(Regs.BX)

   CASE &H40
      Message$ = "Write to handle" + STR$(Regs.BX)

   CASE &H41
      GOSUB GetDOSName
      Message$ = "Delete file " + DOSName$
  
   CASE &H47
      Message$ = "Get current directory"
  
   CASE &H4B
      GOSUB GetDOSName
      Message$ = "Exec program " + DOSName$
  
   CASE &H4E
      GOSUB GetDOSName
      Message$ = "Find first file that matches " + DOSName$

   CASE &H4F
      Message$ = "Find next matching file"
  
   CASE ELSE
      Message$ = ""

END SELECT

CALL PDQPrint("Service: " + HEX$(Service) + " " + Message$, Row, Row, Colr)
IF Ticks THEN CALL Pause(Ticks)

CALL GotoOldInt(Regs)           'continue on to the original Int 21h

GetDOSName:                     'load DOSName$ with name pointed to by DS:DX
   CALL BlockCopy(Regs.DS, Regs.DX, VARSEG(DOSName$), VARPTR(DOSName$), Fifty)
   Zero = INSTR(DOSName$, Zero$)           'find terminating zero byte
   DOSName$ = LEFT$(DOSName$, Zero - 1)    'blank out what remains
   Ticks = 8                               'pause 1/2 second for readability
   RETURN

EndIt:
   CALL EndTSR(ID$)                        'terminate and stay resident

