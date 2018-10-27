'********** CDIR.BAS - directory changing utility

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS

CONST LastRow% = 25                'lowest row for use by the display
MemSeg = AllocMem%(LastRow% * 32)  'claim DOS memory for saving the screen
IF ERR THEN END                    'if an error occurs end

CONST MaxDirs% = 500            'specify the maximum number of directory names
DIM Array$(1 TO MaxDirs%)       'create an array to hold the directory names
FOR X = 1 TO MaxDirs%           'initialize each element to 12 spaces
    Array$(X) = SPACE$(12)
NEXT

DIM DTA AS STRING * 44          'this will serve as a file DTA
Spec$ = "*.*" + CHR$(0)         'this matches all directory names

DEF SEG = 0                     'see what type of monitor is installed
IF PEEK(&H463) = &HB4 THEN      'by looking in low memory
   VideoSeg = &HB000            'monochrome
ELSE
   VideoSeg = &HB800            'color
END IF
DEF SEG                         'restore the segment for PEEKing the DTA below


'----- This function updates the display screen.
'
DEF FNDraw% (StartEl, BotRow)
    STATIC Row
    FOR Row = 1 TO BotRow
        IF Row = 1 THEN
           PDQPrint "ษออออออออออออออป", Row, 1, 112
        ELSEIF Row = BotRow THEN
           PDQPrint "ศออออออออออออออผ", Row, 1, 112
        ELSE
           PDQPrint "บ " + Array$(StartEl + Row - 2) + " บ", Row, 1, 112
        END IF
    NEXT
END DEF


'----- This function saves the underlying screen.
'
DEF FNScrnSave% (ULRow, ULCol, LRRow, LRCol)    'saves the underlying screen

    STATIC MemAdr, VideoAdr, NumBytes, X
    NumBytes = 2 * (LRCol - ULCol + 1)          'calculate number of bytes/row

    FOR X = ULRow - 1 TO LRRow - 1              'walk through video memory
        MemAdr = NumBytes * (X - ULRow + 1)     'and the offset into the array
        VideoAdr = X * 160 + 2 * (ULCol - 1)    'and the screen address
        '----- the following enables CGA snow checking at the expense of speed
        'IF VideoSeg = &HB800 THEN              'color, might be CGA
        '   DO                                  'wait for the start of the
        '   LOOP UNTIL INP(&H3DA) AND 8         '  vertical retrace interval
        'END IF
        CALL BlockCopy(VideoSeg, VideoAdr, MemSeg, MemAdr, NumBytes)
    NEXT

END DEF


'----- This function restores the underlying screen.
'
DEF FnScrnRest% (ULRow, ULCol, LRRow, LRCol)    'restores application screen

    STATIC MemAdr, VideoAdr, NumBytes, X
    NumBytes = 2 * (LRCol - ULCol + 1)          'calculate number of bytes/row

    FOR X = ULRow - 1 TO LRRow - 1              'step through the array
        MemAdr = NumBytes * (X - ULRow + 1)     'and the offset into the array
        VideoAdr = X * 160 + 2 * (ULCol - 1)    'and the video address
        '----- the following enables CGA snow checking at the expense of speed
        'IF VideoSeg = &HB800 THEN              'color, might be CGA
        '   DO                                  'wait for the start of the
        '   LOOP UNTIL INP(&H3DA) AND 8         '  vertical retrace interval
        'END IF
        CALL BlockCopy(MemSeg, MemAdr, VideoSeg, VideoAdr, NumBytes)
    NEXT
 
END DEF


'This function reads the directory names into the string array.
'
DEF FnLoadDirs%
    STATIC Count                'this will track the accumulated count
    STATIC X, Char              'work variables
    Count = 0                   'assume zero matching files

    Registers.AX = &H1A00       'set DTA service (Registers is in PDQDECL.BAS)
    Registers.DX = VARPTR(DTA)  'use the fixed-length string for this
   'Registers.DS = -1           'add this to run within QBX (BASIC 7)
   'in QBX change the Interrupt call below to instead call InterruptX
    CALL Interrupt(&H21, Registers)     'call DOS to set the DTA

    Registers.CX = 19           'the attribute for all directory types
    Registers.AX = &H4E00       'find first matching file (directory) service
    Registers.DX = SADD(Spec$)
   'Registers.DS = SSEG(Spec$)  'add this to run within QBX

    DO
     'in QBX change the Interrupt call below to instead call InterruptX
      CALL Interrupt(&H21, Registers)           'call DOS
      IF Registers.Flags AND 1 THEN EXIT DO     'carry set means no more
      IF PEEK(VARPTR(DTA) + 21) = 16 THEN       'if it really was a directory
         'and the name isn't a single "." character (this subdirectory)
         IF PDQPeek2%(VARPTR(DTA) + 30) <> &H2E THEN
            Count = Count + 1                   'we found another one
            LSET Array$(Count) = ""             'clear out any old contents
            FOR X = 30 TO 30 + 11               'copy the name to the array
                Char = PEEK(VARPTR(DTA) + X)    'get the current character
                IF Char = 0 THEN EXIT FOR       'a zero byte marks the end
                MID$(Array$(Count), X - 29, 1) = CHR$(Char)  'else insert it
            NEXT
         END IF
      END IF
      Registers.AX = &H4F00                     'find next matching file
    LOOP WHILE Count < MaxDirs%                 'but not more than MaxDirs%

    FnLoadDirs% = Count                         'assign the function output

END DEF

Dummy = FNScrnSave%(1, 1, LastRow%, 16) 'save the underlying screen
CursorOff                               'turn the cursor off
BotRow = LastRow%                       'assume LastRow% - 2 directory names
                                        '  (23 if LastRow% is set to 25)
DO
   TopEl = 1                            'first element at the top initially
   CurEl = TopEl                        'make that the current element too
   NumDirs = FnLoadDirs%                'count and load the directory names
   BotRow = NumDirs + 2                 'set the lower row for the display
   IF BotRow > LastRow% THEN BotRow = LastRow%  'enforce a legal display

   DO
      IF CurEl < TopEl THEN TopEl = CurEl               'force a scroll
      IF CurEl > TopEl + (LastRow% - 3) THEN TopEl = CurEl - (LastRow% - 3)
      Dummy = FNDraw%(TopEl, BotRow)                    'display directories
      PDQPrint Array$(CurEl), CurEl - TopEl + 2, 3, 7   'highlight top element

      DO
         KeyHit = PDQInkey%             'wait for a keypress
      LOOP UNTIL KeyHit

      SELECT CASE KeyHit                'see which key they pressed
         CASE 27                        'Escape
            EXIT DO                     'exit this inner loop

         CASE 13                        'Enter
            CHDIR RTRIM$(Array$(CurEl)) 'change to the selected directory
            EXIT DO                     'and exit this inner DO loop

         CASE -72                       'Cursor Up
            IF CurEl > 1 THEN CurEl = CurEl - 1

         CASE -80                       'Cursor Down
            IF CurEl < NumDirs THEN CurEl = CurEl + 1

         CASE -71                       'Home
            CurEl = 1

         CASE -79                       'End
            CurEl = NumDirs

         CASE ELSE                      'ignore anything else
      END SELECT
   LOOP
  
   Dummy = FnScrnRest%(1, 1, LastRow%, 16)      'restore the original screen
   IF KeyHit = 27 THEN EXIT DO                  'clean up and end if Escape

LOOP

Dummy = ReleaseMem%(MemSeg)             'release the memory
CursorOn                                'turn the cursor back on

