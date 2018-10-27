'********** READFILE.BAS - demonstrates using CritErrOff/On

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

CONST MaxLines% = 500           'the maximum number of lines we can handle
DIM Array$(1 TO MaxLines%)      'make a string array to hold them

INPUT "Enter the name of a file to read: ", FileName$ 'prompt for a file name
IF FileName$ = "" THEN END                      'they just pressed Enter, end

CALL CritErrOff                                 'disable critical errors
OPEN FileName$ FOR INPUT AS #1                  'open the file
IF ERR THEN
   PRINT PDQMessage$(ERR)
   GOTO EndIt                                   'end cleanly by re-enabling
END IF                                          '  critical errors!

DO
   CurLine = CurLine + 1                        'track the line being read
   LINE INPUT #1, Array$(CurLine)               'go get a line of text
   IF ERR THEN EXIT DO                          'we read past the end, done
   PRINT Array$(CurLine)                        'print the line
LOOP UNTIL CurLine = MaxLines%                  'stop at the end of the array

EndIt:
CALL CritErrOn                                  're-enable critical errors
CLOSE #1                                        'close the file, all done

