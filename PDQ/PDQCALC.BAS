'*********** PDQCALC.BAS - 4-function pop-up calculator

'Copyright (c) Crescent Software 1989
'written by Paul Passarelli and Ethan Winer

'This program will run either in the environment or when compiled to disk.
'You MUST REM the line "GOTO ENDIT" to run in the environment, and also load
'PDQSUBS.BAS as a module (for the Dollar$ function).
'
'To take as little DOS memory as possible when this program is installed as
'a TSR, you should link it with the various P.D.Q. "stub" files as follows:
'
'    BC PDQCALC /O;
'    LINK /NOD /NOE PDQCALC STR00512 _NOVAL _NOREAD, , NUL, PDQ;


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

CONST ULRow = 2, ULCol = 57
CONST LRRow = ULRow + 19, LRCol = ULCol + 21
CONST R = ULRow + 2, C = ULCol + 5

CONST WindowSize = (LRRow - ULRow + 1) * (LRCol - ULCol + 1) * 2
ArraySeg = AllocMem%(WindowSize)        'holds the underlying screen
IF ArraySeg = 0 THEN
   PRINT "Unable to allocate memory - ending"
   END
END IF

Zero$ = "         0.00"                 'the starting display
Display$ = Zero$                        'string * 13

DEF SEG = 0
IF PEEK(&H463) = &HB4 THEN
   ScreenSeg = &HB000                   'monochrome
   CalcColor = 112
   NameColor = 112
   MemColor = 15
   NoMColor = 0
ELSE
   ScreenSeg = &HB800                   'color
   CalcColor = 48
   NameColor = 63
   MemColor = 57
   NoMColor = 55
END IF


DEF FnScrnSave% (ULRow, ULCol, LRRow, LRCol)    'saves the underlying screen

    STATIC ArrayAdr, VideoAdr, NumBytes, X

    FOR X = ULRow - 1 TO LRRow - 1              'walk through video memory
        NumBytes = 2 * (LRCol - ULCol + 1)      'calculate bytes/row
        ArrayAdr = NumBytes * (X - ULRow + 1)   'and the offset into the array
        VideoAdr = X * 160 + 2 * (ULCol - 1)    'and the screen address
        '----- the following enables CGA snow checking at the expense of speed
        'IF ScreenSeg = &HB800 THEN             'color, might be CGA
        '   DO                                  'wait for the start of the
        '   LOOP UNTIL INP(&H3DA) AND 8         '  vertical retrace interval
        'END IF
        CALL BlockCopy(ScreenSeg, VideoAdr, ArraySeg, ArrayAdr, NumBytes)
    NEXT

END DEF


DEF FnScrnRest% (ULRow, ULCol, LRRow, LRCol)    'restores application screen

    STATIC ArrayAdr, VideoAdr, NumBytes, X

    FOR X = ULRow - 1 TO LRRow - 1              'step through the array
        NumBytes = 2 * (LRCol - ULCol + 1)      'calculate bytes/row
        ArrayAdr = NumBytes * (X - ULRow + 1)   'and the offset into the array
        VideoAdr = X * 160 + 2 * (ULCol - 1)    'and the video address
        '----- the following enables CGA snow checking at the expense of speed
        'IF ScreenSeg = &HB800 THEN             'color, might be CGA
        '   DO                                  'wait for the start of the
        '   LOOP UNTIL INP(&H3DA) AND 8         '  vertical retrace interval
        'END IF
        CALL BlockCopy(ArraySeg, ArrayAdr, ScreenSeg, VideoAdr, NumBytes)
    NEXT
   
END DEF


DEF FnDisp%                                     'this updates the display
    RSET Display$ = Dollar$(Wind&)
    PDQPrint Display$, R, C, 58
END DEF


ID$ = "PDQCalc Copyright (c) 1989 Crescent Software - press Alt-C to activate"
PDQPrint ID$, CSRLIN, POS(0), 7

CALL PopUpHere(&H82E, ID$)
GOTO EndIt                              'REM this to run in the environment
10                                      'this line number is needed for VB/DOS

Dummy = FnScrnSave%(ULRow, ULCol, LRRow, LRCol) 'save the underlying screen

'----- Show the calculator "pad"
PDQPrint " ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ» ", ULRow + 1, ULCol, CalcColor
PDQPrint " Ç                 ¶ ", ULRow + 2, ULCol, CalcColor
PDQPrint " ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼ ", ULRow + 3, ULCol, CalcColor
PDQPrint "  Crescent PDQ Calc  ", ULRow + 4, ULCol, NameColor
PDQPrint " ÖÄ· ÖÄ· ÖÄ· ÖÄ· ÖÄ· ", ULRow + 5, ULCol, CalcColor
PDQPrint " º7º º8º º9º ºöº ºº ", ULRow + 6, ULCol, CalcColor
PDQPrint " ÓÄ½ ÓÄ½ ÓÄ½ ÓÄ½ ÓÄ½ ", ULRow + 7, ULCol, CalcColor
PDQPrint " ÖÄ· ÖÄ· ÖÄ· ÖÄ· ÖÄ· ", ULRow + 8, ULCol, CalcColor
PDQPrint " º4º º5º º6º º*º ºRº ", ULRow + 9, ULCol, CalcColor
PDQPrint " ÓÄ½ ÓÄ½ ÓÄ½ ÓÄ½ ÓÄ½ ", ULRow + 10, ULCol, CalcColor
PDQPrint " ÖÄ· ÖÄ· ÖÄ· ÖÄ· ÖÄ· ", ULRow + 11, ULCol, CalcColor
PDQPrint " º1º º2º º3º º-º ºMº ", ULRow + 12, ULCol, CalcColor
PDQPrint " ÓÄ½ ÓÄ½ ÓÄ½ ÓÄ½ ÓÄ½ ", ULRow + 13, ULCol, CalcColor
PDQPrint " ÖÄ· ÖÄ· ÖÄ· ÖÄ· ÖÄ· ", ULRow + 14, ULCol, CalcColor
PDQPrint " º0º ºNº º.º º+º º=º ", ULRow + 15, ULCol, CalcColor
PDQPrint " ÓÄ½ ÓÄ½ ÓÄ½ ÓÄ½ ÓÄ½ ", ULRow + 16, ULCol, CalcColor
PDQPrint " ÖÄÄÄ· ÖÄÄÄ· ÖÄ· ÖÄ· ", ULRow + 17, ULCol, CalcColor
PDQPrint " ºEscº ºAllº ºEº ºHº ", ULRow + 18, ULCol, CalcColor
PDQPrint " ÓÄÄÄ½ ÓÄÄÄ½ ÓÄ½ ÓÄ½ ", ULRow + 19, ULCol, CalcColor

IF Memr& <> 0 THEN
   Colr = MemColor            'something in memory, use bright blue
ELSE
   Colr = NoMColor            'don't show a zero, it is invisible
END IF
PDQPrint "M ", ULRow + 2, ULCol + 3, Colr       'print accordingly
PDQPrint Display$, R, C, 58

POKE &H417, PEEK(&H417) OR &H20         'turn on the NumLock key

Start:
    OP = Operation

GetTerm:
    DecPt = 0                           'clear the decimal point flag
    First = -1                          'marks the first digit of a number

Another:
    DO
       KyPrs = BIOSInkey%               'get a key press
    LOOP UNTIL KyPrs
    IF KyPrs >= 97 AND KyPrs <= 122 THEN
       KyPrs = KyPrs - 32               'capitalize if needed
    END IF

    IF Radix THEN                       'are we displaying in Hex (or Joke)?
       Dummy = FnDisp%                  'yes, restore the display
       Radix = 0                        'and clear the flag
    END IF

    SELECT CASE KyPrs                   'see what key they pressed

'----- Digits
       CASE 48 TO 57                    'zero thru nine
          KyPrs = KyPrs - 48            'normalize it to a number
          IF First THEN                 'is it the first digit?
             First = 0                  'yes,
             Wind& = First              'clear the display
          END IF

          IF DecPt = 0 THEN             'are we entering fractions?
             KyPrs = KyPrs * 100        'no, bump it up to whole numbers
             Term& = Wind& * 10 + KyPrs
             IF Term& <= 999999999 THEN 'will it cause an overflow?
                Wind& = Term&           'no, do it.
             END IF
          ELSE
             IF DecPt = -2 THEN         'tenths?
                KyPrs = KyPrs * 10      'yes, bump em up
             END IF
             IF DecPt < 0 THEN          'tenths or hundredths?
                Term& = Wind& + KyPrs   'see if it could cause an overflow
                IF Term& <= 999999999 THEN      'largest entry value
                   Wind& = Term&        'no, add it in
                   DecPt = DecPt + 1    'adjust decimal pointer
                   IF DecPt = 0 THEN    'is the "display" full?
                      DecPt = 1         'yes, don't allow any more
                   END IF
                END IF
             END IF
          END IF
          Dummy = FnDisp%               'update the window
          IF Wind& = 0 AND DecPt = 0 GOTO GetTerm       'eat leading zeros

'----- Decimal Point
       CASE 46
          IF DecPt GOTO Another
          IF First THEN                 'is it the first digit?
             First = 0                  'yes,
             Wind& = First              'clear the display
             PDQPrint Zero$, R, C, 58   'clear the window to "0"
          END IF
          DecPt = -2                    'set the DP flag to -decimal places

'----- Change Sign
       CASE 78
          Wind& = -Wind&                'negate the number
          Dummy = FnDisp%               'update the window

'----- Hex$
       CASE 72
          Radix = -1                            'show something unusual
          RSET Display$ = HEX$(Wind& \ 100)     'line it up
          PDQPrint Display$, R, C, 31           'print it
          CASE 71                               'Game
          Radix = -1
          PDQPrint "  SHELL OIL  ", R, C, 28

'----- Equals or Enter
       CASE 13, 61                      'Return, "="
          Operation = 0                 'to clear pending operations
          GOTO Complete

'----- Mathematical operators
       CASE 43, 45, 42, 47, 92          'plus, minus, multiply, both divisions
          Operation = KyPrs             'set pending operation
          GOTO Complete

'----- Memory Summation
       CASE 77                          'Memory Plus
          Term& = Memr& + Wind&         'check for memory overflow
          IF Wind& > 0 AND Term& < Memr& GOTO Fail
          IF Wind& < 0 AND Term& > Memr& GOTO Fail
          Memr& = Term&
          IF Memr& <> 0 THEN
             Colr = MemColor            'something in there, bright blue
          ELSE
             Colr = NoMColor            'don't show a zero, it is invisible
          END IF
          PDQPrint "M ", R, C - 2, Colr 'print accordingly
          GOTO GetTerm                  'start a new number

'----- Memory Recall
       CASE 82
          Wind& = Memr&                 'bring memory to the display
          Dummy = FnDisp%               'update it
          GOTO GetTerm                  'start a new number if you want

'----- Swap Display & Memory
       CASE -72, -80
          SWAP Memr&, Wind&             'swap display with memory
          IF Memr& <> 0 THEN
             Colr = MemColor
          ELSE
             Colr = NoMColor            'it is invisible
          END IF
          PDQPrint "M ", R, C - 2, Colr 'show memory status
          Dummy = FnDisp%               'update display
          GOTO GetTerm                  'get ready for a new number

'----- Clear All
       CASE 65
          GOTO ClearAll                 'skip the error
Fail:
          PDQPrint " >>  ERROR  << ", R, C - 2, 207     'turn on the ERROR
          DO
             KyPrs = BIOSInkey%
             IF KyPrs = 27 GOTO Escape          'ESC means quit completely
          LOOP UNTIL KyPrs                      'otherwise wait
ClearAll:
          Accu& = 0                             'wipe the slate clean
          Memr& = Accu&
          Wind& = Accu&
          DecPt = Accu&
          KyPrs = Accu&
          PDQPrint Zero$, R, C, 58              'zap the display
          PDQPrint "M ", R, C - 2, NoMColor     'turn off the M
          Display$ = Zero$
          GOTO Start                            'back to the begining

'----- Clear Entry
       CASE 67, 69
          PDQPrint Zero$, R, C, 58      'wipe the window
          GOTO GetTerm                  'restart the number

'----- Quit
       CASE 27                                  'Escape key
Escape:   POKE &H417, PEEK(&H417) AND &HDF      'turn off the NumLock key
          Dummy = FnScrnRest%(ULRow, ULCol, LRRow, LRCol) 'restore the screen
          CALL PopDown                                    'pop down
            
       CASE ELSE                                'case nuisance
    END SELECT
    GOTO Another                                'ignore and go again

Complete:
    IF Wind& > 0 AND Wind& < 100 THEN
       DecPt = 1                        'imply decimal point
    END IF
    Term& = Wind&                       'copy the number
    IF OP = 0 THEN                      'any pending operations?
       Accu& = Wind&                    'no, just assign the value

    ELSE
       SELECT CASE OP                   'perform pending operation
          CASE 43                       'addition
             Wind& = Accu& + Term&      'check for overflow
             IF (Term& > 0) AND (Wind& < Accu&) GOTO Fail
             IF (Term& < 0) AND (Wind& > Accu&) GOTO Fail
             Accu& = Wind&              'ok, assign it

          CASE 45                       'subtraction
             Wind& = Accu& - Term&      'check for underflow
             IF Term& > 0 AND Wind& > Accu& GOTO Fail
             IF Term& < 0 AND Wind& < Accu& GOTO Fail
             Accu& = Wind&              'ok, assign it

          CASE 42                       'multiplication
             SgnA = SGN(Accu&)          'note initial conditions
             SgnT = SGN(Term&)
             IF DecPt = 0 THEN Term& = Term& \ 100      'adjust if necessary
             Accu& = Accu& * Term&                      'try the multiply
             IF DecPt THEN Accu& = Accu& \ 100          'adjust if necessary
             IF SGN(Accu&) = 0 GOTO Nil                 'zero, or <.01
             IF SGN(Accu&) <> (SgnA * SgnT) GOTO Fail   'check for overflow

          CASE 47, 92                   'division
             IF Term& = 0 GOTO Fail     'don't divide by zero. GRIND!!!
             SgnA = SGN(Accu&)          'note initial conditions
             SgnT = SGN(Term&)
             IF DecPt = 0 THEN Term& = Term& \ 100      'adjust if necessary
             Accu& = (Accu& \ Term&)                    'try the multiply
             IF DecPt THEN Accu& = Accu& * 100          'adjust if necessary
             IF SGN(Accu&) = 0 GOTO Nil                 'zero, or <.01
             IF SGN(Accu&) <> (SgnA \ SgnT) GOTO Fail   'check for error
          CASE ELSE
       END SELECT
    END IF
Nil:
    Wind& = Accu&                       'prepare to display
    Dummy = FnDisp%                     'show the answer

GOTO Start                              'Window & Memory are preserved

EndIt:
CALL EndTSR(ID$)

