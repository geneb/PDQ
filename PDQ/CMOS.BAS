'********** CMOS.BAS - saves/restores CMOS set-up memory in an AT-style PC

'Copyright (c) 1990 Ethan Winer


DEFINT A-Z

PRINT "Save or Restore the CMOS memory (S/R)? ";
DO                                      'see which they want
   Choice$ = UCASE$(INKEY$)
LOOP UNTIL Choice$ = "S" OR Choice$ = "R"
PRINT Choice$                           'print what they selected

IF Choice$ = "S" THEN                   'save the current set-up information
   PRINT "Writing to file: CMOS.DAT"    'show what we're doing
   OPEN "CMOS.DAT" FOR OUTPUT AS #1     'create the output file
   FOR X = 14 TO 63                     'for each piece of data needed
       OUT 112, X                       'say we want to read from the port
       Value = INP(113)                 'read the actual data
       PUT #1, , Value                  'write it to disk
   NEXT
   CLOSE                                'all done writing
ELSE
   OPEN "CMOS.DAT" FOR INPUT AS #1      'open the file for reading
   IF ERR THEN                          'check for a possible error
      PRINT "File CMOS.DAT not found"
      END
   END IF
   PRINT "Reading from file: CMOS.DAT"  'show what we're doing
   FOR X = 14 TO 63                     'for each piece of data needed
       GET #1, , Value                  'read it from disk
       OUT 112, X                       'say we want to write to the port
       OUT 113, Value                   'send the actual data
   NEXT
   CLOSE                                'all done writing
END IF
