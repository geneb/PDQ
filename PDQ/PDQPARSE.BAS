'********** PDQPARSE.BAS - demonstrates string parsing

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

CLS

'----- Parse the current DOS PATH and display each directory.  PDQParse uses
'      a semicolon as a delimiter by default.

Path$ = ENVIRON$("PATH")                'get the current DOS PATH
PRINT "The full path for this PC: "; Path$
PRINT "And here's each directory:"

DO                                      'print each individual directory
   ThisDir$ = PDQParse$(Path$)
   PRINT SPC(4); ThisDir$
LOOP WHILE LEN(ThisDir$)                'PDQParse returns a null when done


'----- Parse the command line, and display each argument.

CALL PDQRestore                         'reset again for a new string
CALL SetDelimitChar(32)                 'now use a blank space as a delimiter
Work$ = COMMAND$                        'get the command line arguments
PRINT "The command line arguments used to start this program: "; Work$

DO
   Temp$ = PDQParse$(Work$)             'get the next argument
   PRINT SPC(4); Temp$
LOOP WHILE LEN(Temp$)

