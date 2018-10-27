'********* COLORS.BAS - prints a chart of the screen attributes for each color

'Copyright (c) 1988 Ethan Winer

'This chart provides a quick reference showing the correct "encoded" color
'value to use with PDQPrint.  To get a hard copy printout, simply press
'Shift-PrtSc once it is on your screen.
'
'To obtain the equivalent colors but with flashing, add 128 to the output
'of the FNOneColor function:
'
'DEF FNOneColor% (FG, BG) = FG + 16 * BG + 128
'                                        ^^^^^

DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DEF FNOneColor% (FG, BG) = FG + 16 * BG           'combine 2 colors to 1
DEF FnPad$ (X$) = SPACE$((7 - LEN(X$)) \ 2) + X$  'for centering
Display$ = SPACE$(5)                              'to align color numbers

CLS
DEF SEG = 0
IF PEEK(&H463) <> &HB4 THEN ColorMon = 1          'see what monitor is active

C$ = "Black; Blue; Green; Cyan; Red; Magenta; Brown; White; Gray"
DIM Colr$(8)                                      'the color names
FOR X = 0 TO 8                                    'read them ala READ/DATA
    Colr$(X) = PDQParse$(C$)
NEXT

PDQPrint "  Crescent Software Color Chart  ", 2, 23, 9

FOR BG = 0 TO 7
    LOCATE 5, 15 + BG * 8
    PRINT FnPad$(Colr$(BG))
    FOR FG = 0 TO 15
        LOCATE 7 + FG, 1
        IF FG <= 8 THEN
           PRINT Colr$(FG);
        ELSE
           PRINT "Bright "; Colr$(FG - 8);
        END IF
        RSET Display$ = STR$(FNOneColor%(FG, BG))
        PDQPrint Display$ + "  ", 7 + FG, BG * 8 + 15, FNOneColor%(FG, BG)
    NEXT
NEXT

PDQPrint "0", 7, 19, 7
IF ColorMon THEN
   Grey = 8
ELSE
   Grey = 7
END IF

PDQPrint "8", 15, 19, Grey

LOCATE 24, 10
PRINT "Press any key to end, or Shift-PrtSc to create a print out. ";
WHILE INKEY$ = "": WEND

