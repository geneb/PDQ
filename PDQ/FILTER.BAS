'********** FILTER.BAS - shows how to make a DOS filter program

'Copyright (c) 1989 Ethan Winer

'For the smallest .EXE file size compile and link like this:
'
'  bc filter /o ;
'  link /noe/nod/far/packc filter _noval _noerror _noread , , nul, pdq ;


DEFINT A-Z

CONST CR = 13                               'using CONST saves 16 bytes
CONST LF = 10

'----- The line feed is handled separately because it will be in the file if
'      input is redirected, but not when Enter is pressed from the keyboard.

'----- It would be nice to use DO UNTIL or LOOP UNTIL instead IF .. EXIT DO,
'      but there's no way to do that without making two tests.  Also, notice
'      that the ASCII value of INKEY$ is taken once below, so the remaining
'      comparisons on Work can be integer tests rather than string tests.  An
'      integer operation is always smaller/faster than a string operation.
DO
  Work = ASC(INPUT$(1))                     'get a character, get ASC() once
  IF Work = 26 OR Work = -1 THEN EXIT DO    'all done, don't print these
  IF Work <> LF THEN                        'we'll do this ourself later
     IF Work > 127 THEN Work = Work AND 127 'strip hi-bits just for fun
     PRINT UCASE$(CHR$(Work));              'capitalize too
     IF Work = CR THEN PRINT CHR$(LF);      'add LF to Enter manually
  END IF
LOOP

