'********* DISPLAY.BAS - creates a "self-running" text file reading program

'Copyright (c) 1991 Ethan Winer


'This program will not work in the QB editing environment!
'
'For the smallest size possible compile and link as follows:
'
'  bc display /o;
'  link /nod/noe/far/packc display _noval _noread _noerror , , nul, pdq
'
'You can optionally run this through EXE2COM:
'
'  exe2com display
'
'Then append the text file to be displayed using /b like this:
'
'  copy display.exe /b + textfile.ext runme.exe
'
'If you used EXE2COM then of course do it like this instead:
'
'  copy display.com /b + textfile.ext runme.exe
'
'Note that this program cannot be used if compiled and linked for CodeView.


DEFINT A-Z
DECLARE FUNCTION ScreenHeight% ()       'so we know when to display "more"

'$INCLUDE: 'PDQDECL.BAS'

DIM SHARED Regs AS RegType              'needed for CALL INTERRUPT below


'-- Find this program's name so we can open it to read the appended text.
'
IF DOSVer% < 300 THEN                   'DOS service &H62 requires DOS 3.0 +
  PRINT "Sorry, DOS 3.0 or later required"
  END
END IF

Regs.AX = &H6200                        'service &H62 returns the PSP segment
CALL Interrupt(&H21, Regs)              'call DOS to do the hard stuff
DEF SEG = Regs.BX                       'we need to PEEK this segment
DEF SEG = PDQPeek2%(&H2C)               'address &H2C = environment segment

'Address = 0                            'not necessary, shown for clarity
DO                                      'walk the environment looking for two
  Address = Address + 1                 '  null bytes in a row
LOOP UNTIL PEEK(Address) = 0 AND PEEK(Address + 1) = 0
                                      
Address = Address + 4                   'skip over two nulls + length word

DO                                      'the program's name follows the nulls
  Char = PEEK(Address)
  IF Char = 0 THEN EXIT DO              'and it too is null-terminated
  Address = Address + 1
  MySelf$ = MySelf$ + CHR$(Char)        'build the program's name
LOOP


'-- Open ourself, find the logical end (past the .EXE code), and seek there.
'
OPEN MySelf$ FOR BINARY AS #1           'open this program file
SEEK #1, 3                              'skip over the "MZ" .EXE signature
GET #1, , LastPage                      'read the size of the last page
GET #1, , NumPages                      'and number of full 512-byte pages

IF LastPage THEN NumPages = NumPages - 1'NumPages includes LastPage, adjust
SEEK #1, NumPages * 512 + LastPage + 1  'this is where the text data begins
PRINT                                   'kick out an extra blank line


'-- Determine the screen boundaries, read the appended text, and display it.
'
Cute$ = " "                           'CHR$(8) + " " + CHR$(8) (to be cute)
ScrnHeight = ScreenHeight%              'see how many lines the screen holds
ScrnWidth = PDQPeek2%(&H44A)            'counts on DEF SEG in ScreenHeight!
'NumLines = 0                           'not necessary, shown for clarity

DO                                      'now read the appended text
  LINE INPUT #1, Text$                              'read a line
  NumLines = NumLines + LEN(Text$) \ ScrnWidth + 1  'accommodate long lines
  IF NumLines >= ScrnHeight - 1 THEN
    PRINT "more... ";                   'display "more..." as necessary
    WHILE BIOSInkey% = 0: WEND          'wait for a keypress
    FOR X = 1 TO 8                      'erase the "more..." prompt
      PRINT Cute$;
      CALL Pause(1)
    NEXT
    NumLines = 0                        'reset this for next time
  END IF
  PRINT Text$                           'print the text
LOOP UNTIL ERR                          'until ERR says there ain't no more

FUNCTION ScreenHeight% STATIC

  DEF SEG = 0                   'look in low memory at the adapter type
  ScreenHeight% = 25            'assume 25 lines
  IF PEEK(&H463) = &HB4 THEN    'it's a monchrome display, so 25 is correct
    EXIT FUNCTION
  END IF

  Regs.AX = &H1200              'it's color, test if EGA or VGA
  Regs.BX = &H10
  CALL Interrupt(&H10, Regs)            'call the BIOS video interrupts
  IF (Regs.BX AND &HFF) = &H10 THEN     'it's a CGA
    EXIT FUNCTION                       'so again, 25 lines is correct
  END IF

  ScreenHeight% = PEEK(&H484)   'this address holds the number of screen
                                '  rows for EGA/VGA display adapters
END FUNCTION

