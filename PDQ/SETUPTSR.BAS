'********** SETUPTSR.BAS - TSR version of the P.D.Q. SetUp program

'Copyright (c) 1989 Ethan Winer

'This program must be compiled before it may be run.


'To take as little DOS memory as possible when this program is installed as
'a TSR, you should link it with the STR00512 and other stub files as follows:
'
'    BC SETUPTSR /O;
'    LINK /NOD /NOE SETUPTSR STR00512 _NOVAL _NOREAD, , NUL, PDQ;


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType                'RegType is defined in PDQDECL.BAS

CONST NumCodes% = 5                     'this forces the arrays to be Static
DIM Choice$(1 TO NumCodes%)
DIM Code$(1 TO NumCodes%)

Choice$(1) = " 1) Compressed printing "   'prompt messages
Choice$(2) = " 2) Enhanced printing   "
Choice$(3) = " 3) Tiny printing       "
Choice$(4) = " 4) Reset               "
Choice$(5) = " 5) Quit                "

Code$(1) = "@"                        'these codes were entered with Ctrl-P
Code$(2) = "@EG"                     'this is much more efficient than
Code$(3) = "@S13"                   'Code$(x) = CHR$(27) + "@" + ...
Code$(4) = "@"

DEF SEG = 0
IF PEEK(&H463) = &HB4 THEN
   ScreenSeg = &HB000                   'monochrome
ELSE
   ScreenSeg = &HB800                   'color
END IF

CONST WindowSize% = 24 * 6 * 2          'the size of the screen being saved
ArraySeg = AllocMem%(WindowSize)        'this holds the underlying screen


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


DEF FnBIOSPrint% (Character)
    FnBIOSPrint% = 0                    'assume no errors
    Registers.AX = Character            'put the character into AL, 0 into AH
    Registers.DX = 0                    'specify LPT1: (use 1 for LPT2: etc.)
    CALL Interrupt(&H17, Registers)     'call the BIOS printer service
    AH = Registers.AX \ 256             'get the error result from AH
    AH = AH OR 128                      'ignore the busy flag
    AH = AH AND 191                     'ditto for the printer acknowledgement
    IF AH <> 144 THEN FnBIOSPrint% = -1 'printer isn't ready or it's off-line
END DEF


ID$ = "SetUp (c) 1989 Crescent Software - press Alt-S to activate"
CALL PDQPrint(ID$, CSRLIN, POS(0), 10)

CALL PopUpHere(&H81F, ID$)              'install as a TSR
GOTO OutaHere                           'skip over the hot-key handler
10                                      'this line number is needed for VB/DOS

Dummy = FnScrnSave%(1, 57, 6, 80)
FOR X = 1 TO NumCodes%                  'print the prompts
    CALL PDQPrint(Choice$(X), X, 57, 48)
NEXT
CALL PDQPrint(" Enter your selection:  ", 6, 57, 48)

DO                                      'wait for a keypress
   Which = BIOSInkey% - 48
LOOP UNTIL Which > 0 AND Which < NumCodes + 1
CALL PDQPrint(STR$(Which), 6, 79, 48)   'echo the choice to the screen

FOR X = 1 TO LEN(Code$(Which))          'send the selected code to the printer
    Char = ASC(MID$(Code$(Which), X))   'get this character
    PrnError = FnBIOSPrint%(Char)
    IF PrnError THEN                    'the printer wasn't ready or something
       CALL PDQSound(500, 2)            'make a beep sound
       EXIT FOR                         'skip the rest of the string
    END IF
NEXT

Dummy = FnScrnRest%(1, 57, 6, 80)       'restore the screen
CALL PopDown                            'return to the underlying application

OutaHere:
CALL EndTSR(ID$)                        'terminate and stay resident

