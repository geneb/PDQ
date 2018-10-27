'********** SMALLDOS.BAS - demonstrates INPUT # when using SMALLDOS.LIB

'Copyright (c) 1990 Ethan Winer

'This program should be compiled to disk because the P.D.Q. INPUT # sets
'ERR to 83 if the line is longer than 128 characters.  Also, the appearance
'of the lines will be slightly different, because QuickBASIC's INPUT #
'strips leading blanks from each line.  Compile and link it like this:
'
'   BC SMALLDOS /O;
'   LINK SMALLDOS /NOE /NOD , , NUL, SMALLDOS PDQ


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

CONST MaxLines% = 500           'the maximum number of lines we can handle
DIM Array$(1 TO MaxLines%)      'make a string array to hold them

PRINT "Enter the name of a file to read: ";     'prompt for a file name
PDQInput FileName$                              'get it
IF FileName$ = "" THEN END                      'they just pressed Enter, end

PRINT
OPEN FileName$ FOR INPUT AS #1                  'open the file

DO
   CurLine = CurLine + 1                        'track the line being read
   INPUT #1, Array$(CurLine)                    'go get a line of text
   DO WHILE ERR = 83                            'if the line length > 128
      INPUT #1, Temp$                           'go get some more
      Array$(CurLine) = Array$(CurLine) + Temp$ 'concatenate the strings
   LOOP                                         'until the entire line is read
   IF ERR THEN EXIT DO                          'exit if there was an error
   PRINT Array$(CurLine)                        'print the line
LOOP UNTIL EOF(1) OR (CurLine = MaxLines%)      'end of file or no more array

CLOSE #1                                        'close the file, all done

