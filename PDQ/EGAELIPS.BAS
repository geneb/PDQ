'********** EGAELIPS.BAS - P.D.Q. ellipse plotting routine for EGA/VGA

'Copyright 1990 Crescent Software
'Written by Jay Munro

DEFINT A-Z
DECLARE SUB EGAEllipse (X, Y, RadiusWide, RadiusHigh, Colr)
DECLARE SUB DrawDot (X, Y)

DECLARE FUNCTION PDQShl% (BYVAL Value, BYVAL Places)
DECLARE FUNCTION PDQShr% (BYVAL Value, BYVAL Places)

CONST ScrnWidth = 80
CONST ScrnSeg = &HA000

SUB DrawDot (X, Y)

    PixelBytePtr = (Y * ScrnWidth) + (X \ 8)
    PixelMask = PDQShr%(&H80, (X AND 7))
    OUT &H3CE, 8
    OUT &H3CF, PixelMask
    DEF SEG = ScrnSeg
    POKE PixelBytePtr, PEEK(PixelBytePtr) OR &HFF

END SUB

SUB EGAEllipse (X, Y, RadiusWide, RadiusHigh, Colr)

    OUT &H3CE, 0
    OUT &H3CF, Colr                    'set color
    OUT &H3CE, 1
    OUT &H3CF, &HF

    ASquared& = RadiusWide * RadiusWide
    BSquared& = RadiusHigh * RadiusHigh

    CALL DrawDot(X, Y + RadiusHigh)
    CALL DrawDot(X, Y - RadiusHigh)

    'draw four arcs
    WorkingX = 0
    WorkingY = RadiusHigh
    XAdjust& = 0
    YAdjust& = (ASquared& * 2) * RadiusHigh
    Threshold& = (ASquared& \ 4) - (ASquared& * RadiusHigh)
   
    DO
       Threshold& = Threshold& + XAdjust& + BSquared&
       IF Threshold& >= 0 THEN
          YAdjust& = YAdjust& - (ASquared& * 2)
          Threshold& = Threshold& - YAdjust&
          WorkingY = WorkingY - 1
       END IF
  
       XAdjust& = XAdjust& + BSquared& * 2
       WorkingX = WorkingX + 1

       IF XAdjust& >= YAdjust& THEN EXIT DO

       CALL DrawDot(X + WorkingX, Y - WorkingY)
       CALL DrawDot(X - WorkingX, Y - WorkingY)
       CALL DrawDot(X + WorkingX, Y + WorkingY)
       CALL DrawDot(X - WorkingX, Y + WorkingY)
    LOOP

    CALL DrawDot(X + RadiusWide, Y)
    CALL DrawDot(X - RadiusWide, Y)

    WorkingX = RadiusWide
    WorkingY = 0
    XAdjust& = BSquared& * 2 * RadiusWide
    YAdjust& = 0
    Threshold& = BSquared& \ 4 - BSquared& * RadiusWide

    DO
       Threshold& = Threshold& + YAdjust& + ASquared&
  
       IF Threshold& >= 0 THEN
          XAdjust& = XAdjust& - (BSquared& * 2)
          Threshold& = Threshold& - XAdjust&
          WorkingX = WorkingX - 1
       END IF

       YAdjust& = YAdjust& + ASquared& * 2
       WorkingY = WorkingY + 1

       IF YAdjust& >= XAdjust& THEN EXIT DO
  
       CALL DrawDot(X + WorkingX, Y - WorkingY)
       CALL DrawDot(X - WorkingX, Y - WorkingY)
       CALL DrawDot(X + WorkingX, Y + WorkingY)
       CALL DrawDot(X - WorkingX, Y + WorkingY)
    LOOP
  
    OUT &H3CE, 0
    OUT &H3CF, 0
    OUT &H3CE, 8
    OUT &H3CF, &HFF

END SUB

