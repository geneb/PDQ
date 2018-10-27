'********** ENVEDIT.BAS - allows editing the DOS master environment

'Copyright (c) 1989 Ethan Winer

'NOTE: This program will not work within the QuickBASIC editing environment.
'
'To avoid having to use LTRIM$(STR$(..)) which adds more code, you should
'link this program using the _STR$.OBJ stub file.  This merely affects the
'appearance of the displayed numbers.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

CALL EnvOption(1)               'work on the parent's (DOS) environment

DO                              'this is the main loop
   CurEnv = 0                   'clear the counter from the last go-around

   DO
      CurEnv = CurEnv + 1       'consider the next environment variable
      Work$ = ENVIRON$(CurEnv)  'get it
      IF ERR = 102 THEN         'some versions of DOS don't allow this
         PRINT "This DOS version can't access the COMMAND.COM environment."
         END
      END IF
      PRINT CurEnv; Work$       'print it
   LOOP WHILE LEN(Work$)

   PRINT
   NumVars = CurEnv             'remember the total number currently active

   DO
      PRINT "Which do you want to edit? (1-"; STR$(NumVars - 1); ", ";
      PRINT NumVars; "to add a new one, Ctrl-C to quit): ";
      CALL PDQInput(Sel$)                       'enter the selection
      CurEnv = PDQValI%(Sel$)                   'get the numeric value
   LOOP UNTIL CurEnv > 0 AND CurEnv <= NumVars  'force a valid selection

   Work$ = SPACE$(80)            'make an editing string
   LSET Work$ = ENVIRON$(CurEnv) 'assign the one they want to the edit string

   PRINT
   CALL BIOSInput(Work$, 7)      'let them edit it
   ENVIRON LTRIM$(RTRIM$(Work$)) 'set the new string into place
   PRINT : PRINT                 'kick out a coupla' blank lines

LOOP                             'and go again

