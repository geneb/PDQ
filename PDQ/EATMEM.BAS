'*********** EATMEM.BAS

'Copyright (c) 1992 Ethan Winer

'This simple utility does nothing but eat up memory, so you can simulate
'running your programs on a machine with less RAM than your own.
'
'Usage:
'
'  EATMEM n
'
'Where n is the number of KILOBYTE blocks (1024 bytes each) to eat.
'
'Compile and link as follows:
'
'  bc eatmem /o;
'  link /nod/noe/far/packc _
'    eatmem str00512 _noval _noerror _noread, , nul, [basic7] pdq ;


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

CONST ProgSize% = 4544                  'minimum size, determined empirically
                                        '  using QB 4.5, may change with PDS
ID$ = "EATMEM 1.0,"

NumK = PDQValI%(COMMAND$)               'how many KBytes do they want to eat?
NumBytes& = (NumK * 1024&) - ProgSize%  'total number of bytes to eat
IF NumBytes& < 0 THEN NumBytes& = 0     'can't eat less than ProgSize%
PRINT ID$; NumBytes& + ProgSize%; "bytes eaten."

NumBlocks = NumBytes& \ 65535           'how many 64K blocks (for big eats)
LastBlock = NumBytes& MOD 65535         'and how much beyond that

FOR X = 1 TO NumBlocks                  'eat that many 64K blocks
  Dummy = AllocMem%(65535)
NEXT
Dummy = AllocMem%(LastBlock)            'and eat the remainder

CALL EndTSR(ID$)
