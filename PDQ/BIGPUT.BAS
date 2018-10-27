'********** BIGPUT.BAS - demonstrates saving/loading an entire array

'Copyright (c) 1989 Ethan Winer

'This program shows how to load and save entire arrays (or any area of
'memory for that matter), by calling BASIC's internal routines for GET and
'PUT.  Accessing these routines directly will be much faster than using
'individual GET or PUT commands on each array element in a FOR/NEXT loop.
'
'There are four separate routines, with two each for getting and putting.
'The first of the GET and PUT routines uses the current DOS SEEK location,
'and the others expect a long integer SEEK argument.  Because these routines
'are "internal" (and have a dollar sign within their name), the ALIAS keyword
'must be used to declare them.
'
'This program will not work in the QuickBASIC editing environment because
'the file is opened for OUTPUT, but PUT is then used to write the data.  The
'use of ALIAS this way also prevents it from being run in the QB editor.


DEFINT A-Z

DECLARE SUB BigLoad ALIAS "B$Get3" (BYVAL FileNum, SEG Address, BYVAL NumBytes)
DECLARE SUB BigLoadS ALIAS "B$Get4" (BYVAL FileNum, BYVAL SeekLoc&, SEG Address, BYVAL NumBytes)
DECLARE SUB BigSave ALIAS "B$Put3" (BYVAL FileNum, SEG Address, BYVAL NumBytes)
DECLARE SUB BigSaveS ALIAS "B$Put4" (BYVAL FileNum, BYVAL SeekLoc&, SEG Address, BYVAL NumBytes)

'Note 1: NumBytes above MUST be an integer.  DO NOT USE a long integer for
'        values between 32768 and 65536; use negative values instead based
'        on this formula:  NumBytes% = BytesNeeded& - 65536
'
'Note 2: To load or save at any segmented address, replace "SEG Address"
'        above with "BYVAL Segment, BYVAL Address".

CONST NumEls% = 100                     'the size of the test array
REDIM Array(1 TO NumEls%)               'create an integer array
FOR X = 1 TO NumEls%                    'initialize it to ascending values
    Array(X) = X
NEXT

OPEN "BigTest" FOR OUTPUT AS #1         'create the output file
BigSave 1, Array(1), NumEls% * 2        'file #1, array start, number of bytes
CLOSE #1                                'close the file

FOR X = 1 TO NumEls%                    'clear the array to prove we loaded
    Array(X) = 0                        '  it again later
NEXT

OPEN "BigTest" FOR BINARY AS #1         'open the file again
BigLoad 1, Array(1), NumEls% * 2        'load the entire array at once
CLOSE #1                                'close the file

FOR X = 1 TO NumEls%                    'print the results to prove it works
    PRINT Array(X),
NEXT

