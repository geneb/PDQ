'********* MULTPAGE.BAS - shows how to read/write to multiple video pages

'Copyright (c) 1990 Ethan Winer


'NOTE: This routine goes behind BASIC's back to change video modes, and
'      does not work as expected in the QB and QBX editors.


DEFINT A-Z

'$INCLUDE: 'PDQDECL.BAS'


DEF SEG = 0                             'first ensure there's a color monitor
IF PEEK(&H463) = &HB4 THEN              'it's monochrome
  PRINT "You need a color display to run this program"
  END
ELSE
  CLS
END IF


'--- Show how to use CALL INTERRUPT to set the current display for both
'    reading and writing.  The Regs TYPE Variable is defined in PDQDECL.BAS
'    and used here to communicate with the BIOS which does the real work.
'
PRINT "What page would you like to make active? (0 - 7) ";
INPUT "", Page
DIM Regs AS RegType
Regs.AX = &H500 + Page
CALL Interrupt(&H10, Regs)

CLS
PRINT "You are now looking at page "; Page
PRINT "Press any key to flip back to page 0 ";
WHILE LEN(INKEY$) = 0: WEND
PRINT

Regs.AX = &H500                         'specify page 0
CALL Interrupt(&H10, Regs)


'--- Show how to set any page for writing, which is independent of the page
'    currently being displayed.  Each successive page starts at a segment 256
'    paragraphs higher than the previous page.  Use PDQSetMonSeg to set the
'    segment that PDQPrint uses, and fill the screen with a test pattern.
'    Finally, call the BIOS once more to display that page.
'
PRINT "What page would you like to make active? (0 - 7)  ";
INPUT "", Page
Segment = &HB800 + Page * 256
CALL PDQSetMonSeg(Segment)
PRINT "Now printing on page "; Page
FOR X = 1 TO 20
  CALL PDQPrint("This is being printed in the background on page " + STR$(Page), X, 1, 112)
NEXT

PRINT "Press a key to display the text just printed on page "; Page
WHILE LEN(INKEY$) = 0: WEND
Regs.AX = &H500 + Page
CALL Interrupt(&H10, Regs)

LOCATE 22, 1
PRINT "You are now looking at page "; Page
PRINT "Press any key to flip back to page 0 ";
WHILE LEN(INKEY$) = 0: WEND
PRINT

Regs.AX = &H500                         'specify page 0
CALL Interrupt(&H10, Regs)

