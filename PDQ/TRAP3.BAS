'********** TRAP3.BAS - shows how to trap three interrupts in one program

'Copyright (c) 1990 Ethan Winer


'We have been asked many times if P.D.Q. can trap more than one interrupt at
'a time, and of course the answer is yes!  However, there are a number of
'things that can go wrong if you are not careful.  Because neither BASIC nor
'any of the P.D.Q. extensions are "reentrant", it is imperative that your
'program does not use the same internal routines if a hardware interrupt may
'cause the same routine to be called again.  If you are currently servicing,
'say, timer interrupt 8 and using LEFT$, then another interrupt handler may
'not also use LEFT$ if there is any chance that this second handler will be
'invoked while the first is in progress.
'
'In the code below you will see that each interrupt handler checks the Busy
'status of the OTHER interrupt handlers.  Otherwise, if the portion of this
'program that handles Int 10h is in the middle of a call to PDQPrint and a
'timer interrupt 8 comes along, then the Int 8 handler will make another call
'to PDQPrint.  Crashola!
'
'In practice, there's not a whole lot you can do to prevent this problem
'other than testing the flags as shown here.  However, integer math and other
'statements that do not result in calls to the runtime library will be safe.
'
'BE SURE TO LINK THIS PROGRAM WITH THE _NOVAL.OBJ STUB FILE.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers8 AS RegType       'RegType is defined in PDQDECL.BAS
DIM Registers10 AS RegType
DIM Registers16 AS RegType

Registers8.IntNum = 8           'specify trapping the timer Interrupt 8
Registers10.IntNum = &H10       'specify trapping the video Interrupt 10h
Registers16.IntNum = &H16       'specify trapping the keyboard Interrupt 16h

ID$ = "This is a test of trapping three interrupts."
CLS
PDQPrint ID$, 1, 1, 15
PDQPrint "Hang on the Enter key to see it continue working", 2, 1, 15

PointIntHere Registers8         'trap the timer Interrupt 8 here
GOTO Install10                  'skip over to install the next handler
10                              'this line number is needed for VB/DOS

IntEntry1                       'this is the interrupt handling code
IntEntry2 Registers8, 0         'check the Int 10 and 16 busy status (below)
IF NOT (Registers10.BusyFlag OR Registers16.BusyFlag) THEN
   PDQPrint "Int 8 was here", 10, 1, 15    'not busy, so we can call PDQPrint
END IF
GotoOldInt Registers8           'continue on to the original Int 8

Install10:
PointIntHere Registers10        'trap the video interrupt 10h
GOTO Install16                  'skip over to install the next handler
20                              'this line number is needed for VB/DOS

IntEntry1                       'this is the interrupt handling code
IntEntry2 Registers10, 0        'as above
IF NOT (Registers8.BusyFlag OR Registers16.BusyFlag) THEN
   PDQPrint "Int 10 was here", 10, 30, 15
END IF
GotoOldInt Registers10

Install16:
PointIntHere Registers16        'trap the video interrupt 10h
GOTO EndIt                      'skip over to the rest of the program
30                              'this line number is needed for VB/DOS

IntEntry1                       'this is the interrupt handling code
IntEntry2 Registers16, 0        'as above
IF NOT (Registers8.BusyFlag OR Registers10.BusyFlag) THEN
   PDQPrint "Int 16 was here", 10, 60, 15
END IF
GotoOldInt Registers16

EndIt:
EndTSR ID$

