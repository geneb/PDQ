'********** NOBEEP.BAS - TSR that disables the PC speaker from beeping

'Copyright (c) 1989 Crescent Software


'To have this program take as little memory as possible when resident you
'should compile and link as follows:
'
'   BC nobeep /o;
'   LINK /noe /nod nobeep str00256 _noval _noread, , nul, pdq

DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS
Registers.IntNum = &H10         'specify trapping video Interrupt 10h

ID$ = "NOBEEP 1.0 installed"
PRINT ID$

PointIntHere Registers          'after this, every Int 10h will go to the
GOTO EndIt                      '  the next line below (CALL IntEntry1)
10                              'this line number is needed for VB/DOS

IntEntry1                       'come here when a program prints via the BIOS
IntEntry2 Registers, Zero       '0 means wait until resident to work

IF Registers.AX = &HE07 THEN    'if they're printing a CHR$(7)
  'PDQSound 1000, 2             'optionally substitute a short 1KHz. tone
   ReturnFromInt Registers      'and then ignore the print request
END IF
  
GotoOldInt Registers            'continue to the original interrupt handler

EndIt:
EndTSR (ID$)                    'terminate and stay resident

