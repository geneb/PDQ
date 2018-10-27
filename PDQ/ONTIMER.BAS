'********** ONTIMER.BAS - shows how to simulate BASIC's ON TIMER

'Copyright (c) 1989 Crescent Software

'This program will not work in the QuickBASIC editing environment, because
'the very concept of PointIntHere cannot work in the QB P-code interpreter.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS

Active = -1                     'set the active flag (see below)
Registers.IntNum = 8            'specify trapping hardware timer Interrupt 8

CLS
PDQPrint "This is a test of trapping the timer interrupt.", 1, 1, 15

PointIntHere Registers          'after this, every Int 8 will go to the
GOTO WaitLoop                   '  the next line below (CALL IntEntry1)
10                              'this line number is needed for VB/DOS

'----------------------------------------------------------------------------
' This portion of the program services the timer interrupt in real time.
'----------------------------------------------------------------------------
IntEntry1
IntEntry2 Registers, 2          '2 means start working immediately (non-TSR)
Tick = Tick + 1                 'work only every third tick
IF Tick = 3 THEN                'this is our tick!
   Tick = 0                     'reset it to zero for next time
   Evnt = Evnt + 1              'we're doing this entire mess 5 times
   PDQPrint "This is event number" + STR$(Evnt) + " of 25.", 3, 1, 9
   IF Evnt = 25 THEN Active = 0 'this gets us out of the WHILE loop below
END IF

GotoOldInt Registers            'continue to the original int handler

WaitLoop:
WHILE Active                    'sit in this loop most of the time
WEND
  
Flag = UnHookInt%(Registers, 0) 'you MUST unhook the interrupt before ending
IF NOT Flag THEN                'if SideKick is loaded this will happen
   PRINT "Unable to unhook the interrupt -- reboot now!"
   WHILE -1: WEND
END IF

LOCATE 4, 1                     'clean up the display

