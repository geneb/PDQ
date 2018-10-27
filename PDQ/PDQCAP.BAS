'**************  PDQCAP.BAS - all-mode screen capture TSR program

'   Copyright (c) 1991 Crescent Software
'   Written by Nash Bly
'
'   PDQCAP is a simplified PopUp TSR whose Hot Key is Alt-S.  It captures
'   Text, Hercules, CGA, EGA and VGA screens, saving them with BLOAD files.
'   When the hot key is pressed, the top line of the screen is saved in
'   memory and a file name prompt is given.  Users enter a file name without
'   an extension.  The screen is then restored and saved to disk.
'
'   Critical error handling is disabled before any file operations take place
'   and re-enabled after they are complete.  This is important within a TSR
'   because improper return of control may result from the DOS critical error
'   handler.
'
'   PDQCAP must be compiled to disk before it can be run:
'
'   BC PDQCAP /O;
'   LINK /NOD/NOE/EX/FAR/PACKC +
'     PDQCAP _NOERROR _NOREAD _NOVAL _PDQVAL STR01024 ,, NUL, SMALLDOS PDQ
'
'   Text and CGA screens are saved in a single file with an ".SCR" extension.
'   EGA and VGA screens are saved with four files, one for each of the video
'   planes.  The extensions of these files correspond to the video plane from
'   which they were saved (BLU, RED, GRN, INT).
'
'   For each screen that is saved, a file with the extension ".VID" is also
'   written to disk.  This file contains information about the screen which
'   is needed when redisplaying it.  The first line in this file contains the
'   screen mode that was active when the screen was captured.  If the screen
'   mode is 0 (text screen) then the file will have two more lines, the
'   number of rows, and the number of columns on the screen.
'
'   The "VID" file holds additional information for EGA and VGA screen modes
'   representing the palette data.  A character 26 (End Of File) separates
'   the text data from the binary palette data.  Values for the palette
'   registers are saved for EGA and VGA screens.  Values for the DAC registers
'   and mode control registers are also included for VGA screens.

'   Please see the SCRNSHOW demonstration program for the correct methods to
'   display the screens saved with PDQCAP.


DEFINT A-Z

'-------- Declare P.D.Q. extensions

DECLARE FUNCTION AllocMem% (NumBytes)
DECLARE FUNCTION BIOSInkey% ()
DECLARE FUNCTION CursorSave& ()
DECLARE FUNCTION PDQPeek2% (Address)
DECLARE FUNCTION PDQValI% (Text$)
DECLARE FUNCTION PopDeinstall% (Segment, ID$)
DECLARE FUNCTION TSRInstalled% (ID$)
DECLARE SUB BlockCopy (FromSeg, FromAdr, ToSeg, ToAdr, NumBytes)
DECLARE SUB CritErrOff ()
DECLARE SUB CritErrOn ()
DECLARE SUB CursorRest (CursorMem&)
DECLARE SUB EndTSR (ID$)
DECLARE SUB InterruptX (IntNumber, Registers AS ANY)
DECLARE SUB PDQPoke2 (Address, Value)
DECLARE SUB PDQSound (Freq, Duration)
DECLARE SUB PopDown ()
DECLARE SUB PopUpHere (HotKey, ID$)

'-------- Initialize TYPE variable for CALL INTERRUPT

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

DIM Registers AS RegType                        'used for call interrupt
DIM PAL AS STRING * 17                          '17 byte palette buffer
DIM DAC AS STRING * 768                         '768 VGA DAC register buffer
DIM RAMTable(1 TO 14)                           '28 byte table of 7 pointers
DIM RAMArea(1 TO 128)                           '256 byte area of EGA data

'-------- Start of Execution

    ID$ = "PDQCAP 1.10 Copyright (c) 1991 Crescent Software"
    PRINT ID$                                   'always assign ID$ first
   
    EGASeg = &HA000                             'an often-used integer
    EOF$ = CHR$(26)                             'and string character
    Pointer = &H4A8                             'locates a ROM pointer table

'-------- Install, UnInstall, and Help

    Segment = TSRInstalled%(ID$)                'get the installed segment
                                              
    Switch$ = UCASE$(COMMAND$)                  'get command line switch
    IF LEN(Switch$) = 0 THEN                    'if no switch then install
        IF Segment <> 0 THEN                    'if already installed then
            PRINT "PDQCAP is already installed" 'display a message and
            PRINT "Use PDQCAP /U to uninstall"  'uninstall instructions
            PRINT "Press Alt-S to pop up."
            END                                 'then end
        END IF
    ELSEIF Switch$ = "/U" THEN                  'if uninstall switch then
        IF Segment THEN                         'if the segment is not 0 then
            DEF SEG = Segment                   'look in segment of TSR
            ROMAdd = PDQPeek2%(VARPTR(ROMAdd))  'get ROM table address
            ROMSeg = PDQPeek2%(VARPTR(ROMSeg))  'which was saved on install
            DEF SEG = 0                         'switch to low mem
            PDQPoke2 Pointer, ROMAdd            'change pointer back to
            PDQPoke2 Pointer + 2, ROMSeg        'original ROM address
            Success = PopDeinstall(Segment, ID$)'attempt deinstallation
            IF Success THEN                     'if successful then display
                PRINT "PDQCAP removed from memory"         'a success message
            ELSE                                           'otherwise display
                PRINT "Error uninstalling - please reboot" 'an error message
            END IF                                         'if not installed
        ELSE                                               'display a message
            PRINT "PDQCAP is not resident"
        END IF                                             'and end
        END
    ELSE                                               'if any other switch
        PRINT "PDQCAP - usage:    Install - PDQCAP"    'then display a help
        PRINT "                 UnInstall - PDQCAP /U" 'message for user
        END                                            'and end
    END IF

'-------- Initialize storage for temporary screen save

    ArraySize = 2560                        'memory required to save one line
    BlueSeg = AllocMem%(ArraySize)          'in VGA screen mode 13
    GreenSeg = AllocMem%(ArraySize)         'more than enough for other
    RedSeg = AllocMem%(ArraySize)           'screen modes.  Need four planes
    IntenSeg = AllocMem%(ArraySize)         'for EGA and VGA screens.

'-------- Setup means to read EGA palette

    DEF SEG = 0                                 'get ready to peek low mem
    ROMAdd = PDQPeek2%(Pointer)                 'get ROM table address
    ROMSeg = PDQPeek2%(Pointer + 2)             'get ROM table segment

    RAMAdd = VARPTR(RAMTable(1))                'get RAM table address
    RAMSeg = VARSEG(RAMTable(1))                'get RAM table segment

    BlockCopy ROMSeg, ROMAdd, RAMSeg, RAMAdd, 28'copy ROM table to RAM table

    RAMTable(3) = VARPTR(RAMArea(1))            'set pointer in our RAM table
    RAMTable(4) = VARSEG(RAMArea(1))            'to the RAM area for EGA data

    PDQPoke2 Pointer, RAMAdd                    'change low mem pointer to
    PDQPoke2 Pointer + 2, RAMSeg                'to our new RAM table

    PRINT "PDQCAP is Resident in Memory"        'print installation message
    PRINT "Press Alt-S to pop up."

'-------- Setup hot key and TSR entry point

    HotKey = &H81F                          'Alt-S is the Hot Key
    PopUpHere HotKey, ID$                   'set the Hot Key entry point
    GOTO EndIt                              'jump to finish installation
10                                     'this line number is needed for VB/DOS

'-------- Determine the video mode          'start of resident program

    Registers.AX = &HF00                    'AH = Service 0Fh, Get Video Mode
    CALL InterruptX(&H10, Registers)        'BIOS Video Interrpt 10H
    VideoMode = Registers.AX MOD 256        'AL returns BIOS video mode

'-------- Save a one-line window and save some screen info

    MonSeg = &HB800                             'assume CGA color segment
    SELECT CASE VideoMode                       'video mode actions
    CASE 0 TO 3, 7                              'Text Screens
        IF VideoMode = 7 THEN MonSeg = &HB000   'fix segment if mono
        ScrnMode = 0                            'SCREEN 0
        NumBytes = 160                          'bytes to save for a window
        DEF SEG = 0                             'peek low memory for the
        NumCols = PEEK(&H44A)                   'number of screen columns
        NumRows = PEEK(&H484) + 1               'and the number of screen rows
        Size& = NumRows * NumCols * 2           'bytes to save entire screen
        BlockCopy MonSeg, Zero, BlueSeg, Zero, NumBytes   'save a window
    CASE 4, 5, 6                                'CGA Graphic Screens
        IF VideoMode = 6 THEN                   'if BIOS video mode is 6
            ScrnMode = 2                        'SCREEN 2
            NumBytes = 640                      'bytes to save for a window
        ELSE                                    'if BIOS video mode 4 or 5
            ScrnMode = 1                        'SCREEN 1
            NumBytes = 320                      'bytes to save for a window
        END IF                                  'save window, CGA interlaced
        BlockCopy MonSeg, Zero, BlueSeg, Zero, NumBytes   'so save twice with
        BlockCopy MonSeg, &H2000, GreenSeg, Zero, NumBytes'an 8K offset
    CASE 8                                      'Hercules Graphic Screen
        MonSeg = &HB000                         'mono hercules segment
        ScrnMode = 3                            'SCREEN 3
        NumBytes = 360                          'bytes to save for a window
        BlockCopy MonSeg, Zero, BlueSeg, Zero, NumBytes   'Herc is interlaced
        BlockCopy MonSeg, &H2000, GreenSeg, Zero, NumBytes'into 4 blocks so we
        BlockCopy MonSeg, &H4000, RedSeg, Zero, NumBytes  'save from 4 places
        BlockCopy MonSeg, &H6000, IntenSeg, Zero, NumBytes'with 8K offsets
    CASE 13                                     'EGA Graphic Screen
        ScrnMode = 7                            'SCREEN 7
        NumBytes = 320                          'bytes to save a window
        Size& = 8000                            'bytes to save entire screen
        GOTO EGASave                            'save window
    CASE 14                                     'EGA Graphic Screen
        ScrnMode = 8                            'SCREEN 8
        NumBytes = 640                          'bytes to save for a window
        Size& = 16000                           'bytes to save entire screen
        GOTO EGASave                            'save window
    CASE 15, 16                                 'EGA Graphic Screens
        IF VideoMode = 15 THEN                  'If BIOS video mode 15
            ScrnMode = 10                       'SCREEN 10
        ELSE                                    'if BIOS video mode 16
            ScrnMode = 9                        'SCREEN 9
        END IF
        NumBytes = 1120                         'bytes to save for a window
        Size& = 28000                           'bytes to save entire screen
        GOTO EGASave                            'save window
    CASE 17, 18                                 'VGA Graphic Screens
        IF VideoMode = 17 THEN                  'if BIOS video mode 17
            ScrnMode = 11                       'SCREEN 11
        ELSE                                    'if BIOS video mode 18
            ScrnMode = 12                       'SCREEN 12
        END IF
        NumBytes = 1280                         'bytes to save window
        Size& = 38400                           'bytes to save entire screen
        GOTO EGASave                            'save window
    CASE 19                                     'VGA Graphic Screen
        ScrnMode = 13                           'SCREEN 13
        NumBytes = 2560                         'bytes to save window
        Size& = 64000                           'bytes to save entire screen
        GOTO EGASave                            'save window
    CASE ELSE                                   'some new unsupported mode?
        GOTO PopDone                            'we do nothing
    END SELECT

'-------- Input file name

EnterName:
    CursorMem& = CursorSave&                        'save cursor postion
    LOCATE 1, 1                                     'locate at top of screen
    PRINT "Enter a name for the screen:  --------  "; 'display a prompt
    MaxLen = 8: Text$ = STRING$(MaxLen, 32)         'init edit parameters
    GOSUB UserInput                                 'input filename
    FileName$ = RTRIM$(Text$)                       'trim input name
    CursorRest CursorMem&                           'restore cursor postion

'-------- Restore window saved above

    SELECT CASE ScrnMode                            'the opposite of saving
    CASE 0                                          'the top screen line
        BlockCopy BlueSeg, Zero, MonSeg, Zero, NumBytes
    CASE 1, 2
        BlockCopy BlueSeg, Zero, MonSeg, Zero, NumBytes
        BlockCopy GreenSeg, Zero, MonSeg, &H2000, NumBytes
    CASE 3
        BlockCopy BlueSeg, Zero, MonSeg, Zero, NumBytes
        BlockCopy GreenSeg, Zero, MonSeg, &H2000, NumBytes
        BlockCopy RedSeg, Zero, MonSeg, &H4000, NumBytes
        BlockCopy IntenSeg, Zero, MonSeg, &H6000, NumBytes
    CASE 7 TO 13
        OUT &H3C4, 2: OUT &H3C5, 1
        BlockCopy BlueSeg, Zero, EGASeg, Zero, NumBytes
        OUT &H3C4, 2: OUT &H3C5, 2
        BlockCopy GreenSeg, Zero, EGASeg, Zero, NumBytes
        OUT &H3C4, 2: OUT &H3C5, 4
        BlockCopy RedSeg, Zero, EGASeg, Zero, NumBytes
        OUT &H3C4, 2: OUT &H3C5, 8
        BlockCopy IntenSeg, Zero, EGASeg, Zero, NumBytes
        OUT &H3C4, 2: OUT &H3C5, 15
    END SELECT

    IF Ky = 27 GOTO PopDone                         'exit if escape pressed
    IF LEN(FileName$) = 0 GOTO PopDone              'exit if no name given
    IF INSTR(FileName$, ".") GOTO PopDone           'exit if extension given

'-------- Save Screen to Disk

    CritErrOff                                      'disable crit err handling
    SELECT CASE ScrnMode                            'check screen mode
    CASE 0                                          'if text screen then
        DEF SEG = &HB800                            'assume color sement
        IF VideoMode = 7 THEN DEF SEG = &HB000      'fix segment if mono
        BSAVE FileName$ + ".SCR", Zero, Size&       'and save to disk
    CASE 1, 2                                       'if CGA screen
        DEF SEG = &HB800                            '16K is saved for CGA
        BSAVE FileName$ + ".SCR", Zero, &H4000      'from the proper segment
    CASE 3                                          'if hercules screen
        DEF SEG = &HB000                            'this is Herc segment
        BSAVE FileName$ + ".SCR", Zero, &H8000      'save 32K this time
    CASE 7 TO 13                                    'if EGA/VGA screen
        DEF SEG = EGASeg                            'EGA/VGA segment
        OUT &H3CE, 4: OUT &H3CF, 0: BSAVE FileName$ + ".BLU", Zero, Size&
        OUT &H3CE, 4: OUT &H3CF, 1: BSAVE FileName$ + ".GRN", Zero, Size&
        OUT &H3CE, 4: OUT &H3CF, 2: BSAVE FileName$ + ".RED", Zero, Size&
        OUT &H3CE, 4: OUT &H3CF, 3: BSAVE FileName$ + ".INT", Zero, Size&
        OUT &H3CE, 4: OUT &H3CF, 0                  'save all 4 planes
    CASE ELSE: END SELECT

'-------- Write a small file with screen mode and palette information

    OPEN FileName$ + ".VID" FOR OUTPUT AS #1    'start with a null file
    PRINT #1, "Screen Mode - "; ScrnMode        'write the screen mode text
    SELECT CASE ScrnMode                        'check the screen mode
    CASE 0                                      'if text screen then save
        PRINT #1, "Number of Rows - "; NumRows  'screen height and width
        PRINT #1, "Number of Columns - "; NumCols
    CASE 7 TO 10                                'if EGA screen
        PUT #1, , EOF$                          'put separator char in file
        FOR I = 1 TO 9                          'write 17 palette bytes plus
            PUT #1, , RAMArea(I)                'one extra byte doesn't matter
        NEXT
    CASE 11, 12, 13                             'add palette data for VGA
        PUT #1, , EOF$                          'put separator char in file

        Registers.AX = &H1009                   'read VGA palette registers
        Registers.ES = VARSEG(PAL)              'into a 17 byte buffer with
        Registers.DX = VARPTR(PAL)              'a BIOS video service using
        CALL InterruptX(&H10, Registers)        'InterruptX

        Registers.AX = &H1017                   'read VGA DAC registers
        Registers.BX = 0                        'into a 768 byte buffer
        Registers.CX = &H100
        Registers.ES = VARSEG(DAC)
        Registers.DX = VARPTR(DAC)
        CALL InterruptX(&H10, Registers)

        Registers.AX = &H101A                   'read VGA mode selection
        CALL InterruptX(&H10, Registers)        'register
        Mode = Registers.BX

        PUT #1, , PAL                           'write palette data to file
        PUT #1, , DAC                           'write DAC data
        PUT #1, , Mode                          'and select register data
    CASE ELSE: END SELECT
    CLOSE #1                                    'close the file

'-------- Return to underlying program

PopDone:

    CritErrOn                                   'enable crit err handling
    PopDown                                     'before returning

'-------- Exit but stay resident

EndIt:

    EndTSR ID$

'***************************************************************************
'*****************************  Subroutines  *******************************
'***************************************************************************

'-------- Save a portion of EGA/VGA Screen

EGASave:

    DEF SEG = EGASeg                                'set the proper segment
    OUT &H3CE, 4: OUT &H3CF, 0                      'and save the 4 planes
    BlockCopy EGASeg, Zero, BlueSeg, Zero, NumBytes 'of the top line to our
    OUT &H3CE, 4: OUT &H3CF, 1                      'memory storage area
    BlockCopy EGASeg, Zero, GreenSeg, Zero, NumBytes
    OUT &H3CE, 4: OUT &H3CF, 2
    BlockCopy EGASeg, Zero, RedSeg, Zero, NumBytes
    OUT &H3CE, 4: OUT &H3CF, 3
    BlockCopy EGASeg, Zero, IntenSeg, Zero, NumBytes
    OUT &H3CE, 4: OUT &H3CF, 0
    GOTO EnterName

'-------- Graphic Mode Keyboard Input

UserInput:

    LOCATE 1, 31                                    'locate at start of field
    Curpos = 1                                      'cursor position counter
    DO                                              'character input loop
        Ky = BIOSInkey%                             'get a key press
        SELECT CASE Ky                              'actions for the key press
        CASE 33 TO 126                              'if a normal key press
            IF Curpos <= MaxLen THEN                'if not past end of field
                MID$(Text$, Curpos, 1) = CHR$(Ky)   'add the char to string
                LOCATE , 30 + Curpos                'position the cursor
                PRINT CHR$(Ky);                     'print the character
                Curpos = Curpos + 1                 'increment cursor counter
            ELSE                                    'if past end of field
                PDQSound 2500, 2                    'sound a nice beep
            END IF
        CASE 8                                      'if key is backspace
            IF Curpos > 1 THEN                      'if not at start of field
                Curpos = Curpos - 1                 'decrement cursor counter
                MID$(Text$, Curpos, 1) = " "        'remove char from string
                LOCATE , 30 + Curpos                'position the cursor
                PRINT "-";                          'display a dash character
                LOCATE , 30 + Curpos                'reposition the cursor
            END IF
        CASE ELSE
        END SELECT                                  'loop until CR or ESC key
    LOOP UNTIL Ky = 13 OR Ky = 27
    RETURN

