'********** PLAY.BAS - just for fun

'Copyright (c) 1990 Ethan Winer


'If you like this music, you need help.  No kidding.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

CLS
FOR X = 1 TO 10                 'fabricate ten PLAY strings
    Work$ = ""
    FOR Y = 1 TO 10
        Length$ = "L" + STR$(PDQRand%(28) + 5) 'make a random length (4 to 32)
        Octave$ = "O" + STR$(PDQRand%(3) + 1)  'and a random octave
        Note$ = CHR$(PDQRand%(6) + 65)              'and a random note
        Work$ = Work$ + Octave$ + Length$ + Note$   'build the PLAY string
    NEXT
    PRINT Work$
    PLAY Work$
NEXT

