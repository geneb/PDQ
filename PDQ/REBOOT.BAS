'********** REBOOT.BAS - reboots the PC (warm boot, no power-on self-test)

'Copyright (c) 1990 Ethan Winer


'Compile and link as follows for the smallest program:
'
'  BC reboot /o;
'  LINK /nod /noe /packc /far reboot _noread _noval _noerror , , nul , pdq;
'  EXE2COM reboot


DEFINT A-Z

DEF SEG = 0                     'first indicate a warm boot
CALL PDQPoke2(&H472, &H1234)    'by writing 1234h at address 0000:0472h
DEF SEG = &HFFFF                'then call the boot routine in BIOS
CALL Absolute(0)                'at address FFFF:0000h

