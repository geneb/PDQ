'********** ONKEY.BAS - shows how to simulate ON KEY in a QuickBASIC program

'Copyright (c) 1989 Crescent Software

'This program will not work in the QuickBASIC editing environment, because
'the very concept of PointIntHere cannot work in the QB P-code interpreter.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS

Flag = -1
Registers.IntNum = 9            'specify trapping Interrupt 9

CLS
LOCATE 4, 1
PDQPrint "ONKEY 1.10 (c) 1989, Robert L. Hummel", 1, 1, 7
PDQPrint "Press a key to see the scan code, press ESC to end.", 2, 1, 7

PointIntHere Registers          'after this, every Int 9 will go to the
GOTO ENDIT                      '  the next line below (CALL IntEntry1)
10                              'this line number is needed for VB/DOS

'----------------------------------------------------------------------------
' This portion of the program services the keyboard interrupt in real time.
'----------------------------------------------------------------------------
IntEntry1
IntEntry2 Registers, 2          '2 means start working immediately (non-TSR)

IF TestHotKey(1) THEN Flag = 0  '1 is the Escape key

Code = INP(&H60)                'read the current scan code from the keyboard
                                'print only the "make" code, not the "break"
IF Code < 128 THEN PDQPrint HEX$(Code) + " ", 4, 1, 7   'make codes are < 128

ResetKeyboard                   'this is our key, so clear it out
CALL ReturnFromInt(Registers)   'finished handling the interrupt

'----------------------------------------------------------------------------
' This portion simply loops to allow the interrupt-driven portion to operate.
'----------------------------------------------------------------------------
ENDIT:
WHILE Flag                      'flag is modified in the interrupt handler
WEND

Flag = UnHookInt%(Registers, 0) 'you MUST unhook the interrupt before ending

