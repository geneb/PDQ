'******** EGALINE.BAS - P.D.Q. line drawing routine for graphics EGA/VGA

'Copyright 1990 Crescent Software
'Written by Jay Munro

DEFINT A-Z
DECLARE FUNCTION PDQShr% (BYVAL Value, BYVAL Places)
DECLARE SUB EGALine (X0, Y0, X1, Y1, Colr)

CONST ScrnWidth = 80
CONST ScrnSeg = &HA000
CONST GXData = &H3CE

'NOTE: Change ScrnWidth to ScrnWidth& throughout if using VGA SCREEN 12 and
'      working in the QB environment.  Also, in that case you must change all
'      references to PixelBytePtr to PixelBytePtr& in this file.

SUB EGALine (TX0, TY0, TX1, TY1, Colr) STATIC

'---- P.D.Q. implementation of the Bresenham line drawing algorithm

    X0 = TX0                    'make copies of variables
    Y0 = TY0
    X1 = TX1
    Y1 = TY1

    OUT &H3CE, 0                'tell the EGA a color byte is coming
    OUT &H3CF, Colr            'set color
    OUT &H3CE, 1
    OUT &H3CF, &HF

    IF Y0 > Y1 THEN             'keep all lines going the same direction
       SWAP Y0, Y1
       SWAP X0, X1
    END IF

    DeltaX = X1 - X0            'figure length of line
    DeltaY = Y1 - Y0
   
    IF DeltaX > 0 THEN          'if length is greater
       XDirection = 1
       IF DeltaX > DeltaY THEN
          GOSUB Octant0
       ELSE
          GOSUB Octant1
       END IF
    ELSE
       XDirection = -1
       DeltaX = -DeltaX
       IF DeltaX > DeltaY THEN
          GOSUB Octant0
       ELSE
          GOSUB Octant1
       END IF
    END IF

    OUT &H3CE, 1
    OUT GXData, 0
    OUT &H3CE, 8
    OUT GXData, &HFF

EXIT SUB

Octant0:

    '---- (X0, Y0, DeltaX, DeltaY, XDirection)
    DeltaYx2 = DeltaY * 2
    DeltaYx2MinusDeltaXx2 = DeltaYx2 - (DeltaX * 2)
    ErrorTerm = DeltaYx2 - DeltaX
    GOSUB EvgaDot                          'draw first pixel

    WHILE DeltaX
      IF ErrorTerm >= 0 THEN
         Y0 = Y0 + 1
         ErrorTerm = ErrorTerm + DeltaYx2MinusDeltaXx2
      ELSE
         ErrorTerm = ErrorTerm + DeltaYx2
      END IF
      X0 = X0 + XDirection
      GOSUB EvgaDot
      DeltaX = DeltaX - 1
    WEND
RETURN

Octant1:
    '---- (X0,Y0,DeltaX,DeltaY,XDirection)
    DeltaXx2 = DeltaX * 2
    DeltaXx2MinusDeltaYx2 = DeltaXx2 - (DeltaY * 2)
    ErrorTerm = DeltaXx2 - DeltaY
    GOSUB EvgaDot                                'draw first dot

    WHILE DeltaY
      IF ErrorTerm >= 0 THEN
         X0 = X0 + XDirection
         ErrorTerm = ErrorTerm + DeltaXx2MinusDeltaYx2
      ELSE
         ErrorTerm = ErrorTerm + DeltaXx2
      END IF

      Y0 = Y0 + 1
      GOSUB EvgaDot
      DeltaY = DeltaY - 1
    WEND
RETURN

EvgaDot:
   PixelBytePtr = (Y0 * ScrnWidth) + (X0 \ 8)
   PixelMask = PDQShr%(&H80, (X0 AND 7))
   OUT &H3CE, 8
   OUT &H3CF, PixelMask
   DEF SEG = ScrnSeg
   POKE PixelBytePtr, PEEK(PixelBytePtr) OR &HFF
RETURN

END SUB

