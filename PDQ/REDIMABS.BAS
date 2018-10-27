'********** REDIMABS.BAS - shows how to coerce an array to use any segment

'Copyright (c) 1991 Ethan Winer

'Note that when using RedimAbsolute it is not truly necessary to specify
'more than one element.  For example, if you change the call that establishes
'the Video array as display memory to elements 1 through 1, the assignments
'to higher element numbers will still be made correctly.  BASIC doesn't check
'the validity of element numbers unless you compile with /d or /ah.  However,
'this is not really a recommendation, and good "form" would probably suggest
'using correct values.


DEFINT A-Z
'$INCLUDE: 'pdqdecl.bas'

'---- see if this is a color or monochrome display
'
DEF SEG = 0
IF PEEK(&H463) = &HB4 THEN                      'monochrome
  VidSeg = &HB000
ELSE                                            'color
  VidSeg = &HB800
END IF

REDIM Video(1 TO 1)                             'first establish the array
CALL RedimAbsolute(Video(), 1, 2000, VidSeg)    'change segment to video mem.


'---- fill the screen with white-on-blue "A" characters
'
Value = &H1741                       '                   &H1741
FOR X = 1 TO 2000                    '                     ||||
  Video(X) = Value                   '  blue background ---+|++-- ASCII "A"
NEXT                                 ' white foreground ----+

LOCATE 25, 1
PRINT "press a key      "; STRING$(5, 8);
WHILE LEN(INKEY$) = 0: WEND
CLS


'---- now lets look at part of the interrupt vector table
'
REDIM Vectors&(1 TO 1)
CALL RedimAbsolute(Vectors&(), 0, 127, 0)
FOR X = 0 TO 45
    Temp$ = RIGHT$("0000000" + HEX$(Vectors&(X)), 8)    'format the numbers
    Temp$ = LEFT$(Temp$, 4) + ":" + RIGHT$(Temp$, 4)    'as 0000:0000
    IF X > 22 THEN LOCATE X - 22, 40                    'tab over
    PRINT "Vector &H"; RIGHT$("0" + HEX$(X), 2); ":", Temp$
NEXT

LOCATE 25, 1
PRINT "press a key ";
WHILE LEN(INKEY$) = 0: WEND
CLS


'---- mimic a C union by aliasing a TYPE array to the same interrupt vectors
'
TYPE FLen                               'a TYPE is needed to allow passing
  S AS STRING * 45                      ' an entire array in QB 4.5 / PDS 7.0
END TYPE
REDIM Union(1 TO 1) AS FLen
CALL RedimAbsolute(Union(), 1, 10, 0)   '10 elements of 45 bytes each

FOR X = 1 TO 10
    CALL PDQPrint(Union(X).S, X, 1, 7)
NEXT

