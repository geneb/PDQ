'PDQPAUSE.BAS - DOS PAUSE replacement accepts a command-line timeout value

'Copyright (c) 1992 Ethan Winer

'Usage: PDQPAUSE NumSeconds

'Compile and link as follows:
'
'  BC pdqpause /o;
'  LINK /far/nod/noe/packc pdqpause _noval _noread _noerror, , nul, pdq;
'  EXE2COM pdqpause


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Spin$(1 TO 4)
Spin$(1) = "|"                 'These are CHR$(8) backspaces embedded in the
Spin$(2) = "/"                 ' spinner icons, so PRINT will back up and
Spin$(3) = "-"                 ' print the next one over the previous one.
Spin$(4) = "\"

NumTicks = PDQValI%(COMMAND$) * 18
PRINT "Press any key to continue: ";
CALL CursorOff
DO: LOOP WHILE LEN(INKEY$)      'clear the keyboard buffer like PAUSE does

Now& = PDQTimer&
DO WHILE (Now& + NumTicks > PDQTimer&) AND (KeyHit = 0)
  Element = Element + 1
  IF Element > 4 THEN Element = 1
  PRINT Spin$(Element);
  CALL Pause(1)
  KeyHit = PDQInkey%
LOOP

PRINT " "                       'erase the last spinner
CALL CursorOn

IF KeyHit = 3 THEN CALL StuffBuf(CHR$(3))       'let DOS act on Ctrl-C
CALL EndLevel(KeyHit)           'also allow testing in a batch file

