'********* DEMOEGA.BAS - demonstrates EGA/VGA graphics with P.D.Q.

'Copyright 1990 Crescent Software
'written by Jay Munro

DEFINT A-Z

DECLARE SUB EGABox (ULRow, ULCol, LRRow, LRCol, Colr, Style)
DECLARE SUB EGADot (X, Y, Colr)
DECLARE SUB EGAEllipse (X, Y, RadiusWide, RadiusHigh, Colr)
DECLARE SUB EGALine (X0, Y0, X1, Y1, Colr)
DECLARE SUB EGAPrint (X$, Colr)
DECLARE FUNCTION PDQRand% (Limit)

SCREEN 9                                'set to graphics mode, use 12 for VGA

'For SCREEN 12 see the comments in EGADOT.BAS and EGALINE.BAS as well.

FOR I = 1 TO 3600                       'plot some random dots
    X = PDQRand%(639)                   'the X position
    Y = PDQRand%(350)                   'the Y position
    Z = PDQRand%(15)                    'the color to use
    CALL EGADot(X, Y, Z)
NEXT

FOR X = 10 TO 100 STEP 10               'draw some nested boxes
    CALL EGABox(200 - (15 + X), 100 + X, 200 - (30 + X), 110 + X + X, X \ 20, 1)
NEXT X


CALL EGABox(45, 180, 80, 380, 12, 2)    'make a box for text

FOR X = 48 TO 77                        'clear the box
    CALL EGALine(183, X, 377, X, 0)     'change 0 to fill the box with color
NEXT X

'----- After drawing lines and plotting dots, we must reset the EGA registers
'      before text printing will work correctly.

Text$ = "P.D.Q. Graphics Lives!"        'create a string
LOCATE 5, 25
CALL EGAPrint(Text$, 13)                'and print it

FOR X = 20 TO 320 STEP 20               'draw some lines
    CALL EGALine(10 + X, 10 + X, 630, 350 - X, X \ 20)
NEXT X

'---- Globes
FOR X = 1 TO 30 STEP 3                  'plot some ellipses
    CALL EGAEllipse(70, 200, 50 - X * 2, 40, 9)
NEXT

FOR X = 1 TO 30 STEP 3
    CALL EGAEllipse(70, 200, 50, 40 - X * 2, 9)
NEXT

FOR X = 1 TO 30 STEP 3
    CALL EGAEllipse(470, 100, 50 - X * 2, 40, 13)
NEXT

FOR X = 1 TO 30 STEP 3
    CALL EGAEllipse(470, 100, 50, 40 - X * 2, 13)
NEXT

FOR X = 20 TO 360 STEP 20                   'more lines
    CALL EGALine(70, 200, 10 + X, 350, X \ 20)
NEXT

LOCATE 25, 65
CALL EGAPrint("Press any key", 7)
WHILE INKEY$ = "": WEND
SCREEN 0

