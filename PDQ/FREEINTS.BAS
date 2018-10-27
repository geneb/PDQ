'********** FREEINTS.BAS - shows how to see which interrupts are free

'Copyright (c) 1991 Ethan Winer


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

CLS
PRINT "Available interrupt vectors:"
PRINT

FOR X = 0 TO 255                       'examine all 256 interrupt vectors
  DEF SEG = 0                          'the vector table is in segment 0
  ReportIt = 0                         'assume we won't report this interrupt
  Star$ = "  "                         'and that it doesn't point to an IRET
  Address = PDQPeek2%(X * 4)           'get the interrupt handler's address
  Segment = PDQPeek2%(X * 4 + 2)       'and its segment two bytes later
  DEF SEG = Segment                    'look in this segment
  OpCode = PEEK(Address)               'read the first byte that "executes"

  IF OpCode = &HCF THEN                '&HCF is the opcode for IRet
    ReportIt = -1
    Star$ = " *"
  ELSEIF (Segment OR Address) = 0 THEN 'unassigned means available too
    ReportIt = -1
  END IF

  IF ReportIt THEN                      'report this interrupt if appropriate
    PRINT RIGHT$("0" + HEX$(X), 2); Star$; SPC(6); 'add leading "0" as needed
  END IF
NEXT

PRINT : PRINT
PRINT "* = Interrupt vector points to an IRET instruction."

