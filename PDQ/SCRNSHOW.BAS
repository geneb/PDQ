'************ SCRNSHOW.BAS - screen retrieval demonstration

'   Copyright (c) 1991 Crescent Software
'   Written by Nash Bly

'   SCRNSHOW.BAS displays screens saved with the PDQCAP screen capture TSR.
'   The default directory is searched for files with a ".VID" extension.
'   Each screen associated with the VID files found is displayed one at a
'   time, with a keypress pause in betweeen.  The VID files contain screen
'   mode and palette information needed to prepare the computer for the
'   screen.

'   BASIC's SCREEN statement is used to set the video mode in all cases
'   except hercules graphics mode.  In this case, HercMode, a PDQ extension,
'   does the job without the need for MSHERC.COM.  Calling HercMode with any
'   non-zero argument will switch from text to Hercules graphics.  Using
'   zero as an argument will switch back.

'   SCRNSHOW must be compiled before it can be run:

'   BC SCRNSHOW /O;
'   LINK /NOD/NOE/EX/FAR/PACKC +
'     SCRNSHOW _NOERROR _NOREAD _NOVAL _PDQVAL, , NUL, SMALLDOS PDQ

DEFINT A-Z

'-------- PDQ Extensions

DECLARE FUNCTION PDQValI% (Text$)
DECLARE SUB BlockCopy (FromSeg, FromAdd, ToSeg, ToAdd, NumBytes)
DECLARE SUB HercMode (Mode)
DECLARE SUB Interrupt (IntNum, Registers AS ANY)
DECLARE SUB InterruptX (IntNum, Registers AS ANY)

'-------- Initialize TYPE variable used for call interrupt

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

'-------- Dimension Static Variables

DIM Registers AS RegType                    'used for call interrupt
DIM DTA AS STRING * 44                      'this will serve as a file DTA
DIM PAL AS STRING * 17                      'holds EGA/VGA palette data
DIM DAC AS STRING * 768                     'holds VGA DAC register data
 
'-------- Start of execution
  
    CLS                                     'clear the screen
    MaxNames = 25                           'no more then 25 screens in a show
    EOF$ = " "                              'helpful one character string
    Spec$ = "*.VID" + CHR$(0)               'spec for DOS file name search

    DIM FileName$(1 TO MaxNames)            'create an array to save the names
    FOR I = 1 TO MaxNames                   'and initialize each element
        FileName$(I) = SPACE$(12)           'to 12 spaces
    NEXT

'-------- Load archive files matching "*.VID" using CALL INTERRUPT

    Registers.AX = &H1A00                   'place DOS Set DTA service in AH
    Registers.DX = VARPTR(DTA)              'memory address to be used for DTA
    CALL Interrupt(&H21, Registers)         'call DOS to set the DTA

    Registers.CX = 32                       'the attribute for archive files
    Registers.AX = &H4E00                   'find first matching file service
    Registers.DX = SADD(Spec$)              'pass the spec$ address
    NumNames = 0                            'init count of names found
    DO
        CALL Interrupt(&H21, Registers)        'call DOS to fetch file name
        IF Registers.Flags AND 1 THEN EXIT DO  'carry set means no more
        NumNames = NumNames + 1                'add one to the count of names
        FOR X = 30 TO 30 + 11                  'copy the name to the array
            Char = PEEK(VARPTR(DTA) + X)       'get the current character
            IF Char = 0 THEN EXIT FOR          'a zero byte marks the end
            MID$(FileName$(NumNames), X - 29, 1) = CHR$(Char)  'else insert it
        NEXT
        Registers.AX = &H4F00               'find next matching file service
    LOOP WHILE NumNames < MaxNames          'but not more than MaxNames

'-------- Display each screen found
  
    FOR I = 1 TO NumNames                       'for each screen found

'-------- Read ".VID" file for screen mode and the number of rows and columns

        OPEN FileName$(I) FOR INPUT AS #1       'open the ".VID" file
        INPUT #1, Text$                         'read the first line
        ScrnMode = PDQValI%(MID$(Text$, 14))    'parse out the screen mode
        SELECT CASE ScrnMode                    'check the screen mode
        CASE 0                                  'if SCREEN 0 then
            INPUT #1, Text$                     'input the number of rows
            NumRows = PDQValI%(MID$(Text$, 18)) 'convert to a number
            INPUT #1, Text$                     'input the number of cols
            NumCols = PDQValI%(MID$(Text$, 21)) 'convert to a number
        CASE 7, 8, 9, 10                        'if EGA screen then
            GET #1, , EOF$                      'skip over separator char
            GET #1, , PAL                       'then read the palette info
        CASE 11, 12, 13                         'if VGA screen then
            GET #1, , EOF$                      'skip separator char
            GET #1, , PAL                       'read the palette information
            GET #1, , DAC                       'read the DAC register data
            GET #1, , Mode                      'and the mode select data
        CASE ELSE: END SELECT
        CLOSE #1                                'close the ".VID" file

'-------- Set the screen mode and DEF SEG to the screen segment

        IF ScrnMode = 3 THEN                    'if hercules screen then
           HercMode 3                           'set hecules screen mode
        ELSE                                    'any other screen mode
           SCREEN ScrnMode                      'use basic to set the mode
        END IF
        
        SELECT CASE ScrnMode                    'setup for proper screen
        CASE 0                                  'Text Screen
            WIDTH NumCols, NumRows              'set video rows and cols
            DEF SEG = 0                         'ready to peek low memory
            IF PEEK(&H463) = &HB4 THEN          'if screen is monochrome
                DEF SEG = &HB000                'set mono segment
            ELSE                                'if screen is color
                DEF SEG = &HB800                'set color segment
            END IF
            LOCATE , , 0                        'turn off cursor
        CASE 1, 2                               'CGA Graphic Screens
            DEF SEG = &HB800                    'CGA color segment
        CASE 3                                  'Herculese Graphic Screen
            DEF SEG = &HB000                    'set mono segment
        CASE ELSE                               'VGA Color / EGA Mono Screen
        END SELECT

'-------- Load and display associated screens
      
        FileName$ = LEFT$(FileName$(I), INSTR(FileName$(I), ".") - 1)
        IF ScrnMode < 7 THEN                    'text and CGA screens
            BLOAD FileName$ + ".SCR", Zero      'display with BLOAD
        ELSE                                    'for EGA/VGA screens
            SELECT CASE ScrnMode                'set screen size for mode
            CASE 7                              'EGA screens
                ScrnSize& = 8000
            CASE 8
                ScrnSize& = 16000
            CASE 9, 10
                ScrnSize& = 28000
            CASE 11, 12                         'VGA screens
                ScrnSize& = 38400
            CASE 13
                ScrnSize& = 64000
            CASE ELSE: END SELECT

            REDIM ScrnBuf(ScrnSize& \ 2)        'create a screen buffer
   
            IF ScrnSize& < 32767 THEN           'convert size to an integer
                Size = ScrnSize&
            ELSE
                Size = ScrnSize& - 65536
            END IF

            DEF SEG = VARSEG(ScrnBuf(0))        'set segment to screen buffer
                                                'and BLOAD each video plane
                                                'into the buffer then copy
                                                'from buffer into video memory

            BLOAD FileName$ + ".BLU", VARPTR(ScrnBuf(0))
            OUT &H3C4, 2: OUT &H3C5, 1
            BlockCopy VARSEG(ScrnBuf(0)), VARPTR(ScrnBuf(0)), &HA000, 0, Size
 
            BLOAD FileName$ + ".GRN", VARPTR(ScrnBuf(0))
            OUT &H3C4, 2: OUT &H3C5, 2
            BlockCopy VARSEG(ScrnBuf(0)), VARPTR(ScrnBuf(0)), &HA000, 0, Size

            BLOAD FileName$ + ".RED", VARPTR(ScrnBuf(0))
            OUT &H3C4, 2: OUT &H3C5, 4
            BlockCopy VARSEG(ScrnBuf(0)), VARPTR(ScrnBuf(0)), &HA000, 0, Size
 
            BLOAD FileName$ + ".INT", VARPTR(ScrnBuf(0))
            OUT &H3C4, 2: OUT &H3C5, 8
            BlockCopy VARSEG(ScrnBuf(0)), VARPTR(ScrnBuf(0)), &HA000, 0, Size
           
            OUT &H3C4, 2: OUT &H3C5, 15

            SELECT CASE ScrnMode                'set palette for screens
            CASE 7 TO 13                        'for EGA or VGA screens
                Registers.AX = &H1002           'set the palette registers
                Registers.ES = VARSEG(PAL)
                Registers.DX = VARPTR(PAL)
                CALL InterruptX(&H10, Registers)
                IF ScrnMode > 10 THEN           'for VGA screens
                    Registers.AX = &H1012       'also set DAC registers
                    Registers.BX = 0
                    Registers.CX = &H100
                    Registers.ES = VARSEG(DAC)
                    Registers.DX = VARPTR(DAC)
                    CALL InterruptX(&H10, Registers)

                    Bit7 = Mode AND &HFF        'and the mode select regist.
                    ColrSel = Mode AND &HFF00
                    Registers.AX = &H1013
                    Registers.BX = 0
                    IF Bit7 = 1 THEN Reg.BX = &H100
                    CALL Interrupt(&H10, Registers)

                    Registers.BX = ColrSel + 1
                    CALL Interrupt(&H10, Registers)
                END IF
            END SELECT

        END IF
        WHILE LEN(INKEY$) = 0: WEND             'wait for a key press
    NEXT

    IF ScrnMode = 3 THEN                        'if in hercules mode
       HercMode 0                               'set mode back to text
    ELSE                                        'if any other mode
       SCREEN 0                                 'use basic to set text mode
       LOCATE , , 1                             'and turn on the cursor
    END IF
    
    CLS

