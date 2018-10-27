'********** MAP.BAS - memory map utility

'Copyright (c) 1989 Crescent Software, written by Robert L. Hummel


' Usage: MAP [/D]  --- The /D option tells Map to show additional details.
'
'---- Map prints information about the DOS memory map.  It works only for
'     real (640K) memory, and it includes the segments of the Map program
'     itself, because Ethan liked it that way.
'
'Compile and link as follows:
'
'  BC MAP /O;
'  LINK /EX/NOE/NOD MAP _STR$ STR00256 _NOREAD _NOVAL _LOCATE, , NUL, PDQ


'$INCLUDE: 'PDQDECL.BAS'

DECLARE SUB GetMCB (A&, B&, C&, D&)
DECLARE SUB FindName (A&, A$)

DEFLNG A-Z

CONST VNum% = &H77
DIM IntVect(VNum%), Ints%(VNum%)

CONST MaxEntries% = 50
DIM MCBS(1 TO MaxEntries, 1 TO 5)
DIM ProgName$(1 TO MaxEntries)

PRINT "MAP 1.20 (c) 1989 Crescent Software þ Robert L. Hummel"


' The MCB array contains 5 entries for each memory control block (MCB).
' (1) The segment address of the MCB.
' (2) The PSP that owns the MCB. An owner of 0 indicates free memory.
' (3) The length of the block in paragraphs (16-bytes).
' (4) The type of block. This is data, PSP, or environment.
' (5) The index of the parent PSP.

CONST Adr% = 1
CONST Own% = 2
CONST Length% = 3
CONST Typ% = 4
CONST Par% = 5

CONST MASK& = &HFFFF&
CONST TypeData% = 0
CONST TypePSP% = 1
CONST TypeEnv% = 2

'---- Find out if an expanded listing is requested.
IF INSTR(UCASE$(COMMAND$), "/D") THEN Expand% = -1

'---- Get the current values of the interrupt vectors and convert them to
'     segment-only values.  We're interested only in vectors 0 - 77h.
DEF SEG = 0

FOR X% = 0 TO VNum%
    IntVect(X%) = (MASK& AND PDQPeek2%(X% * 4)) \ 16 + (MASK& AND PDQPeek2%(X% * 4 + 2))
NEXT X%

'---- Search the memory control block chain and record the segment address
'     of each block.
Block = 0
Count% = 0

DO
  Count% = Count% + 1

  IF Count% > MaxEntries% THEN
     PRINT "Error: Increase the size of the <MCBS> array."
     END
  END IF

  CALL GetMCB(Block, MCBS(Count%, Own%), MCBS(Count%, Length%), NextBlock)
  MCBS(Count%, Adr%) = Block
  Block = NextBlock

LOOP WHILE NextBlock

'---- Fudge on the first block.
MCBS(1, Own%) = MCBS(1, Adr%) + 1
MCBS(1, Typ%) = TypePSP%
MCBS(1, Par%) = 1
ProgName$(1) = "DOS"

'---- Now test each block in the chain to identify its type: data,
'     environment, or PSP, and its relationship to other blocks.
FOR X% = 2 TO Count%

'---- A MCB can be identified as a PSP by the fact that it owns itself.
'     If found, set the type indicator.
    IF MCBS(X%, Adr%) + 1 = MCBS(X%, Own%) THEN

       MCBS(X%, Typ%) = TypePSP%

'---- Assume this PSP is COMMAND.COM.  Note that COMMAND doesn't normally
'     record its name in the environment, as do other programs.
       ProgName$(X%) = "COMMAND "

'---- The PSP block (1 paragraph past MCB header) contains the segment of the
'     program's environment at 2CH and the segment of the program's parent
'     at 16H.
       DEF SEG = MCBS(X%, Adr%) + 1
       Env = MASK& AND PDQPeek2%(&H2C)
       Parent = MASK& AND PDQPeek2%(&H16)

'---- Look up the segment that was returned for the Parent PSP.  If it's in
'     our list, it's a valid block and the index for that block is entered
'     as the parent of this one (X%).
       FOR Y% = 1 TO Count%
           IF MCBS(Y%, Adr%) + 1 = Parent THEN MCBS(X%, Par%) = Y%
       NEXT Y%

'---- If the program is its own parent or the Env segment is 0, we know this
'     program name is COMMAND and that we can't determine its parent.
       IF (Parent = MCBS(X%, Adr%) + 1) OR (Env = 0) GOTO MAP9

'---- Look up the segment that was returned as the environment for this PSP.
'     If it's in the list and owned by the PSP, it's valid and its type can
'     be set to Env.
'     If valid and DOS version 3.x, name can be found.
       ProgName$(X%) = "  n/a   "

       FOR Y% = 1 TO Count%
           IF (MCBS(Y%, Adr%) + 1 = Env) AND (MCBS(Y%, Own%) = MCBS(X%, Adr%) + 1) THEN
              IF DOSVer% >= 300 THEN CALL FindName(Env, ProgName$(X%))
              MCBS(Y%, Typ%) = TypeEnv%
           END IF
       NEXT

MAP9:
    END IF
NEXT

'---- Now go through the chain again and print out all the particulars.
PRINT "----------------------------------------------------------------"
PRINT "PSP  Program  Parent   Segs  Size(Bytes) Hooked Interrupts"
PRINT "----------------------------------------------------------------"

FOR X% = 1 TO Count%

    IF MCBS(X%, Own%) = 0 THEN
       FSegs% = FSegs% + 1
       FSize = FSize + MCBS(X%, Length%)
    END IF

    IF MCBS(X%, Typ%) = TypePSP% THEN

'---- Clear the Ints array, which is used to keep track of which interrupts
'     point to memory owned by the current PSP.
       FOR Y% = 0 TO VNum%
           Ints%(Y%) = 0
       NEXT

'---- Scan the memory chain and total the number of segs and bytes that
'     belong to this PSP.  Then check for hooked interrupt vectors.
       Size = 0
       Segs% = 0

       FOR Y% = 1 TO Count%
           IF MCBS(X%, Own%) = MCBS(Y%, Own%) THEN
              Segs% = Segs% + 1
              Size = Size + MCBS(Y%, Length%)
              Lo = MCBS(Y%, 1) + 16
              Hi = MCBS(Y%, Length%) + Lo
              FOR Z% = 0 TO VNum%
                  IF Lo <= IntVect(Z%) AND Hi >= IntVect(Z%) THEN
                     Ints%(Z%) = -1
                  END IF
              NEXT
           END IF
       NEXT

'---- I guess we're done. Write it out!
    CurLine% = CSRLIN
    PRINT HEX$(MCBS(X%, Own%)); TAB(6); ProgName$(X%); TAB(15);
    PRINT ProgName$(MCBS(X%, Par%)); TAB(25); Segs%; TAB(30);
    PRINT Size * 16; TAB(41);
    FOR Y% = 0 TO VNum%
        IF Ints%(Y%) THEN               'one of the interrupts points here
           IF POS(0) = 80 THEN PRINT    'in the last column, go to next line
           IF POS(0) < 2 THEN LOCATE CSRLIN, 41  'Tab to the Interrupts col.
           PRINT " "; RIGHT$("0" + HEX$(Y%), 2); 'print the interrupt vector
        END IF
    NEXT
    PRINT

'---- If an expanded listing is called for, do it.
    IF Expand% THEN
       FOR Y% = 1 TO Count%
           IF MCBS(X%, Own%) = MCBS(Y%, Own%) THEN
              PRINT "("; HEX$(MCBS(Y%, Adr%) + 1); ") is ";
              IF MCBS(Y%, Typ%) = 0 THEN PRINT "Data       ";
              IF MCBS(Y%, Typ%) = 1 THEN PRINT "PSP        ";
              IF MCBS(Y%, Typ%) = 2 THEN PRINT "Environment";
              PRINT TAB(30); MCBS(Y%, Length%) * 16
            END IF
       NEXT
       PRINT
    END IF

  END IF
NEXT

'---- List the free memory.
PRINT
PRINT "Free Memory"; TAB(25); FSegs%; TAB(30); FSize * 16

IF Expand% THEN
   FOR X% = 1 TO Count%
       IF MCBS(X%, Own%) = 0 THEN
          PRINT "("; HEX$(MCBS(X%, Adr%) + 1); ") Unallocated Memory ";
          PRINT TAB(30); MCBS(X%, Length%) * 16
       END IF
   NEXT X%
END IF

'----- PEEK low memory to obtain the total installed system RAM
DEF SEG = 0
PRINT
PRINT "This system has a total of "; PDQPeek2%(&H413); "KBytes base memory"

'----- Get the CPU type and DOS version, and display them
PRINT "This processor is an 80"; GetCPU%
PRINT "DOS Version is "; Dollar$(CLNG(DOSVer%))

' Entry: Env = Segment of the environment to get the name from
'  Exit: Name$ = Name of the program that owns the environment
'     1. Scan the environment to find the name at the end.
SUB FindName (Env, Name$)

Offset% = 0
DEF SEG = Env

DO
   Test = PDQPeek2%(Offset%)
   IF Test = 0 THEN EXIT DO
   Offset% = Offset% + 1
LOOP

Offset% = Offset% + 4           'Point to start of program name
Chars% = 0

DO WHILE PEEK(Offset%)
   Offset% = Offset% + 1
   Chars% = Chars% + 1
LOOP

'---- Now scan backwards through memory to parse out the program name from
'     the string "d:\path\NAMENAME.EXT", 0

Name$ = ""
Chars% = Chars% - 4           'Take off extension
IF Chars% > 8 THEN Chars% = 8
Offset% = Offset% - 5         'Back up on string

FOR X% = Offset% TO Offset% - Chars% STEP -1
    A$ = CHR$(PEEK(X%))
    IF A$ = "\" THEN EXIT FOR
    Name$ = A$ + Name$
NEXT

END SUB

' Entry: MCB = contains the segment of a valid MCB to analyze
'            = 0 to return first block
' Exit:  MCB = segment of the analyzed block
'      Owner = Owner of this MCB
'     Length = Length of block in paragraphs
'    NextMCB = address of next block or 0 if no more
'
' Notes:
' 1. Minimal error checking since this is just a demo and not a commercial
'    application.
' 2. Always assumes MCB is valid and is an "M" block.  Should not be called
'    if MCB is the last block in the chain.
'
SUB GetMCB (MCB, Owner, Length, NextMCB)

DIM Registers AS RegType

' ---- If the MCB parameter is 0, then get the first memory control block
'      using an undocumented DOS function.
'      The word at ES:[BX-2] is the address of the first MCB.

IF MCB = 0 THEN
   Registers.AX = &H5200
   CALL InterruptX(&H21, Registers)
   DEF SEG = Registers.ES
   MCB = MASK& AND PDQPeek2%(Registers.BX - 2)  'First MCB
END IF

'---- MCB is now valid.  Use the MCB to find owner and length.
DEF SEG = MCB
Owner = MASK& AND PDQPeek2%(1)          'Owner of this block
Length = MASK& AND PDQPeek2%(3)         'Length of this block

'---- Set NextMCB for return.
IF PEEK(0) = 90 THEN                    '90 is ASCII for "Z"
   NextMCB = 0
ELSE
   NextMCB = MCB + Length + 1
END IF

END SUB

