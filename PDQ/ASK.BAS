'********* ASK.BAS - allows keyboard input in a batch file via ERRORLEVEL

'Copyright (c) 1989 Ethan Winer

'This program will not work in the QB editing environment.

'For the smallest size possible compile and link as follows:
'
'  bc ask /o;
'  link /nod/noe/far/packc ask _noval _noread _noerror , , nul, pdq


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

PRINT COMMAND$;         'print the prompt message

DO                      'wait until a key is pressed
   Ask = ASC(INKEY$)
LOOP WHILE Ask = -1     'in P.D.Q. ASC() returns -1 for a null string

PRINT
EndLevel (Ask - 48)     'adjust ASCII to a valid number

