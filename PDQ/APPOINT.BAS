'********** APPOINT.BAS - TSR Appointment reminder
'
'Copyright (c) 1990 Don Malin & Crescent Software
'
'This program demonstrates trapping both a hot key and the timer interrupt
'in a P.D.Q. TSR using the simplified PopRequest method.
'
'To take as little DOS memory as possible when this program is installed as
'a TSR, you should link it with the STR00512.OBJ and other "stub" files:
'
'Compile and link as follows:
'
' bc appoint /s/o;
' link /nod/noe/ex/far/packc +
'   appoint str00512 _noread _noval _locate,, nul, smalldos pdq;
' exe2com appoint
'
'To install this program as a TSR enter APPOINT from DOS.  To enter an
'appointment time and message press Ctrl-A to activate the TSR.  Once
'activated the program will prompt you for the time and message.  When the
'program detects that it is at or past the appointment time it will pop up
'and display the message along with a series of tones to alert you.  You
'can then press any key to clear the message and return to the underlying
'application.
'----------------------------------------------------------------------------

DEFINT A-Z                          'Always use integers

'$INCLUDE: 'PDQDECL.BAS'            'Holds Declares and defines RegType

DECLARE SUB DisplayMessage (Message$)
DECLARE SUB GetMessage (Message$, AppointTime$)

CONST MessageLine = 1               'The line at which to display the message
CONST ScrAddr = (MessageLine - 1) * 160

ID$ = "Press Ctrl-A to enter an appointment"    'All TSR programs need an ID
IF TSRInstalled%(ID$) THEN END      'Make sure we're not already installed

DIM Registers AS RegType            'Create the TYPE for interrupt services

DIM SHARED ScrBuf$                  'This holds the background screen
ScrBuf$ = STRING$(160, 0)           '  when we pop up

DIM SHARED Colr                     'This is the edit/display color
Colr = 112                          '112 = black on white (inverse)

DIM SHARED OneSixty                 'This saves a bit of code later
OneSixty = 160

DIM SHARED ScrSeg                   'This holds the screen segment
DEF SEG = 0                         'See what type of monitor is installed
IF PEEK(&H463) <> &HB4 THEN         'Color monitor
   ScrSeg = &HB800                  'Use the color segment
   CursorBot = 7                    'Cursor's bottom scan line is 7
ELSE
   ScrSeg = &HB000                  'Use monochrome segment
   CursorBot = 15                   'Cursor's bottom scan line is 15
END IF

Message$ = STRING$(40, 32)          'This will hold the appointment message

PRINT "Appointment Reminder (c) 1990 Crescent Software, Inc."
PRINT ID$


'----- Timer Interrupt 8 handler
Registers.IntNum = 8                'Specify timer interrupt 8
'TimerFlag = 0                      'No action yet (shown for clarity only)

CALL PointIntHere(Registers)        'Trap the interrupt
GOTO PopUp                          'Skip past the Int 8 handler to PopUpHere
10                                  'this line number is needed for VB/DOS

  CALL IntEntry1                    'This code is executed at each timer tick
  CALL IntEntry2(Registers, Action) 'These are the two mandatory steps
  CALL CallOldInt(Registers)        'Always defer to the original handler

  Ticks = Ticks + 1                 'Another 1/18th second has passed
  IF Ticks >= 1092 THEN             'But has one minute passed yet?
    IF TrapTime THEN                'Is it okay to trap the time?
      IF TIME$ >= AppointTime$ THEN 'Time to pop up our message?
        IF PopRequest(TimerFlag, 18) THEN 'Yes, try it for one second
          Ticks = 0                 'The request was accepted so start a new
        END IF                      '  one-minute period
      END IF
    END IF
  END IF

CALL ReturnFromInt(Registers)       'All done with this timer tick


'----- Simplified popup handler
PopUp:
CALL PopUpHere(&H41E, ID$)          '&H41E = Ctrl-A
GOTO EndIt                          'Skip over the simplified handler and end
20                                  'this line number is needed for VB/DOS

'----------------------------------------------------------------------------
'Global interupt handling code follows.  Control comes here whenever the hot
'key is pressed or the appointment time has been exceeded.
'----------------------------------------------------------------------------
  CALL BreakOff                     'Disable Ctrl-Break
  SaveCsr& = CursorSave&            'Save the current cursor location

  IF TimerFlag = 0 THEN             'If TimerFlag is 0 the hot key got us here
    CALL GetMessage(Message$, AppointTime$)  'Input new time and message
    TrapTime = -1                   'Set flag to start checking the time below
  ELSE                              'We got here via the timer interrupt
    CALL DisplayMessage(Message$)   'Display the message and beep
    TimerFlag = 0                   'Clear this so we won't think the timer
                                    '  did it next time they hit Ctrl-A
    TrapTime = 0                    'The time came due and we don't have to
  END IF                            '  continue trapping the time

  CALL CursorRest(SaveCsr&)         'Restore the cursor location/size
  CALL BreakOn                      'Reenable Ctrl-Break
   
CALL PopDown                        'Return to the underlying application


EndIt:
CALL EndTSR(ID$)                    'Terminate and stay resident

SUB DisplayMessage (Message$) STATIC

    '----- Save the underlying screen, center and print the message
    CALL BlockCopy(ScrSeg, ScrAddr, VARSEG(ScrBuf$), SADD(ScrBuf$), OneSixty)
    Temp$ = STRING$(80, 32)
    MID$(Temp$, (80 - LEN(RTRIM$(Message$))) \ 2) = Message$
    CALL PDQPrint(Temp$, MessageLine, 1, Colr + 128)
    
    FOR N = 600 TO 1200 STEP 300    'Sound an alarm
       CALL PDQSound(N, 3)          'Sound a tone
       CALL Pause(3)                'Wait 3 clock ticks
    NEXT

    DO                              'Clear the keyboard buffer first in case
    LOOP WHILE BIOSInkey%           '  they were in the middle of typing
    
    DO                              'Wait for any key to be pressed
    LOOP UNTIL BIOSInkey%

    '----- Restore the underlying screen
    CALL BlockCopy(VARSEG(ScrBuf$), SADD(ScrBuf$), ScrSeg, ScrAddr, OneSixty)

END SUB

SUB GetMessage (Message$, AppointTime$) STATIC
   
    SHARED CursorBot

    '----- Save the underlying screen
    CALL BlockCopy(ScrSeg, ScrAddr, VARSEG(ScrBuf$), SADD(ScrBuf$), OneSixty)

    '----- Blank the message line
    CALL PDQPrint(STRING$(80, 32), MessageLine, 1, Colr)

    '----- Get the apointment time from the operator
    CALL PDQPrint("Enter the Appointment Time:", MessageLine, 5, Colr)
    CALL CursorSize(CursorBot - 1, CursorBot)
    LOCATE MessageLine, 33
    AppointTime$ = TIME$
    CALL BIOSInput(AppointTime$, Colr)

    '----- Get the message from the operator
    CALL PDQPrint("Enter the Appointment Message:", MessageLine, 2, Colr)
    LOCATE MessageLine, 33
    CALL BIOSInput(Message$, Colr)

    '----- Restore the underlying screen
    CALL BlockCopy(VARSEG(ScrBuf$), SADD(ScrBuf$), ScrSeg, ScrAddr, OneSixty)
       
END SUB

