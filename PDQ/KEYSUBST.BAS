'********* KEYSUBST.BAS - shows how to substitute "modifier" keys in a TSR

'Copyright (c) 1993 Crescent Software
'With a special thanks for the core code submitted by Matt Hart

'This demo substitutes the CapsLock and Ctrl keys.  Modify to suit.

' bc keysubst /o;
' link /far/packc/nod/noe _
'   keysubst _noread _noerror _noval str00256, , nul, pdq;
' exe2com keysubst


DEFINT A-Z

'$INCLUDE: 'PDQDECL.BAS'

DIM Regs AS RegType                 'RegType is defined in PDQDECL.BAS

ID$ = "KEYSUBST installed"          'define the unique ID string
PRINT ID$                           'print the sign-on message

Regs.IntNum = &H15                  'specify trapping Interrupt 15h
DEF SEG = &H40                      'for the PEEK below

CALL PointIntHere(Regs)             'every Int 9 will now go to the next
GOTO EndIt                          '  line below (CALL IntEntry1)
10                                  'this line number is needed for VB/DOS

CALL IntEntry1
CALL IntEntry2(Regs, Zero)

IF Regs.AX AND &H4F00 THEN
   EnhKey = PEEK(&H96) AND 3
   IF EnhKey = 0 THEN
     MakeBreak = Regs.AX AND &HFF
     SELECT CASE MakeBreak
       CASE &H3A                    'CapsLock make code
         Regs.AX = Regs.AX AND &HFF00 OR &H1D 'Cvt to Ctrl make
       CASE &HBA                    'CapsLock break code
         Regs.AX = Regs.AX AND &HFF00 OR &H9D 'Cvt to Ctrl break
       CASE &H1D                    'Ctrl make code
         Regs.AX = Regs.AX AND &HFF00 OR &H3A 'Cvt to Caps Lock make
       CASE &H9D                    'Ctrl break code
         Regs.AX = Regs.AX AND &HFF00 OR &HBA 'Cvt to Caps Lock break
     END SELECT
   END IF
END IF

CALL GotoOldInt(Regs)

EndIt:
CALL EndTSR(ID$)                    'exit while staying resident
