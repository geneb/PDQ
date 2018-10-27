'********** SHELL.BAS - allows shelling from within any application

'Copyright (c) 1990 Crescent Software
'written by Paul Passarelli

'VERY IMPORTANT: SHELL cannot be successfully invoked while a low-numbered
'DOS service is in progress.  Therefore, this program sets up a separate trap
'for Interrupt 21h, and maintains a flag for those services.  Attempting to
'SHELL in that case will simply BEEP as a warning.
'
'To take as little memory as possible when resident, compile/link like this:
'
'       BC SHELL /O;
'       LINK /NOE /NOD SHELL STR00256 _NOREAD _NOVAL _NOERROR , , NUL, PDQ
'       EXE2COM SHELL
'
'In general, using SHELL from within a TSR is not advisable.  However, there
'may be occasions when that is necessary.  This program shows the steps you
'should follow, in particular how to allocate and release the memory that DOS
'will need to execute another copy of COMMAND.COM.
'
'As implemented here, only 60K or so memory will be available when you SHELL
'to DOS from within an application.  This will be enough for FORMAT and COPY
'to work with.  But to increase that, you should allocate a second block of
'memory, perhaps another full 64K.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Reg21 AS RegType                   'RegType is defined in PDQDECL.BAS
FourK = 4000                           'variables speed up the .asm calls
Minus1 = -1                            'claim 65535 bytes
   
ScreenSeg = AllocMem%(FourK)           'ScreenSeg holds the saved screen
IF ScreenSeg = 0 THEN
   PRINT "Unable to allocate memory - ending"
   END
END IF

ShellSeg = AllocMem%(Minus1)           'ShellSeg reserves memory for COMMAND
IF ShellSeg = 0 THEN
   PRINT "Unable to allocate memory - ending"
   END
END IF

DEF SEG = 0                            'peek lo-mem for the active video
IF PEEK(&H463) = &HB4 THEN
   VideoSeg = &HB000                   'it's monochrome
ELSE
   VideoSeg = &HB800                   'it's color
END IF

ID$ = "Shell 1.1 -- activate with Ctrl-Alt-S"
PRINT ID$

CALL PopUpHere(&HC1F, ID$)             '&HC = Ctrl-Alt, &H1F = S
GOTO Trap21                            'continue to trap Int 21h
10                                     'this line number is needed for VB/DOS

'---- this is where we come every time the hot-key is pressed
IF Failed GOTO RetToApp                'we had an earlier allocation error

SaveCsr& = CursorSave&                 'save the current cursor parameters

IF Flag21 THEN                         'a low-numbered service is in progress
   BEEP                                'warn 'em
   GOTO RetToApp                       'ignore the request
END IF

BlockCopy VideoSeg, Zero, ScreenSeg, Zero, FourK    'save the screen

'The lines that are commented out below are not really necessary for the
'operation of this program.  Further, those conditions should never occur.
'If they do, something very serious went wrong and the PC should be rebooted.
   
Failed = ReleaseMem%(ShellSeg)         'release the memory for COMMAND.COM
'IF NOT Failed THEN                    'if the memory was released okay
   CLS                                 'clear the screen
   CALL CursorOn                       'make sure the cursor is visible
   InShell = -1                        'flag that we've shelled to DOS
   SHELL                               'drop down to DOS until EXIT is typed
   InShell = 0                         'okay to handle Int 21h below now
   CALL BlockCopy(ScreenSeg, Zero, VideoSeg, Zero, FourK) 'restore the screen
   ShellSeg = AllocMem%(Minus1)        'reclaim the memory again for later
'  IF ShellSeg = 0 THEN                'see if we were able to claim memory
'     Failed = -1                      'no, remember that this failed
'     BEEP                             '(though that should never happen)
'  END IF
'ELSE
'   BEEP                               'we were unable to release the memory
'END IF                                '(this is unlikely too)

RetToApp:
CALL CursorRest(SaveCsr&)              'restore the cursor size and location
CALL PopDown                           'return to the underlying application



'---- Take over Interrupt 21h here

Trap21:
Reg21.IntNum = &H21                    'specify trapping Interrupt 21h
CALL PointIntHere(Reg21)
GOTO EndIt                             'skip over and out
20                                     'this line number is needed for VB/DOS

CALL IntEntry1                         'control comes here at each interrupt
CALL IntEntry2(Reg21, Zero)
IF InShell GOTO Spaghetti              'I'd rather have spaghetti code than
                                       '  two 9-byte calls to GotoOldInt....
Service = Reg21.AX \ 256               'read the service number from AH
IF Service = 0 THEN                    'some old programs end with service 0
   Reg21.AX = Reg21.AX OR &H4C00       'change it to the newer DOS 2.x value
   Service = &H4C                      '(We have to do this, because calling
END IF                                 '  DOS to end means it never returns!)

IF Service > &HC THEN
Spaghetti:
  CALL GotoOldInt(Reg21)               'high service numbers are okay
END IF

Flag21 = Flag21 + 1                    'show we're in progress
CALL CallOldInt(Reg21)                 'call the interrupt handler
Flag21 = Flag21 - 1                    'we're okay now
CALL ReturnFromInt(Reg21)              'all done here

EndIt:
CALL EndTSR(ID$)

