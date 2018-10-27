'********** PDQBLANK.BAS - TSR screen blanking utility

'Copyright (c) 1990 Crescent Software
'written by Nash Bly and Ethan Winer


'To have this program take as little RAM as possible when resident, compile
'and link as follows:
'
'   BC PDQBLANK /O;
'   LINK /NOE /NOD PDQBLANK _NOVAL _NOREAD STR00256, , NUL, PDQ
'
'This program may be run multiple times to change the delay time value.  To
'do this requires a bit of trickery, where TSRInstalled% is used both to see
'if we are already resident, and if so what the data segment of the resident
'copy is.  Then DEF SEG and POKE are used to assign the new Delay time
'directly into the resident copy.  Also see PDQBLNK2.BAS for a smaller (about
'1.3K less memory taken) version of PDQBLANK that does not have this feature,
'or the ability to restore the screen when a program prints through the BIOS.

    DEFINT A-Z
    '$INCLUDE: 'PDQDECL.BAS'

    DIM Registers8 AS RegType   'RegType for int 8 processing
    DIM Registers9 AS RegType   'RegType for int 9 processing
    DIM Registers10 AS RegType  'RegType for int 10 processing
   
    ID$ = "PDQBLANK 1.00 Copyright (c) 1990 Crescent Software"
    CALL PDQPrint(ID$, CSRLIN, POS(0), 7)       'print the sign-on message

    Delay = PDQValI%(COMMAND$)          'see if they gave a delay value
    IF Delay = 0 THEN Delay = 60 * 2    'no, default to 2 minutes
   
    DGroup = TSRInstalled%(ID$)         'see if we're already installed
    IF DGroup THEN                      'yes, use the new delay value
       DEF SEG = DGroup                 'we're going to POKE it into the TSR
       CALL PDQPoke2(VARPTR(Delay), Delay)      'that's already resident
       END                                      'all done
    END IF


'-- Reserve memory for saving the screen, use 43 or 50 instead of 25 if the
'   monitor may be in a 43 or 50 line mode.  However, the TSR will then
'   occupy that much additional memory.

    CONST NumBytes = 25 * 80 * 2        'the number of bytes to save
    ArraySeg = AllocMem%(NumBytes)      'Rows * Cols * Bytes per Col

'-- PEEK low memory to determine the correct video memory segment.

    DEF SEG = 0                         'for peeking low memory
    IF PEEK(&H463) = &HB4 THEN
       VideoSeg = &HB000                'monochrome
    ELSE
       VideoSeg = &HB800                'color
    END IF
    DEF SEG = VideoSeg                  'for clearing the screen below

'-- Set up keyboard Interrupt 9, jump to set up Int 10h.

    Registers9.IntNum = 9               'specify keyboard interrupt 9
    CALL PointIntHere(Registers9)       'setup interrupt entry point
    GOTO Install10                      'skip to install interrupt 10
10                                      'this line number is needed for VB/DOS

'-- This block of code receives control each time a key is pressed.

    CALL IntEntry1                      'mandatory first two steps for
    CALL IntEntry2(Registers9, Zero)    '  any PDQ interrupt routine

    TicksPassed = 0                     'reset the tick count on keypresses

    IF ScrnBlanked THEN                 'if the screen is blank restore it
       GOSUB ScrnRest
       X = INP(&H60)                    'eat the key press
       CALL ResetKeyboard               'then reset the keyboard hardware
       CALL ReturnFromInt(Registers9)   'and return to underlying program
    END IF
   
    CALL GotoOldInt(Registers9)         'if the screen is not blanked, exit
                                        '  to the normal keypress routine

'-- Set up to trap video Interrupt 10h.
  
Install10:
    Registers10.IntNum = &H10           'specify video interrupt 10
    CALL PointIntHere(Registers10)      'setup interrupt entry point
    GOTO Install8                       'skip to install interrupt 8
20                                      'this line number is needed for VB/DOS

'-- This block of code receives control each time someone prints.

    CALL IntEntry1                      'mandatory first two steps for
    CALL IntEntry2(Registers10, Zero)   '  any PDQ interrupt routine
   
    TicksPassed = 0                     'reset the tick count on keypresses

    IF ScrnBlanked THEN GOSUB ScrnRest  'if the screen is blank restore it
    CALL GotoOldInt(Registers10)        'continue on to the original int. 10h
   

'-- Set up the intercept for timer Interrupt 8.

Install8:
    Registers8.IntNum = 8               'specify Interrupt 8
    CALL PointIntHere(Registers8)       'setup interrupt entry point
    GOTO EndIt                          'jump to finish installation
30                                      'this line number is needed for VB/DOS

'-- This block of code receives control each time a timer tick occurs.
 
    CALL IntEntry1                      'required first two steps for any
    CALL IntEntry2(Registers8, Zero)    '  P.D.Q. interrupt handler

    IF ScrnBlanked THEN                 'if the screen is already blanked
       CALL GotoOldInt(Registers8)      'go on to the normal timer routine
    END IF
   
    CALL CallOldInt(Registers8)         'otherwise service the timer ASAP
                                           
    IF NOT ScrnBlanked THEN             'if it isn't already blanked
       TicksPassed = TicksPassed + 1    'increment tick counter
       IF TicksPassed > Delay * 18 THEN 'the delay has passed, save screen
          ScrnBlanked = -1              'show that the screen is now blanked
          CALL BlockCopy(VideoSeg, Zero, ArraySeg, Zero, NumBytes)
          FOR X = 0 TO NumBytes - 1 STEP 2 'clear the screen by
              CALL PDQPoke2(X, Zero)       'poking zero words
          NEXT                             'into display memory
       END IF
    END IF

    CALL ReturnFromInt(Registers8)      'return to the underlying app.

'-- Terminate and stay resident.

EndIt:
    CALL EndTSR(ID$)

ScrnRest:
    ScrnBlanked = 0                     'show that the screen is not blanked
    CALL BlockCopy(ArraySeg, Zero, VideoSeg, Zero, NumBytes)
    RETURN

