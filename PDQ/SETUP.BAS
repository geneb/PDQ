'********** SETUP.BAS - Epson printer setup program

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'                'we need the declare for PDQValI%

CONST NumCodes% = 5                     'this forces the arrays to be Static
DIM Choice$(1 TO NumCodes%)
DIM Code$(1 TO NumCodes%)

Choice$(1) = "1) Compressed printing"   'prompt messages
Choice$(2) = "2) Enhanced printing"
Choice$(3) = "3) Tiny printing"
Choice$(4) = "4) Reset"
Choice$(5) = "5) Quit"


Code$(1) = "@"                        'these codes were entered with Ctrl-P
Code$(2) = "@EG"                     'this is much more efficient than
Code$(3) = "@S13"                   'Code$(x) = CHR$(27) + "@" + ...
Code$(4) = "@"

PRINT
FOR X = 1 TO NumCodes%                  'print the prompts
    PRINT Choice$(X)
NEXT
PRINT "Enter your selection: ";

DO                                      'wait for a keypress
   Which = PDQValI%(INKEY$)
LOOP UNTIL Which > 0 AND Which < NumCodes + 1

PRINT Which                             'echo the choice to the screen
LPRINT Code$(Which);                    'LPRINT the selected code

