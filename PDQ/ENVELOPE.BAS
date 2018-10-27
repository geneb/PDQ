'********** ENVELOPE.BAS - TSR text mode address capture program
'
'Copyright (c) 1990 Don Malin & Crescent Software
'
'This is a deluxe TSR showing many advanced features such as replaceable
'parameters, error trapping on file operations, saving and restoring of the
'underlying screen, and TSR deinstallation.
'
'Note: This program cannot be run in the QuickBASIC environment.
'
'----------------------------------------------------------------------------
'To take as little DOS memory as possible when this program is installed as
'a TSR, you should link it with the STR00512.OBJ and other stub files:
'
'Compile and link as follows:
'
' BC ENVELOPE /S/O;
' LINK /NOD /NOE ENVELOPE STR00512 _NOREAD _NOVAL _LOCATE,, NUL, SMALLDOS PDQ;
' EXE2COM ENVELOPE
'
'----------------------------------------------------------------------------
'Install this program as a TSR as follows:
'
'   ENVELOPE outfile [/fl n] [/tm n] [/lm n]
'
'Where:
'  "outfile" is the name of a file or device (LPT1, LPT2 or PRN) to send
'            the captured address to (OPEN FOR APPEND is used to combine
'            multiple envelopes into a single file).  Notice that a trailing
'            colon is NOT used for printer device names with P.D.Q.
'  "/fl n" - (Form Length) specifies that the envelope (form) is "n" lines
'            long.  That is, extra blanks are printed to fill that many lines.
'  "/tm n"   (Top Margin) specifies that "n" lines will be printed before
'            the address.
'  "/lm n"   (Left Margin) specifies the address will be indented "n" spaces.
'
'The following specifies a standard size (#10) envelope on printer port #1:
'
'  ENVELOPE lpt1 /fl 25 /tm 10 /lm 40
'
'If you reinvoke the program from DOS with no parameters, it will uninstall
'itself.  If you reinvoke the program with any parameters, the new parameters
'will replace the resident program's current settings.
'****************************************************************************

DEFINT A-Z

'$INCLUDE: 'PDQDECL.BAS'

'----- Internal procedures
DECLARE FUNCTION GetSwitchVal% (CmdLine$, switch$)
DECLARE SUB GetCommandLineArgs (ID$, FormLen, TopMarg, LeftMarg)
DECLARE SUB HiLightBlock (NumRows%, NumCols%)
DECLARE SUB PaintBlock (UlRow%, UlCol%, BrRow%, BrCol%, Clr%)
DECLARE SUB RestLine (Row%, LCol%, TxtBuf$, ClrBuf$)
DECLARE SUB SaveLine (Row%, LCol%, Buf$, ClrFlag%)

CONST MaxRows = 5                      'Maximum number of address lines
CONST MaxCols = 32                     'Maximum number of address columns
CONST Nul$ = ""

ID$ = "Envelope (c) 1990 Crescent Software, Inc."   'All TSR's need an ID

DIM SHARED FileName AS STRING * 40       'Holds the output file name
DIM SHARED X, Y, N, Temp, Char, BaseAddr 'Share common scratch variables

'----- Make an array to hold the characters and colors from the screen.
DIM SHARED Buf$(1 TO MaxRows)
FOR N = 1 TO MaxRows
   Buf$(N) = STRING$(MaxCols, 0)
NEXT


'----- Get command line arguments or deinstall if requested.
CALL GetCommandLineArgs(ID$, FormLen, TopMarg, LeftMarg)


'----- Set up the TSR as a pop-up using Ctrl-E
CALL PopUpHere(&H412, ID$)
GOTO EndIt                             'Skip past the interrupt handler below
10                                     'this line number is needed for VB/DOS

'----- The following code is invoked each time Ctrl-E is pressed

    CALL BreakOff                      'Disable Ctrl-BREAK
    SaveCsr& = CursorSave&             'Save the current cursor location

    IF LEN(RTRIM$(FileName$)) = 0 THEN 'Make a default file name if none given
       LSET FileName$ = "lpt1"
    END IF


    '----- Let the user highlight the address on screen
    CALL HiLightBlock(NumRows, NumCols)


    '----- Print the highlighted address
    IF NumRows THEN                    'If the user didn't press Escape
    
       CALL CritErrOff                 'Make sure we get control of errors
       
       OPEN RTRIM$(FileName$) FOR BINARY AS #1  'Open the output file

       IF ERR THEN                     'If an error occurred, beep
          BEEP
       ELSE                            'No errors, print the captured text
          SEEK #1, LOF(1) + 1

          FOR X = 1 TO TopMarg         'Print the top margin
             PRINT #1,
          NEXT

          FOR N = 1 TO NumRows         'Examine each line of the address and
                                       '  trim the right side
             Temp$ = RTRIM$(LEFT$(Buf$(N), NumCols))
             IF LEN(Temp$) THEN        'If the line isn't blank, print it
                PRINT #1, SPC(LeftMarg); Temp$
                X = X + 1              'Track the number of printed lines
             END IF
          NEXT
          Temp$ = Nul$

          FOR N = X TO FormLen         'Kick out the remaining lines on form
              PRINT #1,
          NEXT
          CLOSE #1
       END IF

       CALL CritErrOn                  'Reenable critical error handling for
                                       '  the underlying application
    END IF

    CALL CursorRest(SaveCsr&)          'Restore the cursor location/size
    CALL BreakOn                       'Reenable Ctrl-Break
    CALL PopDown                       'Go back to the underlying application

EndIt:
CALL EndTSR(ID$)                       'Installs as a TSR

'Reads command line parameters, uninstalls the program if none are given.
'
'ID$ is the program's TSR identification string
'FormLen is the total length of the envelope
'TopMarg is the number of lines to skip before printing
'LeftMarg is the number of spaces to indent the address
'
SUB GetCommandLineArgs (ID$, FormLen, TopMarg, LeftMarg) STATIC

    PRINT ID$;                         'Print the banner

    'UNREM the following for command line help
    '----- Does the user want help?
    'IF INSTR(COMMAND$, "?") THEN
    '   PRINT
    '   PRINT "Syntax:"
    '   PRINT "  >Envelope captfile [/FL n] [/TM n] [/LM n]"
    '   PRINT
    '   PRINT "where:"
    '   PRINT "  'captfile' is the name of the output file, or LPTn for printer"
    '   PRINT "  /FL n = the total length of your form."
    '   PRINT "  /TM n = the top margin to leave blank."
    '   PRINT "  /LM n = the left margin."
    '   END
    'END IF


    '----- Initialize, reinitialize or uninstall the TSR
    DGROUP = TSRInstalled%(ID$)        'see if we're already installed


    IF LEN(COMMAND$) THEN              'do they want to install?

       CmdLine$ = UCASE$(COMMAND$)     'Copy the command line

       '----- Parse out parameters
       FormLen = GetSwitchVal%(CmdLine$, "/FL") 'Form length
       TopMarg = GetSwitchVal%(CmdLine$, "/TM") 'Top margin
       LeftMarg = GetSwitchVal%(CmdLine$, "/LM")'Left margin
       CmdLine$ = LTRIM$(RTRIM$(CmdLine$))      'Remainder of command line is
                                                '  the output file name
       LSET FileName$ = CmdLine$                'Assign remainder to file name

       IF DGROUP THEN                  'Already resident?
          PRINT
          
          DEF SEG = DGROUP             'Point to resident program data segment

          '----- Output File Name
          IF LEN(CmdLine$) THEN        'Are they giving us a new file name?
             Temp = VARPTR(FileName$)  'Get the address of the file name and
             FOR N = 1 TO LEN(FileName$) ' poke it into the resident variable
                Char = MidChar%(FileName$, N)
                POKE Temp + N - 1, Char
             NEXT N
          END IF

          '----- Form Length
          IF FormLen > -1 THEN         'Poke new values into resident copy
             POKE VARPTR(FormLen), FormLen
          END IF
          
          '----- Top Margin
          IF TopMarg > -1 THEN
             POKE VARPTR(TopMarg), TopMarg
          END IF

          '----- Left Margin
          IF LeftMarg > -1 THEN
             POKE VARPTR(LeftMarg), LeftMarg
          END IF

          PRINT "New settings are now in effect"

          END                          'End this copy of the program
       ELSE
       
          '----- Fill in default values if none given
          IF FormLen = -1 THEN FormLen = 25
          IF LeftMarg = -1 THEN LeftMarg = 40
          IF TopMarg = -1 THEN TopMarg = 10
       END IF

       CmdLine$ = Nul$

    ELSE                               'No parameters means they want to
                                       '  deinstall the program
       PRINT
       IF DGROUP THEN                       'already installed?
          Temp = PopDeinstall%(DGROUP, ID$) 'yes, try to remove the
          PRINT                             '  earlier copy
          IF Temp THEN
             PRINT "Envelope is no longer resident."
          ELSE                          'de-installation failed, so tell 'em
             PRINT "Unable to de-install Envelope"
          END IF
       ELSE
          PRINT "Envelope is not resident -- try again with a file name."
       END IF
       
       END                              'either way, end the program
    END IF

    PRINT " - Press CTRL-E to activate" 'Show them the hotkey to use

END SUB

'Looks for a command line switch and returns its numeric value.  Also removes
'the switch and number from the command line string.
'
'CmdLine$ is a copy of the command line
'Switch$ is the switch identifier to look for
'
FUNCTION GetSwitchVal% (CmdLine$, switch$) STATIC

   GetSwitchVal% = -1                  'Nothing found yet

   Temp = LEN(switch$)                 'Save the length of the switch
   X = INSTR(CmdLine$, switch$)        'Get its position in the string
   IF X THEN                           'If found, assign its value to
                                       '  function
      GetSwitchVal% = PDQValI(MID$(CmdLine$, X + Temp))

      Temp = X + Temp + 1              'Find the end of the switch value
      Y = INSTR(Temp, CmdLine$, " ")
      IF Y = 0 THEN Y = INSTR(Temp, CmdLine$, "/")
      IF Y = 0 THEN Y = LEN(CmdLine$) + 1
                                       'Remove the switch and its value
      CmdLine$ = LEFT$(CmdLine$, X - 1) + MID$(CmdLine$, Y)
   END IF

END FUNCTION

'Allow the user to highlight a block on the screen that contains the address.
'The user first moves the cursor to the upper left corner of the address and
'then presses Enter.  Next he/she highlights the desired area and presses
'Enter again.  At this point the routine will return with the number of rows
'and columns selected.
'
'NumRows returns the number of rows highlighted unless the user pressed
'Escape, in which case it will return 0.
'
'NumCols returns the number of columns highlighted.
'
SUB HiLightBlock (NumRows, NumCols) STATIC

    SHARED OBrRow, OBrCol              'Share the previous cursor location
    SHARED BotRow, BotCol              'Share the maximum cursor location

    NumRows = 0                        'Nothing marked yet
    Clr = NumRows                      'No color has been read yet
    TxtFlag = NumRows                  'Flag for saving text
    ClrFlag = -1                       'Flag for saving color

    BrRow = CSRLIN                     'Save the current cursor row and col.
    BrCol = POS(0)

    UlRow = 1                          'Minimum row and column is 1 initially
    UlCol = UlRow
    MsgCol = UlCol
    BotCol = 80                        '80 columns maximum initially
    BotRow = 25                        'Default to 25 lines maximum initially
   
    '----- Determine the type of monitor and current number of screen lines
    DIM Registers AS RegType           'RegType is defined in PDQDECL.BAS
    
    DEF SEG = 0                        'See what type of monitor
    IF PEEK(&H463) <> &HB4 THEN        'It might be an EGA or VGA
       ScrSeg = &HB800                 'Use the color segment
       Registers.AX = &H1200           'Ask for the EGA info service
       Registers.BX = &H10
       Interrupt &H10, Registers
       IF (Registers.BX AND &HFF) <> &H10 THEN  'if BL <> 10h it's an EGA/VGA
          BotRow = PEEK(&H484) + 1     'get rows, adjust to 1-based
       END IF
       CursorSize NumRows, 7           'Make the cursor big
    ELSE
       ScrSeg = &HB000                 'Use monochrome segment
       CursorSize NumRows, 15
    END IF

    DEF SEG = ScrSeg                   'Point current segment to the screen

    TxtBuf$ = STRING$(BotCol, 0)       'Character buffer for instruction line
    ClrBuf$ = TxtBuf$                  'Color buffer for instruction line

    '----- Print instruction line for locating the upper left corner
    MsgTxt$ = "Move the cursor to the upper left corner of the address and press [Enter].      "
    GOSUB ShowMessage

    
    '----- Key processing loop
    DO
       Ky = BIOSInkey%                 'Get a keypress
                                       
       IF Ky THEN                      'If a key was pressed...
       
          SELECT CASE Ky               'Branch according the keys value

             '----- Enter key
             CASE 13
                '----- Clr of 0 means we are locating the upper left corner
                IF Clr = 0 THEN

                   '----- Print new instructions
                   RestLine MsgRow, MsgCol, TxtBuf$, ClrBuf$
                   LSET MsgTxt$ = "Now move the cursor to highlight the entire address and then press [Enter]."
                   GOSUB ShowMessage

                   '----- Save the upper left corner coordinates
                   UlRow = BrRow
                   UlCol = BrCol

                   '----- Set the bottom right corner to the maximum size
                   BrRow = UlRow + MaxRows - 1
                   BrCol = UlCol + MaxCols - 1

                   '----- Adjust the bottom right corner if it would be off
                   '      the screen
                   IF BrRow > BotRow THEN
                      BrRow = BotRow
                   ELSE
                      BotRow = BrRow
                   END IF

                   IF BrCol > BotCol THEN
                      BrCol = BotCol
                   ELSE
                      BotCol = BrCol
                   END IF

                   '----- Save coordinates history for later resizing
                   OBrRow = BrRow
                   OBrCol = BrCol

                   '----- Read and save the underlying window colors
                   FOR Row = UlRow TO BotRow 'For each row of the whole block
                      Y = Row - UlRow + 1    'Calculate buffer array element
                                             'Save the line
                      SaveLine Row, UlCol, Buf$(Y), ClrFlag
                   NEXT

                   '----- Read the screen's color and assign a highlight color
                   IF ASC(Buf$(1)) = 112 THEN
                      Clr = 7
                   ELSE
                      Clr = 112
                   END IF

                '----- Color already set, calculate rows and columns
                ELSE
                   NumRows = BrRow - UlRow + 1
                   NumCols = BrCol - UlCol + 1
                   EXIT DO                   'All done, bail out of loop
                END IF

             '----- Escape key
             CASE 27
                EXIT DO

             '----- Home key
             CASE -71
                BrCol = UlCol

             '----- Down arrow
             CASE -80
                IF BrRow < BotRow THEN BrRow = BrRow + 1

             '----- Up arrow
             CASE -72
                IF BrRow > UlRow THEN BrRow = BrRow - 1

             '----- Right arrow
             CASE -77
                IF BrCol < BotCol THEN BrCol = BrCol + 1

             '----- Left arrow
             CASE -75
                IF BrCol > UlCol THEN BrCol = BrCol - 1

             CASE ELSE
          END SELECT

          IF BrRow = MsgRow THEN
             RestLine MsgRow, MsgCol, TxtBuf$, ClrBuf$
             GOSUB ShowMessage
          END IF
         
          LOCATE BrRow, BrCol                'Update the cursor location

          '----- If in Highlight mode, paint/repaint the block
          IF Clr THEN PaintBlock UlRow, UlCol, BrRow, BrCol, Clr
       END IF
    LOOP


    RestLine MsgRow, MsgCol, TxtBuf$, ClrBuf$
    TxtBuf$ = Nul$
    ClrBuf$ = Nul$
    MsgTxt$ = Nul$

    '----- Restore the underlying screen if they were highlighting
    IF Clr THEN
       FOR Row = UlRow TO BrRow
          Y = Row - UlRow + 1
          RestLine Row, UlCol, "", Buf$(Y)
       NEXT

       '----- Read and save the highlighted text
       FOR Row = UlRow TO UlRow + NumRows - 1
          Y = Row - UlRow + 1    'Calculate buffer array element
                                 'Save the line
          SaveLine Row, UlCol, Buf$(Y), TxtFlag
       NEXT
    END IF

    
    EXIT SUB


'----- Display a help message after first saving the background screen
ShowMessage:

    IF BrRow <> 1 THEN                    'If the cursor isn't on the top
       MsgRow = 1                         '  line, put the message there
    ELSE                                  'Otherwise put it in the bottom line
       MsgRow = BotRow
    END IF

    SaveLine MsgRow, MsgCol, TxtBuf$, TxtFlag   'Save the underlying text
    SaveLine MsgRow, MsgCol, ClrBuf$, ClrFlag   'Save the underlying color

    PDQPrint MsgTxt$, MsgRow, MsgCol, 112       'Print the instructions
RETURN

END SUB

'Paints or repaints the currently highlighted block on the screen.
'
'The first four parameters are the coordinates of the upper left and the
'bottom right corners of the block.
'
'Clr is the painting color.
'
SUB PaintBlock (UlRow, UlCol, BrRow, BrCol, Clr) STATIC

    SHARED OBrRow, OBrCol              'Share the previous cursor location

    '----- Un-paint rows
    IF BrRow < OBrRow THEN             'If moving up, restore the previously
       FOR Row = BrRow TO OBrRow         '  highlighted lines
          Y = Row - UlRow + 1
          RestLine Row, UlCol, "", Buf$(Y)
       NEXT
    END IF

    '----- Un-paint columns
    IF BrCol < OBrCol THEN             'If moving left restore the previously
       FOR N = BrCol TO OBrCol         '  highlighted columns
          X = N - UlCol + 1            'Calculate offset into block buffer
          BaseAddr = (N - 1) * 2       'Calc. column's relative screen address
                                       'For each row in the block
          FOR Y = UlRow TO UlRow + MaxRows - 1
                                       'Calculate character's screen address
             Temp = (Y - 1) * 160 + BaseAddr + 1
                                       'Poke the original color into screen
             Char = MidChar%(Buf$(Y - UlRow + 1), X)
             POKE Temp, Char
          NEXT
       NEXT
    END IF

    '----- Paint the block
    FOR Y = UlRow TO BrRow             'Go from top to bottom of whole block
       BaseAddr = (Y - 1) * 160        'Get screen address of the start of row

       FOR X = UlCol TO BrCol          'Go from left to right of whole block
                                       'Calculate address of this location
          Temp = (X - 1) * 2 + BaseAddr + 1
          POKE Temp, Clr               'Poke highlight color into the screen
       NEXT
    NEXT

    OBrRow = BrRow                     'Save current cursor location for next
    OBrCol = BrCol                     '  time through

END SUB

'Restores a row portion of the screen from our block buffer.
'
'Row is the row to restore
'LCol is left screen column to restore to
'TxtBuf$ is the character buffer to restore from
'ClrBuf$ is the same as above but holds color attributes
'
SUB RestLine (Row, LCol, TxtBuf$, ClrBuf$) STATIC

    BaseAddr = (Row - 1) * 160         'Calculate the screen row address
    X = LEN(TxtBuf$)

    FOR N = LCol TO LCol + LEN(ClrBuf$) - 1
       Y = N - LCol + 1                'Calculate offset into block buffer
                                       'Calculate character's screen address
       Temp = (N - 1) * 2 + BaseAddr

       IF X THEN                       'Poke the original character
          Char = MidChar%(TxtBuf$, Y)
          POKE Temp, Char
       END IF
                                       'Poke the original color
       Char = MidChar%(ClrBuf$, Y)
       POKE Temp + 1, Char
    NEXT

END SUB

'Saves a line from the screen to a text and a color buffer.
'
'Row is the row to save
'LCol is left screen column to save
'TxtBuf$ is the buffer to save to and it must be padded to the length to save
'ClrBuf$ is the same as above but holds color attributes
'
SUB SaveLine (Row, LCol, Buf$, ClrFlag) STATIC
    
    BaseAddr = (Row - 1) * 160         'Calculate the screen row address
                                       'For each column, calculate its
    FOR N = LCol TO LCol + LEN(Buf$) - 1
       Temp = (N - 1) * 2 + BaseAddr   '   screen address and
       X = N - LCol + 1                '   Offset into the buffers
                                       'Peek the attribute
       MID$(Buf$, X) = CHR$(PEEK(Temp - ClrFlag))
    NEXT

END SUB

