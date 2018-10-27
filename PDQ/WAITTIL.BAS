'******** WAITTIL.BAS - pauses a batch file until a specified time of day

'Copyright (c) 1991 Ethan Winer

'This program was inspired by a utility in PC Computing.

'For minimum program size compile and link as follows:
'
'  bc waittil /o;
'  link /noe /nod /ex /far /packc waittil _noread _noval _noerror, , nul, pdq


DEFINT A-Z
WaitTime$ = LTRIM$(RTRIM$(COMMAND$))    'get the resume time
CmdLen = LEN(WaitTime$)                 'and its length

IF CmdLen = 0 THEN              'show help if no command
   PRINT "Syntax: WAITTIL hh:mm[:ss]"
   PRINT "You must use military (24 hour) time and provide either 5 or 8 characters."
   END
END IF

IF CmdLen = 5 THEN WaitTime$ = WaitTime$ + ":00"

DO
LOOP UNTIL WaitTime$ = TIME$

