'********* PDQKEY.BAS - keyboard macro substitution program

'Copyright (c) 1990 Crescent Software
'Written by Ethan Winer and Nash Bly


'WARNING: This program does NOT work in the QuickBASIC editing environment,
'and it should be uninstalled before entering QB.  Please understand that few
'TSR programs cooperate fully with QB, and this is not a failing of P.D.Q.
'
'PDQKEY is a TSR program that lets you define keyboard macros that are typed
'automatically when you press a single "hot-key".  It also expands the PC's
'15-character keyboard buffer to nearly any size.  PDQKEY examines each key
'stroke that is entered, and if it is one of those that have been defined,
'substitutes a replacement character or string of characters.  Any number of
'macros may be defined, and each may be as long as BASIC's string memory can
'accommodate.  As each recognized hot-key is detected, a "master" macro is
'concatenated with the new contents.  This allows multiple macros to be typed
'in succession, even if earlier ones have not yet been processed by the
'underlying application.  Both the macros you define and non-macro keys are
'stuffed into the keyboard buffer by PDQKEY.
'
'The macros defined below are simple examples which you can replace with your
'own.  This version of PDQKEY uses about 6.5K of memory, compared to 59K
'taken by Borland's SuperKey.  PDQKEY is of course much less capable than
'SuperKey, but it performs all that is usually needed.
'
'It is important to point out that the method used here may not cooperate
'with other TSR keyboard handlers.  For example, PDQKEY does not work with
'the QuickBASIC editor, because it installs its own replacement keyboard
'handler.  However, I have not encountered any problems using PDQKEY with any
'other programs.
'
'Also see the MACRO.BAS program which is newer, and is more direct if you
'only need to handle keyboard macros.
'
'To take as little memory from DOS as possible, compile and link as follows:
'
'   BC PDQKEY /o;
'   LINK /NOD /NOE PDQKEY STR02048 _NOVAL _NOREAD , , NUL, PDQ



'***************************************************************************
'*******************  PDQKEY.BAS - Keyboard Macro TSR  *********************
'***************************************************************************


'-- Recommended statements for any P.D.Q. program.

DEFINT A-Z                              'declare integer variables

'$INCLUDE: 'PDQDECL.BAS'                'declarations and type definitions

'-- Define variables and constants

DEF SEG = 0                             'for peeking keyboard info
CONST NumMacros = 10                    'the number of macros we're handling
DIM Registers9 AS RegType               'RegType for interrupt 9 processing
DIM Registers8 AS RegType               'RegType for interrupt 8 prcessing
DIM Macro$(0 TO NumMacros)              'dimension array of macro strings
Zero$ = CHR$(0)                         'this saves a few bytes later by
                                        '  avoiding calls to CHR$ repeatedly
                                        '  (CHR$ is a called routine)
'-- Start Execution

    Id$ = "PDQKEY 1.00 Copyright (c) 1990 Crescent Software"
    PRINT Id$

'-- Install, UnInstall, and Help

    Segment = TSRInstalled(Id$)

    Switch$ = UCASE$(COMMAND$)
    IF Switch$ = "" THEN
        IF Segment <> 0 THEN
            PRINT "PDQKEY is Already Installed"
            PRINT "Use PDQKEY /U to Uninstall"
            END
        END IF
    ELSEIF Switch$ = "/U" THEN
        IF Segment = 0 THEN
            PRINT "PDQKEY Is Not Resident and Cannot be Uninstalled"
            END
        ELSE
            Success = UnHookInt(Registers9, Segment)
            GOSUB Check
            Success = UnHookInt(Registers8, Segment)
            GOSUB Check
            Success = DeInstallTSR(Segment, Id$)
            GOSUB Check
            PRINT "PDQKEY is Removed from Memory"
            END
        END IF
    ELSE
        PRINT "PDQKEY Usage:   Install   - PDQKEY"
        PRINT "                UnInstall - PDQKEY /U"
        END
    END IF

    PRINT "PDQKey is Resident in Memory"

'-- Define Macros.  The CHR$(13) below shows how to also type an Enter.  To
'   define an extended key, use a CHR$(0) plus the extended key's code.  For
'   example, to stuff the F1 key use CHR$(0) + CHR$(59).  The second example
'   below enters an up arrow after the string.

    Macro$(1) = "REM  -  F1 Key Hit  -  F1 Key Hit" + CHR$(13)
    Macro$(2) = "REM  -  F2 Key Hit  -  F2 Key Hit" + CHR$(0) + CHR$(72)
    Macro$(3) = "REM  -  F3 Key Hit  -  F3 Key Hit  -  F3 Key Hit"
    Macro$(4) = "REM  -  F4 Key Hit  -  F4 Key Hit  -  F4 Key Hit"
    Macro$(5) = "REM  -  F5 Key Hit  -  F5 Key Hit  -  F5 Key Hit"
    Macro$(6) = "REM  -  F6 Key Hit  -  F6 Key Hit  -  F6 Key Hit"
    Macro$(7) = "REM  -  F7 Key Hit  -  F7 Key Hit  -  F7 Key Hit"
    Macro$(8) = "REM  -  F8 Key Hit  -  F8 Key Hit  -  F8 Key Hit"
    Macro$(9) = "REM  -  F9 Key Hit  -  F9 Key Hit  -  F9 Key Hit"
    Macro$(10) = "REM  - F10 Key Hit  -  F10 Key Hit  -  F10 Key Hit"


'-- Set up keyboard Interrupt 9, jump to set up Int 8.

    Registers9.IntNum = 9                   'specify keyboard interrupt 9
    PointIntHere Registers9                 'setup interrupt entry point
    GOTO Install8                           'skip to interrupt 8 setup
10                                     'this line number is needed for VB/DOS


'-- This block of code receives control each time a key is pressed.

    IntEntry1                               'mandatory first two steps for
    IntEntry2 Registers9, Zero              '  any P.D.Q. interrupt routine

    ScanCode = INP(&H60)                    'first get the key press manually
    ShiftMask = PEEK(&H417) AND &HF         'then get the shift status

    SELECT CASE ScanCode + 256 * ShiftMask  'this is the key that was pressed
    'see the P.D.Q. manual "hot key" section for an explanation of hot keys

    CASE &H3B
        ThisKey = 1                         'F1
    CASE &H3C
        ThisKey = 2                         'F2 Key
    CASE &H3D
        ThisKey = 3                         'F3 Key
    CASE &H3E
        ThisKey = 4                         'F4 Key
    CASE &H3F
        ThisKey = 5                         'F5 Key
    CASE &H40
        ThisKey = 6                         'F6 Key
    CASE &H41
        ThisKey = 7                         'F7 Key
    CASE &H42
        ThisKey = 8                         'F8 Key
    CASE &H43
        ThisKey = 9                         'F9 Key
    CASE &H44
        ThisKey = 10                        'F10 Key

    CASE ELSE

'-- The key pressed was not one we are recognizing, so call the original
'   interrupt handler to translate the scan code to an ASCII or extended
'   value.  This would place characters into the keyboard buffer and disturb
'   characters which may already be there.  For this reason, we reserve
'   keyboard buffer addresses &H3A - &H3D for interpreting key presses.
'   The buffer head and tail are saved, moved and restored for this purpose.

        ThisKey = 0
        OldHead = PDQPeek2%(&H41A)          'save keyboard buffer head
        OldTail = PDQPeek2%(&H41C)          'save keyboard buffer tail
        PDQPoke2 &H41A, &H3A                'move head to reserved area
        PDQPoke2 &H41C, &H3A                'move tail also
        CallOldInt Registers9               'call the BIOS to interpret press
                                            'if no characters end up in the
                                            'buffer (Shift, Alt, etc.) then
                                            'simply ignore
       
        IF PDQPeek2%(&H41A) = PDQPeek2%(&H41C) THEN GOTO Ignore

'-- Get ASCII code from the buffer and convert to a string.
       
        ThisChar = PDQPeek2%(&H400 + PDQPeek2%(&H41A))

        SELECT CASE ThisChar AND 255        'check the low byte
           CASE 0, 224, 240                 'treat these as extended
                Macro$(0) = Zero$ + CHR$(ThisChar \ 256)    'alt. cursor keys
           CASE ELSE                        'it's a normal key
                Macro$(0) = CHR$(ThisChar)
        END SELECT

    END SELECT

'-- This code adds the macro or other key to the master keypress queue.

    Queue$ = Queue$ + Macro$(ThisKey)       'add the macro to master queue
    QueueEmpty = 0                          'set macro pending flag

Ignore:

    IF ThisKey = 0 THEN                     'if not a macro key then
        PDQPoke2 &H41A, OldHead             'reset keyboard buffer head
        PDQPoke2 &H41C, OldTail             'reset keyboard buffer tail
    ELSE
        ResetKeyboard                       'we're handling this ourselves
    END IF
    ReturnFromInt Registers9                'return to the underlying program


'-- Set up the intercept for timer Interrupt 8.

Install8:

    Registers8.IntNum = 8                   'specify Interrupt 8
    PointIntHere Registers8                 'setup interrupt entry point
    GOTO EndIt                              'jump to finish installation
20                                     'this line number is needed for VB/DOS


'-- This block of code receives control each time a timer tick occurs.
   
    IntEntry1                               'required first two steps for any
    IntEntry2 Registers8, Zero              'P.D.Q. interrupt service routine

'-- See if we need to do anything, get out as quickly as possible if not.
'   We'll stuff the keystrokes one by one, but only when the keyboard buffer
'   is empty.

    IF QueueEmpty GOTO Done8                'no macro is pending, bye bye

    IF PDQPeek2%(&H41A) = PDQPeek2%(&H41C) THEN 'if the keyboard buffer empty
        PDQPoke2 &H41A, &H1E                'set buffer head to start address
        PDQPoke2 &H41C, &H1E                'set the buffer tail there too
        IF LEN(Queue$) < 14 THEN            'if 13 or less keys in queue then
            stuff$ = Queue$                 'stuff entire queue
            Queue$ = ""                     'clear the queue
            QueueEmpty = -1                 'set queue empty flag
        ELSE                                'if more than 13 chars in queue
            IF MID$(Queue$, 13, 1) <> Zero$ THEN 'if last char isn't CHR$(0)
                stuff$ = LEFT$(Queue$, 13)       'stuff only 12 characters
                Queue$ = MID$(Queue$, 14)        'and update the queue
            ELSE
                stuff$ = LEFT$(stuff$, 12)       'stuff 13 characters
                Queue$ = MID$(Queue$, 13)        'update the queue
            END IF
        END IF
        StuffBuf stuff$                     'stuff the keyboard buffer
    END IF

Done8:

    GotoOldInt Registers8                   'return to underlying program

EndIt:

    EndTSR Id$                              'exit while staying resident



'****************************  Subroutine  ******************************

Check:
                                            'check the uninstall success
    IF NOT Success THEN
        PRINT "Error Uninstalling - Please Reboot"
        END
    END IF

    RETURN

