'********* RANDOM.BAS - shows how to use the SMALLDOS OPEN for random access

'Copyright (c) 1989 Ethan Winer

'This program must be compiled to disk to run, because the file is opened
'for OUTPUT, and then PUT is used to write to it.  (That's illegal in QB.)


DEFINT A-Z
'$INCLUDE: 'PDQDECL'

TYPE MyType
   X AS INTEGER
   Y AS LONG
   Z AS STRING * 20
END TYPE

DIM Buffer AS MyType
DIM Array(1 TO 10) AS MyType

FOR X = 1 TO 10
    Array(X).X = X
    Array(X).Y = -X
    Array(X).Z = STR$(X)
NEXT

OPEN "Random.Dat" FOR OUTPUT AS #1      'this also works for random access!
FOR Record = 1 TO 10                    'write out ten records
    PUT #1, , Array(Record)
NEXT

FOR Record = 10 TO 1 STEP -1            'now read the records back again
    GET #1, SeekLoc&(Record, LEN(Buffer)), Buffer
    PRINT Buffer.X, Buffer.Y, "{"; Buffer.Z; "}"
NEXT
CLOSE #1

