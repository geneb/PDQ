'******** EGAPRINT.BAS - P.D.Q. graphics text printing routine for EGA/VGA

'Copyright 1990 Crescent Software
'Written by Jay Munro

DEFINT A-Z

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

DECLARE SUB EGAPrint (Text$, Colr)
DECLARE SUB Interrupt (IntNumber, Registers AS ANY)
DIM SHARED Registers AS RegType

SUB EGAPrint (X$, Colr) STATIC

    '----- After drawing lines and plotting dots, we must reset the EGA
    '      registers before text printing will work correctly.

    FOR X = 0 TO 5
        OUT &H3CE, X
        OUT &H3CF, 0
    NEXT

    OUT &H3CE, 7
    OUT &H3CF, &HF
    OUT &H3CE, 8
    OUT &H3CF, &HFF

    '--- now print the text at the current cursor position
   
    FOR X = 1 TO LEN(X$)
        Registers.AX = (&HE * 256) + ASC(MID$(X$, X, 1))  'service/char in AX
        Registers.BX = Colr                               'color in BL
        CALL Interrupt(&H10, Registers)                   'Int 10h is video
    NEXT X

END SUB

