'*********** FSTAMP.BAS

'Copyright (c) 1991 Crescent Software, Inc.


'NOTE: This program requires QuickPak Professional as well as P.D.Q.

'Compile and link as follows:
'
'  bc fstamp /o/s;
'  link /nod/noe/far/packc/ex fstamp +
'    _str$ _time$ _noread _noval _noerror, , nul, pdq pro


DEFINT A-Z
'$INCLUDE: 'pdqdecl.bas'

DECLARE FUNCTION FCount% (FileSpec$)
DECLARE FUNCTION ParseString$ (Position, Work$, Delimit$)
DECLARE FUNCTION WhichError% ()

DECLARE SUB BCopyT (BYVAL FromSeg, BYVAL FromAdr, BYVAL ToSeg, BYVAL ToAdr, ElSize, NumEls)
DECLARE SUB FStamp (FileSpec$, NewTime$, NewDate$)
DECLARE SUB ReadFileT (Spec$, BYVAL Segment, BYVAL Address)
DECLARE SUB SplitName (Spec$, Drive$, Path$, File$, Extension$)

DEF FNParseIt$ (Delimit$)       'parses the date and time from COMMAND$
  Temp = INSTR(Cmd$, Delimit$)  'see if this delimiter was given
  IF Temp THEN                  'it was, parse out the value
    Temp = Temp + 2             'start looking past the delimiter
    IF Delimit$ = "/D" THEN     'if they're parsing the date
      Separator$ = "-"          'separate the components with a dash
    ELSE
      Separator$ = ":"          'else use a colon for the time
    END IF
    Temp$ = ""                  'clear Temp$ to build a new output string
    FOR X = 1 TO 3              'build the output string
      Item$ = ParseString$(Temp, Cmd$, "/-:")   '"/-:" matches date and time
      Value = PDQValI%(Item$)                   'PDQValI weeds out /D and /T
      IF Value THEN                             'make sure there's a number
        IF X > 1 THEN Temp$ = Temp$ + Separator$    'this avoids "12:30:45:"
        Temp$ = Temp$ + STR$(Value)                 'append it as a string
      ELSE
        IF X = 1 THEN                               'if nothing is there
          FNParseIt$ = "*"                          'use "*" for now
          EXIT DEF                                  'and we're all done
        ELSE
          EXIT FOR
        END IF
      END IF
    NEXT
    FNParseIt$ = LTRIM$(RTRIM$(Temp$))  'assign the function output
  ELSE
    FNParseIt$ = ""                     'no parameter given, ignore
  END IF
END DEF

Cmd$ = UCASE$(COMMAND$)         'work with a copy for efficiency
                                'the file spec precedes the first space
FileSpec$ = LEFT$(Cmd$, INSTR(Cmd$, " ") - 1)

D$ = FNParseIt$("/D")           'find the date if it was given
T$ = FNParseIt$("/T")           'and the time too

NumFiles = FCount%(FileSpec$)   'see how many files there
ErrCode = WhichError%           'see if there was an error accessing the disk
IF ErrCode THEN                 'there was, print the message
   PRINT PDQMessage$(ErrCode)
   END                          'and then end
END IF

IF NumFiles THEN                'at least one file, isolate the components
   CALL SplitName(FileSpec$, Drive$, Path$, File$, Extension$)
   Prefix$ = Drive$ + Path$             'create a file name prefix
   Hold$ = "            "               'and a place to hold each name
   ASeg = AllocMem(NumFiles * 12)       'claim memory for a fake TYPE array
   CALL ReadFileT(FileSpec$, ASeg, 0)   'fill the "array" with names

   FOR X = 0 TO NumFiles - 1            'for each file we read, copy the name
     CALL BCopyT(ASeg, X * 12, VARSEG(X), SADD(Hold$), 12, 1)
     This$ = RTRIM$(Prefix$ + Hold$)    'build the full name for this file
     PRINT This$; " ";                  'show what files are being processed
     IF LEN(D$) THEN                    'if we're changing the date
       IF D$ = "*" THEN                 'if using today print DATE$
         PRINT DATE$; " ";
       ELSE
         PRINT D$; " ";                 'else print what they specified
       END IF
     END IF
     IF LEN(T$) THEN                    'if we're changing the time
       IF T$ = "*" THEN                 'as above
         PRINT TIME$;
       ELSE
         PRINT T$;
       END IF
     END IF
     PRINT
     CALL FStamp(This$, T$, D$)         'QuickPak Pro's FStamp does the work
   NEXT
ELSE
   PRINT "No match for "; FileSpec$     'oops, no file spec or it was invalid
END IF

