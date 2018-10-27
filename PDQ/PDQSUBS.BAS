'********** PDQSUBS.BAS - subprograms and functions for the QB environment

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM SHARED Registers AS RegType 'RegType is defined in PDQDECL.BAS, and
                                '  it is used with CALL INTERRUPT as well
                                '  as the P.D.Q. TSR routines

DIM SHARED NextChar             'these are used by PDQParse$, PDQRestore
DIM SHARED DelimitChar          '  and SetDelimitChar

REDIM SHARED Alloc1&(1 TO 1)    'these are used by AllocMem and ReleaseMem
REDIM SHARED Alloc2&(1 TO 1)
REDIM SHARED Alloc3&(1 TO 1)
REDIM SHARED Alloc4&(1 TO 1)
REDIM SHARED Alloc5&(1 TO 1)

DIM SHARED Active(1 TO 5)       'this tracks which arrays/segments are in use
                                '  by AllocMem

FUNCTION AllocMem% (NumBytes) STATIC

'---- This function differs from the actual PDQ assembler version in that
'     only five segments may be allocated.
  
    Handle = 1
    DO WHILE Active(Handle)
       Handle = Handle + 1
    LOOP
  
    NumEls = NumBytes \ 4 + 1           'calculate number of elements needed
                                        '+1 is to round up
    SELECT CASE Handle
       CASE 1
          REDIM Alloc1&(1 TO NumEls)
          Active(1) = VARSEG(Alloc1&(1))
          AllocMem% = Active(1)

       CASE 2
          REDIM Alloc2&(1 TO NumEls)
          Active(2) = VARSEG(Alloc2&(1))
          AllocMem% = Active(2)

       CASE 3
          REDIM Alloc3&(1 TO NumEls)
          Active(3) = VARSEG(Alloc3&(1))
          AllocMem% = Active(3)

       CASE 4
          REDIM Alloc4&(1 TO NumEls)
          Active(4) = VARSEG(Alloc4&(1))
          AllocMem% = Active(4)

       CASE 5
          REDIM Alloc5&(1 TO NumEls)
          Active(5) = VARSEG(Alloc5&(1))
          AllocMem% = Active(5)

       'CASE N
          'Numbered cases may be repeated.  Be sure to add the REDIM SHARED
          'in the module level code and modify ReleaseMem similarly.
       CASE ELSE
    END SELECT

END FUNCTION

FUNCTION BreakHit% STATIC
END FUNCTION

SUB BreakOff STATIC
END SUB

SUB BreakOn STATIC
END SUB

FUNCTION BufIn$ (FileName$, Done) STATIC

'The four lines REMmed out below can be activated if you want to handle
'properly CHR$(26) EOF (end of file) marks imbedded within a file.

IF LEN(FileName$) = 0 GOTO ExitFn      'a null means they want to abort early

IF Reading GOTO Process                'if we're reading now, jump into it

'----- initialization
Reading = -1                           'we're not reading yet, so start now
Done = 0                               'in case Done came in not zero
CR$ = CHR$(13)                         'define this once now for speed later
'E$ = CHR$(26)                         'define this once too for speed

FileNum = FREEFILE                     'get the next available file number
OPEN FileName$ FOR BINARY AS #FileNum  'open the file
Remaining& = LOF(FileNum)              'see how many bytes need to be read
IF Remaining& = 0 GOTO ExitFn          'empty file or it wasn't there, exit

BufSize = 4096                         'bytes to read, change to suit
Buffer$ = SPACE$(BufSize)              'assume a full BufSize bytes

DO                                     'this is the main "outer" loop
   IF Remaining& < BufSize THEN        'we can't read more than is left
      BufSize = Remaining&             'resize the buffer to what remains
      IF BufSize < 1 GOTO ExitFn       '(happens only if there's an EOF mark)
      Buffer$ = SPACE$(BufSize)        'create the buffer proper
   END IF
   GET #FileNum, , Buffer$             'read a block

   BufPos = 1                          'start at the beginning of the string
   DO                                  'this loop walks through the buffer
    'E = INSTR(BufPos, Buffer$, E$)    'see if there's an EOF in there
     CR = INSTR(BufPos, Buffer$, CR$)  'search for a carriage return
    'IF E AND (E < CR) THEN CR = E     'if EOF is before CR, keep only to EOF
     IF CR THEN                        'we found a CR in the buffer
        SaveCR = CR                    'save a copy to seek backwards later
        BufIn$ = MID$(Buffer$, BufPos, CR - BufPos)'extract the string
        BufPos = CR + 2                            'skip inevitable line feed
       'IF CR = E GOTO ExitFn                      'all done, clean up
        EXIT FUNCTION                              'done for now
     ELSE                                          'back up in the file
        IF SEEK(FileNum) >= LOF(FileNum) THEN      'if at the end with no CR
           Output$ = MID$(Buffer$, SaveCR + 2)     'return only what remains
           IF RIGHT$(Output$, 1) = CHR$(26) THEN   'trap a trailing CHR$(26)
              Output$ = LEFT$(Output$, LEN(Output$) - 1)
           END IF
           BufIn$ = Output$
           GOTO ExitFn                             'and exit now
        END IF
        Slop = BufSize - SaveCR - 1                'calculate buffer excess
        Remaining& = Remaining& + Slop             'this much more to read
        SEEK #FileNum, SEEK(FileNum) - Slop        'seek to start of string
     END IF

Process:
   LOOP WHILE CR                       'while there's more in the buffer
   Remaining& = Remaining& - BufSize   'show that much left to process

LOOP WHILE Remaining&                  'while there's more in the file

ExitFn:
Reading = 0                            'show that we're not reading anymore
Done = -1                              'and show that we're all done
CLOSE #FileNum                         'final clean-up

END FUNCTION

SUB BufOut (FileName$, Text$, Term$) STATIC

    CONST BufSize% = 4096               'this sets the output buffer size

    IF FileNum THEN                     'if the file is currently active
      IF LEN(FileName$) = 0 THEN        'and if they want to finish
        GOSUB FlushIt                   'first flush the buffer
        CLOSE #FileNum                  'then close the file
        FileNum = 0                     'show that the file is inactive
        Buffer$ = ""                    'free up the memory used by Buffer$
        EXIT SUB                        'and finally exit
      ELSE

PutIt:
        Length = LEN(Text$) + LEN(Term$)        'see how long the text is
        IF Length > BufSize% - Pointer + 1 THEN 'will Text$ + Term$ fit?
          GOSUB FlushIt                         'no, first purge the buffer
          Pointer = 1                           'then reset the pointer
        END IF

        MID$(Buffer$, Pointer, Length) = Text$ + Term$   'insert the text
        Pointer = Pointer + Length              'bump the pointer past Text$
      END IF

    ELSE                                        'this is the first time
      FileNum = FREEFILE                        'get next avail. file number
      OPEN FileName$ FOR OUTPUT AS #FileNum     'open the file for output
      Buffer$ = SPACE$(BufSize%)                'create the output buffer
      Pointer = 1                               'init the buffer pointer
      GOTO PutIt                                'and jump to buffered write
    END IF

    EXIT SUB                                    'don't fall into the GOSUB!

FlushIt:
    PRINT #FileNum, LEFT$(Buffer$, Pointer - 1); 'flush the buffer to disk
    RETURN                                      'return to caller
     
END SUB

SUB CallOldInt (Registers AS RegType) STATIC
END SUB

SUB CritErrOff STATIC
END SUB

SUB CritErrOn STATIC
END SUB

FUNCTION DeInstallTSR% (DGroup, ID$) STATIC
    DeInstallTSR% = -1          'show that deinstallation was succesful
END FUNCTION

SUB DisableFP STATIC
END SUB

FUNCTION Dollar$ (Value&) STATIC

    Minus$ = ""                         'assume it's a positive value
    IF Value& < 0 THEN Minus$ = "-"     'it isn't, remember that for later
   
    Temp$ = MID$(STR$(Value&), 2)       'remove the leading "-" or blank
    Length = LEN(Temp$)                 'get the length just once for speed
    Cents$ = "." + RIGHT$("0" + Temp$, 2)   'format the pennies portion

    IF Length > 2 THEN                  'if it's longer than 2 we have to
       Temp$ = LEFT$(Temp$, Length - 2) '  strip off the pennies
    ELSE                                'otherwise simply
       Temp$ = "0"                      '  use a leading zero
    END IF
   
    Dollar$ = Minus$ + Temp$ + Cents$   'assign the function output

END FUNCTION

FUNCTION DOSBusy% STATIC
    DOSBusy% = 0        'or use -1 if you prefer
END FUNCTION

SUB EnableFP STATIC
END SUB

SUB EndLevel (ErrLevel) STATIC  'we can't really do this in QB
    END                         'so just end
END SUB

SUB EndTSR (ID$) STATIC
    END
END SUB

SUB EnvOption (OptionCode) STATIC
END SUB

SUB GotoOldInt (Registers AS RegType) STATIC
END SUB

SUB HookFP STATIC
END SUB

SUB HookInt0 (Action) STATIC
END SUB

SUB IntEntry1
END SUB

SUB IntEntry2 (Registers AS RegType, Action)
END SUB

SUB PDQCPrint (Work$, Row, Column) STATIC

    SaveRow = CSRLIN
    SaveCol = POS(0)
    LOCATE Row, Column
    PRINT Work$;
    LOCATE SaveRow, SaveCol

END SUB

SUB PointIntHere (Registers AS RegType) STATIC
END SUB

FUNCTION PoolOkay% STATIC
    PoolOkay% = -1          'return true (what else can we do?)
END FUNCTION

FUNCTION PopDeinstall% (DGroup, ID$) STATIC
    PopDeinstall% = -1          'show that deinstallation was succesful
END FUNCTION

SUB PopDown STATIC
    END
END SUB

SUB PopUpHere (HotKey, ID$) STATIC
END SUB

FUNCTION ReleaseMem% (Segment) STATIC
  
    ReleaseMem% = 0                     'assume a successful release

    SELECT CASE Segment                 'see which one it is
       CASE Active(1)                   'if it's this array then ...
          REDIM Alloc1&(1 TO 1)         'release the memory
          Active(1) = 0                 'flag it as being available

       CASE Active(2)                   'as above
          REDIM Alloc2&(1 TO 1)
          Active(2) = 0

       CASE Active(3)
          REDIM Alloc3&(1 TO 1)
          Active(3) = 0

       CASE Active(4)
          REDIM Alloc4&(1 TO 1)
          Active(4) = 0

       CASE Active(5)
          REDIM Alloc5&(1 TO 1)
          Active(5) = 0

       CASE ELSE
          ReleaseMem% = -1               'not one we know of, -1 = failure

    END SELECT

END FUNCTION

SUB ResetKeyboard STATIC
END SUB

SUB ReturnFromInt (Registers AS RegType) STATIC
END SUB

FUNCTION StringShort% STATIC
    StringShort% = 0        'this never happens in BASIC (yeah, right!)
END FUNCTION

FUNCTION StringUsed% STATIC
    StringUsed% = 10000         'there's no real way to imitate this in BASIC
END FUNCTION                    '(so we'll just make up a number)

FUNCTION TestHotKey% (KeyCode) STATIC
    TestHotKey% = 0                     'or whatever, it doesn't much matter
END FUNCTION

SUB TSRFileOff STATIC
END SUB

SUB TSRFileOn STATIC
END SUB

FUNCTION TSRInstalled% (ID$) STATIC
    TSRInstalled% = 0           'use -1 if you prefer, irrelevant either way
END FUNCTION

SUB UnhookFP
END SUB

FUNCTION UnHookInt% (Registers AS RegType, DGroup) STATIC
END FUNCTION

SUB UnhookInt0 STATIC
END SUB

