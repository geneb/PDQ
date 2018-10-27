'********** SORT.BAS - loads a text file and sorts the lines

'Copyright (c) 1992 Ethan Winer


DEFINT A-Z
DECLARE SUB Sort (BYVAL Address, Size, Direction)
DECLARE SUB Sort2 (BYVAL Address, Size, Direction)

OPEN "SORT.BAS" FOR INPUT AS #1         'open ourselves (is that immoral?)
DO WHILE NOT EOF(1)                     'first count the lines
  NumLines = NumLines + 1               ' in the file
  LINE INPUT #1, Dummy$
LOOP
SEEK #1, 1

REDIM Array$(1 TO NumLines)             'make an array to hold the file
FOR X = 1 TO NumLines                   'and read it into the array
  LINE INPUT #1, Array$(X)
NEXT
CLOSE

Dir = 0                                         'change to 1 for descending
PRINT "Press any key to begin sorting ";
'CALL Sort(VARPTR(Array$(1)), NumLines, Dir)    'use either routine
CALL Sort2(VARPTR(Array$(1)), NumLines, Dir)

FOR X = 1 TO NumLines
  PRINT LEFT$(Array$(X), 79)            'LEFT$() in case a line is too long
  IF INKEY$ <> "" THEN
     WHILE INKEY$ = "": WEND            'pause and resume on any keypress
  END IF
NEXT

