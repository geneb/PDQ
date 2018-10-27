'********** CLOCK.BAS - perpetual time display program

'Copyright (c) 1989 Ethan Winer


'To minimize the amount of code that is executed each time TIME$ is displayed
'on the screen, several tricks are used in this program.  Whenever a quoted
'string constant or internal BASIC function (such as TIME$) is used as an
'argument to a called routine, BASIC makes a copy of the string.  This not
'only adds extra code, but it also takes a fair amount of time.  Therefore,
'TIME$ has been declared as an integer function (using ALIAS to allow the
'otherwise illegal name B$FTIM to be used), which tells QB not to make a copy
'before sending it to PDQPrint.
'
'To make this trick work, BYVAL is needed to pass the value of the descriptor
'address that TIME$ returns as an integer function.  When passed to PDQPrint,
'the address is handled correctly, and BASIC is none the wiser.
'
'The other trick is to completely avoid any string assignments, to eliminate
'the inclusion of the string memory managing routines.  By experimentation
'using CodeView it was determined that the string constant stored as a DATA
'statement resides at address &H43.  Therefore, that address (and the length
'of &H20) is stored in a phony string descriptor (Descriptor&), which is then
'passed to PDQPrint and EndTSR.
'
'To eliminate the code necessary for VAL and READ (the code to read data also
'brings in the string heap management routines) and to create the smallest
'program possible, compile and link as follows and then use EXE2COM:
'
'  bc clock /o;
'  link /nod/noe/packc/far/stack:300 clock _noval _noread , , nul, pdq ;


DEFINT A-Z
DECLARE FUNCTION BTime% ALIAS "B$FTIM" ()

TYPE RegType                    'We can't include PDQDECL.BAS because of the
     AX        AS INTEGER       '  non-standard way some of these routines
     BX        AS INTEGER       '  are being called.
     CX        AS INTEGER
     DX        AS INTEGER
     BP        AS INTEGER
     SI        AS INTEGER
     DI        AS INTEGER
     Flags     AS INTEGER
     DS        AS INTEGER
     ES        AS INTEGER
     SS        AS INTEGER
     SP        AS INTEGER
     BusyFlag  AS INTEGER
     Address   AS INTEGER
     Segment   AS INTEGER
     ProcAdr   AS INTEGER
     ProcSeg   AS INTEGER
     IntNum    AS INTEGER
END TYPE
DIM Registers AS RegType

DATA Clock 1.10                                 'allocate this string
Descriptor& = &H43000A                          '&H43 is the DATA address

CALL PDQPrint(Descriptor&, CSRLIN, POS(0), 7)   'use this to show a message
'CALL PDQPrint(Zero, Zero, Zero, Zero)          'or use this to initialize
                                                '  PDQPrint and save 80 bytes
Row = 1                             'using variables for the PDQPrint values
Column = 73                         '  saves a few microseconds and a few
Colr = 9                            '  bytes compared to using constants

Registers.IntNum = 8                'specify trapping Timer Interrupt 8
CALL PointIntHere(Registers)        'after this, every Int 8 will go to the
GOTO EndIt                          '  the next line below
10                                  'this line number is needed for VB/DOS

'----- this code gets executed with each timer tick (18.2 times per second)
CALL IntEntry1
CALL IntEntry2(Registers, Zero)

CALL CallOldInt(Registers)          'service the int. before anything else

Tick = Tick + 1                     'work only once per second
IF Tick < 18 GOTO Skip              'not our tick, skip ahead
Tick = 0                            'reset it to zero for next time
CALL PDQPrint(BYVAL BTime%, Row, Column, Colr)  'display the time

Skip:
CALL ReturnFromInt(Registers)       'return to the underlying application

EndIt:
CALL ReleaseEnv                     'release this program's environment
CALL EndTSR(Descriptor&)            'exit while staying resident

