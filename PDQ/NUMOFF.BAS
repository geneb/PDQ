'********** NUMOFF.BAS - turns off NumLock, add it to your AUTOEXEC.BAT file

'Copyright (c) 1989 Ethan Winer


'To make a REALLY small file from this program do this:
'
'   BC numoff /o;
'   LINK /nod /noe numoff _noread _noval _noerror , , nul , smalldos pdq


DEFINT A-Z

DEF SEG = 0
POKE &H417, PEEK(&H417) AND &HDF

