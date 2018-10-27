'********** DEFFN.BAS - a collection of some useful DEF FN-style functions

'Copyright (c) 1989 Ethan Winer


'This file contains a variety of useful functions and subroutines in the
'form of DEF FN-style functions.  Use them as is, or modify them to suit
'your program's requirements.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'
DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS


'----- combine foreground and background colors into one byte for PDQPrint
'
DEF FnOneColor% (FG, BG) = (FG AND 16) * 8 + ((BG AND 7) * 16) + (FG AND 15)
'
'Example: MyColor = FnOneColor%(Foreground, Background)
'         CALL PDQPrint(Work$, Row, Column, MyColor)



'----- send a character to the printer through the BIOS
'
DEF FnBIOSPrint% (Character)
    FnBIOSPrint% = 0                    'assume no errors
    Registers.AX = Character            'put the character into AL, 0 into AH
    Registers.DX = 0                    'specify LPT1: (use 1 for LPT2: etc.)
    Interrupt &H17, Registers           'call the BIOS printer service
    AH = Registers.AX \ 256             'get the error result from AH
    AH = AH OR 128                      'ignore the busy flag
    AH = AH AND 191                     'ditto for the printer acknowledgement
    IF AH <> 144 THEN FnBIOSPrint% = -1 'printer isn't ready or it's off-line
END DEF
'
'Example: Work$ = "Send me to the printer"
'         FOR X = 1 TO LEN(Work$)
'             Failed = FnBIOSPrint%(ASC(MID$(Work$, X, 1)))
'             IF Failed THEN EXIT FOR
'         NEXT
'         IF Failed THEN PRINT "The printer is broke or turned off"




'----- save and restore the text-mode display screen (windowing)
'
DEF FnPDQScrnSave% (ULRow, ULCol, LRRow, LRCol)

    STATIC ArraySeg, ArrayAdr, VideoSeg, VideoAdr, NumBytes, X

    DEF SEG = 0
    IF PEEK(&H463) = &HB4 THEN
       VideoSeg = &HB000                'monochrome
    ELSE
       VideoSeg = &HB800                'color
    END IF

    ArraySeg = AllocMem%(2 * (LRRow - ULRow + 1) * (LRCol - ULCol + 1))
    IF ArraySeg THEN                            'ensure successful allocation
       FOR X = ULRow - 1 TO LRRow - 1           'walk through video memory
           NumBytes = 2 * (LRCol - ULCol + 1)   'calculate bytes/row
           ArrayAdr = NumBytes * (X - ULRow + 1)'and the offset into the array
           VideoAdr = X * 160 + 2 * (ULCol - 1) 'and the screen address
         
           '-- the following enables CGA snow checking at the expense of speed
           'IF VideoSeg = &HB800 THEN           'color, might be CGA
           '   DO                               'wait for the start of the
           '   LOOP UNTIL INP(&H3DA) AND 8      '  vertical retrace interval
           'END IF
           BlockCopy VideoSeg, VideoAdr, ArraySeg, ArrayAdr, NumBytes
       NEXT
    END IF

    FnPDQScrnSave% = ArraySeg   'return the array segment for FnPDQScrnRest

END DEF

DEF FnPDQScrnRest% (ArraySeg, ULRow, ULCol, LRRow, LRCol)

    STATIC ArrayAdr, VideoSeg, VideoAdr, NumBytes, X

    DEF SEG = 0
    IF PEEK(&H463) = &HB4 THEN
       VideoSeg = &HB000                'monochrome
    ELSE
       VideoSeg = &HB800                'color
    END IF

    IF ArraySeg THEN                            'don't copy from Segment 0
       FOR X = ULRow - 1 TO LRRow - 1           'step through the array
           NumBytes = 2 * (LRCol - ULCol + 1)   'calculate bytes/row
           ArrayAdr = NumBytes * (X - ULRow + 1)'and the offset into the array
           VideoAdr = X * 160 + 2 * (ULCol - 1) 'and the video address
           '-- the following enables CGA snow checking at the expense of speed
           'IF VideoSeg = &HB800 THEN           'color, might be CGA
           '   DO                               'wait for the start of the
           '   LOOP UNTIL INP(&H3DA) AND 8      '  vertical retrace interval
           'END IF
           BlockCopy ArraySeg, ArrayAdr, VideoSeg, VideoAdr, NumBytes
       NEXT
    END IF
  
    FnPDQScrnRest% = ReleaseMem%(ArraySeg)      'return ReleaseMem's success
   
END DEF
'
'Example: (the two preceding functions are meant to be used together)
'         ArraySeg = FnPDQScrnSave%(ULRow, ULCol, LRRow, LRCol)
'         Dummy = FnPDQScrnRest%(ArraySeg, ULRow, ULCol, LRRow, LRCol)
