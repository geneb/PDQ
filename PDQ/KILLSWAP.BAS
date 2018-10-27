'************ KILLSWAP.BAS - removes a swapping TSR program from memory

'Copyright (c) 1991 Ethan Winer


'Note: This program expects a command-line parameter to specify the program
'ID code for the TSR being removed.  If no parameter is given it defaults to
'&H830, which is the ID for DEMOSWAP (the Alt-B hot key)

DEFINT A-Z

'$INCLUDE: 'pdqdecl.bas'

DIM Registers AS RegType

DEF SEG = 0                         'first check if Interrupt &HAA is valid
Address = PDQPeek2%(&HAA * 4)       'by verifying that either the address or
Segment = PDQPeek2%(&HAA * 4 + 2)   '  segment is non-zero
IF (Segment OR Address) = 0 THEN    'oops
  PRINT "No swapping TSR is resident!"
  END
END IF

ID = PDQValI%(COMMAND$)             'get the ID passed on the command line
IF ID = 0 THEN ID = &H830           'if none use the program ID for DEMOSWAP

Registers.AX = ID                   'specify the ID of the program to remove
Registers.BX = 1                    'this is the SwapCode flag to deinstall
Registers.CX = 18 * 5               'try for 5 seconds to get CAP's attention
CALL Interrupt(&HAA, Registers)     'call the resident kernal

PRINT "TSR successfully removed"    'report success

