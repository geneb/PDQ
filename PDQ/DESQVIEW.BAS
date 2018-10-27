'********** DESQVIEW.BAS - shows how to create a DESQview-aware program

'Submitted by Crescent friend Alex Boge

'Link with _STR$.OBJ for the correct printed appearance.


DEFINT A-Z

'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS

MonType = PDQMonitor%
PRINT "Monitor type = "; MonType

SELECT CASE MonType
   CASE 1, 2, 4, 6, 8
      Registers.ES = &HB000     'monochrome
   CASE ELSE
      Registers.ES = &HB800     'color
END SELECT

PRINT "Physical video buffer = "; HEX$(Registers.ES); ":";
PRINT RIGHT$("000" + HEX$(Registers.DI), 4)             'force to 4 digits

Registers.CX = &H4445                   'set to invalid date  CX = "DE"
Registers.DX = &H5351                   'spells "DESQ"!       DX = "SQ"
Registers.AX = &H2B01   'set system date + AL = 1 (get DV version info in BX)
CALL Interrupt(&H21, Registers)

IF (Registers.AX AND 255) = &HFF THEN   'if it's "bad" then...
   PRINT "Running under DOS only."
   END
ELSE                                    'get version number from BX
   Major = Registers.BX \ 256
   Minor = Registers.BX AND 255
   PRINT "Running under DesqView version "; STR$(Major); "."; Minor

   Registers.AX = &HFE00                'get logical buffer address
   Registers.DI = 0
   CALL InterruptX(&H10, Registers)
   PRINT " Logical video buffer = ";
   PRINT HEX$(Registers.ES); ":"; HEX$(Registers.DI)
END IF

CALL PDQSetMonSeg(Registers.ES)         'subsequent printing using PDQPrint
                                        '  et. al. now goes to the DV segment
