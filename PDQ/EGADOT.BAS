'********** EGADOT.BAS - P.D.Q. dot plotting routine for EGA/VGA

'Copyright 1990 Crescent Software
'Written by Jay Munro

DEFINT A-Z
DECLARE SUB EGADot (X, Y, Colr)
DECLARE FUNCTION PDQShr% (BYVAL Value, BYVAL Places)

CONST ScrnWidth = 80                'row length
CONST ScrnSeg = &HA000              'display memory segment
CONST GXData = &H3CE

'NOTE: Change ScrnWidth to ScrnWidth& throughout if using VGA SCREEN 12 and
'      working in the QB environment.  Also, in that case you must change all
'      references to PixelBytePtr to PixelBytePtr& in this file.

SUB EGADot (X, Y, Colr)

    OUT &H3CE, 1
    OUT &H3CF, &HF
   
    OUT &H3CE, 0                        'select register for the color below
    OUT &H3CF, Colr                     'set color

    PixelBytePtr = (Y * ScrnWidth) + (X \ 8)
    PixelMask = PDQShr%(&H80, (X AND 7))
    OUT &H3CE, 8
    OUT &H3CF, PixelMask
    DEF SEG = ScrnSeg
    POKE PixelBytePtr, PEEK(PixelBytePtr) OR &HFF

    OUT &H3CE, 1
    OUT GXData, 0
    OUT &H3CE, 8
    OUT GXData, &HFF

END SUB

