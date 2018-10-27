'********** PDQBLNK2.BAS - "small" version of PDQBLANK.BAS screen blanker

'Copyright (c) 1990 Crescent Software
'Written by Nash Bly and Ethan Winer

'To have this program take as little RAM as possible when resident, compile
'and link as follows:
'
'   BC PDQBLANK /O;
'   LINK /NOE /NOD PDQBLANK _NOVAL _NOREAD , , NUL, PDQ


'-------- Define default segment, constants and type variables.

    DEFINT A-Z
    DECLARE FUNCTION AllocMem% (NumBytes)

    TYPE RegType
         AX        AS INTEGER
         BX        AS INTEGER
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
   
    CONST DelayTime = 2 * 60 * 18   '2 Min blanking delay: Min * Sec * Ticks
    DIM Registers8 AS RegType       'RegType for int 8 processing
    DIM Registers9 AS RegType       'RegType for int 9 prcessing

'-------- Start of execution.

    DATA PDQBLANK 1.00 Copyright (c) 1990 Crescent Software
    Descriptor& = &H730032                          'this is the DATA address
    CALL PDQPrint(Descriptor&, CSRLIN, POS(0), 7)   'print the sign-on message

'-------- Reserve memory for saving the screen, use 43 or 50 instead of 25 if
'         the monitor may be in a 43 or 50 line mode.  However, the TSR will
'         then occupy that much additional memory.

    CONST NumBytes = 25 * 80 * 2            'the number of bytes to save
    ArraySeg = AllocMem%(NumBytes)          'Rows * Cols * Bytes per Col

'-------- PEEK low memory to determine the correct video memory segment.

    DEF SEG = 0                             'for peeking low memory
    IF PEEK(&H463) = &HB4 THEN
       VideoSeg = &HB000                    'monochrome
    ELSE
       VideoSeg = &HB800                    'color
    END IF
    DEF SEG = VideoSeg                      'for clearing the screen below

'-------- Set up keyboard Interrupt 9, jump to set up Int 8.

    Registers9.IntNum = 9                   'specify keyboard interrupt 9
    CALL PointIntHere(Registers9)           'setup interrupt entry point
    GOTO Install8                           'skip to install interrupt 8
10                                     'this line number is needed for VB/DOS

'-------- This block of code receives control each time a key is pressed.

    CALL IntEntry1                          'mandatory first two steps for
    CALL IntEntry2(Registers9, Zero)        'any PDQ interrupt routine

    TicksPassed = 0                         'reset tick count on keypress
   
    IF ScrnBlanked THEN                     'if screen is blanked, restore it
       CALL BlockCopy(ArraySeg, Zero, VideoSeg, Zero, NumBytes)
       ScrnBlanked = 0                      'reset flag
       Dummy = INP(&H60)                    'eat the key press
       CALL ResetKeyboard                   'then reset the keyboard hardware
       CALL ReturnFromInt(Registers9)       'and return to underlying program
    END IF
   
    CALL GotoOldInt(Registers9)             'if the screen is not blanked
                                            'exit to normal keypress routine

'-------- Set up the intercept for timer Interrupt 8.

Install8:
    Registers8.IntNum = 8                   'specify Interrupt 8
    CALL PointIntHere(Registers8)           'setup interrupt entry point
    GOTO EndIt                              'jump to finish installation
20                                     'this line number is needed for VB/DOS

'-------- This block of code receives control each time a timer tick occurs.
 
    CALL IntEntry1                          'required first two steps for any
    CALL IntEntry2(Registers8, Zero)        '  P.D.Q. interrupt handler

    IF ScrnBlanked THEN                     'if the screen is already blanked
       CALL GotoOldInt(Registers8)          'exit to normal timer routine
    END IF                                  'the screen is not blanked
   
    CALL CallOldInt(Registers8)             'service the timer right away
                                            
    TicksPassed = TicksPassed + 1           'increment tick counter
    IF TicksPassed > DelayTime% THEN        'the delay has passed, save screen
       CALL BlockCopy(VideoSeg, Zero, ArraySeg, Zero, NumBytes)
       ScrnBlanked = -1                     'set the flag
       FOR X = 0 TO NumBytes - 1 STEP 2     'clear the screen by poking zeros
           CALL PDQPoke2(X, Zero)           'into display RAM
       NEXT
    END IF

    CALL ReturnFromInt(Registers8)          'return to the underlying app.

'-------- Terminate and stay resident.

EndIt:
    CALL EndTSR(Descriptor&)

