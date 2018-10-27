'********** MAPDEV.BAS - variation on MAP.BAS displays loaded device drivers

'Copyright (c) 1992 Robert L. Hummel


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DEF FnDisp$ (Number) = RIGHT$("000" + HEX$(Number), 4)

'---- Print the identification and column heads.
'
PRINT "MAPDEV 1.0 Copyright (c) 1992 Robert L. Hummel"
PRINT
PRINT "Type   Name/Units  Hdr Address"
PRINT "-----  ----------  -----------"


'---- Select the header address based on the DOS version.
'
SELECT CASE DOSVer%
  CASE IS < 300                 'DOS 2.x
    HeaderAdr = &H17
  CASE IS < 310                 'DOS 3.0
    HeaderAdr = &H28
  CASE ELSE                     'DOS 3.1 - 5.0
    HeaderAdr = &H22
END SELECT


'---- Invoke the undocumented DOS GetIVars function.
'     Pointer is returned in ES:BX.
'
DIM Regs AS RegType             'RegType is defined in PDQDECL.BAS
Regs.AX = &H5200
CALL InterruptX(&H21, Regs)
HeaderAdr = HeaderAdr + Regs.BX
Segment = Regs.ES


'---- ES:Header now points to the header for the NUL device.
'
'  0  DD  Far pointer to next driver -- offset = &HFFFF for end of chain
'  4  DW  Device attribute word
'  6  DW  Strategy routine offset
'  8  DW  Interrupt routine offset
' 10      Char device:  8 character device name, blank filled
'         Block device: 1 byte = number of units in driver
'
'---- Point to the header segment and get the attribute word.
'     If the highest bit is set the driver is a character device.
'     For char print the name, for block print the number of units.
DO WHILE HeaderAdr <> &HFFFF

   DEF SEG = Segment
   Attr = PDQPeek2%(HeaderAdr + 4)
  
   IF Attr AND &H8000 THEN              'character device
     PRINT "Char   ";
     FOR J = 0 TO 7
       PRINT CHR$(PEEK(HeaderAdr + 10 + J));
     NEXT
   ELSE                                 'block device
     PRINT "Block "; PEEK(HeaderAdr + 10);
   END IF

   PRINT TAB(20); FnDisp$(Segment); ":"; FnDisp$(HeaderAdr)

   Segment = PDQPeek2%(HeaderAdr + 2)   'point to next driver
   HeaderAdr = PDQPeek2%(HeaderAdr)     ' in the chain

LOOP

