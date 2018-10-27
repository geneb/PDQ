'*********** NOBOOT.BAS - shows how to disable Ctrl-Alt-Del using a TSR

'Copyright (c) 1991 Ethan Winer

'Compile and link as follows:
'
' bc noboot /o;
' link /nod/noe/ex/far/packc noboot str00256 _noread _noerror _noval,,nul,pdq

'NOTE: This program does not trap Ctrl-Alt-Del when run under Windows 3.x.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType            'RegType is defined in PDQDECL.BAS
ID$ = "NOBOOT V1.0"                 'define the unique ID string
PRINT ID$                           'say hello

Registers.IntNum = 9                'specify trapping Interrupt 9
CALL PointIntHere(Registers)        'after this, every Int 9 will go to the
GOTO EndIt                          '  the next line below (CALL IntEntry1)
10                                  'this line number is needed for VB/DOS

CALL IntEntry1
CALL IntEntry2(Registers, Zero)

IF TestHotKey%(&HC53) THEN          '&HC = Ctrl-Alt, &H53 is the Del key
   CALL ResetKeyboard               'this is our key, so clear it out
   CALL ReturnFromInt(Registers)    'and return to the underlying application
ELSE
   CALL GotoOldInt(Registers)       'not our key, go on to the Int 9 handler
END IF

EndIt:
CALL EndTSR(ID$)                    'exit while staying resident

