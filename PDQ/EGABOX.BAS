'********** EGABOX.BAS - P.D.Q. graphics box drawing routine for EGA/VGA

'Copyright 1990 Crescent Software
'Written by Jay Munro

DEFINT A-Z
DECLARE SUB EGABox (ULRow, ULCol, LRRow, LRCol, Colr, Style)
DECLARE SUB EGALine (X0, Y0, X1, Y1, Colr)

SUB EGABox (ULRow, ULCol, LRRow, LRCol, Colr, Style)

    '--- Style: 1 = one-line box, 2 = two-line box

    CALL EGALine(ULCol, ULRow, LRCol, ULRow, Colr)          'top line
    CALL EGALine(ULCol, ULRow, ULCol, LRRow, Colr)          'left side
    CALL EGALine(LRCol, ULRow, LRCol, LRRow, Colr)          'right side
    CALL EGALine(ULCol, LRRow, LRCol, LRRow, Colr)          'bottom

    '--- if two-line then do another box

IF Style > 1 THEN
   CALL EGALine(ULCol + 2, ULRow + 2, LRCol - 2, ULRow + 2, Colr) 'top line
   CALL EGALine(ULCol + 2, ULRow + 2, ULCol + 2, LRRow - 2, Colr) 'left side
   CALL EGALine(LRCol - 2, ULRow + 2, LRCol - 2, LRRow - 2, Colr) 'right side
   CALL EGALine(ULCol + 2, LRRow - 2, LRCol - 2, LRRow - 2, Colr) 'bottom
END IF

END SUB

