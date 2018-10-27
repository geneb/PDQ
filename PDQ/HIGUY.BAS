'********* HIGUY.BAS - the simplest TSR hot-key program possible

'Copyright (c) 1989 Ethan Winer

'This program may not be run within the QuickBASIC editing environment.
'BE SURE TO LINK WITH THE _NOVAL.OBJ STUB FILE!


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS

ID$ = "HiGuy installed - press ALT-H any time"  'define the unique ID string
Row = CSRLIN                                    'print at the current cursor
Column = POS(0)
PDQPrint ID$, Row, Column, 7                    'print the sign-on message
PRINT

Registers.IntNum = 9               'specify trapping Interrupt 9

CALL PointIntHere(Registers)       'after this, every Int 9 will go to the
GOTO EndIt                         '  the next line below (CALL IntEntry1)
10                                 'this line number is needed for VB/DOS

CALL IntEntry1
CALL IntEntry2(Registers, 0)

IF TestHotKey(&H823) THEN          '8 means Alt, 23 means "H"
   CALL ResetKeyboard              'this is our key, so clear it out
   PDQPrint "Hi Guy", 1, 75, 7     'print the silly little message
   CALL ReturnFromInt(Registers)   'and return to the underlying application
ELSE
   CALL GotoOldInt(Registers)      'not our key, pass on to the Int 9 handler
END IF

EndIt:
CALL EndTSR(ID$)                   'exit while staying resident

