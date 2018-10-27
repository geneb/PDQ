'********** SPEEDUP.BAS - speed-up program for AT-style keyboards

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z

OUT &H60, &HF3          'get the keyboard's attention
FOR D& = 1 TO 100       'a brief delay to give the hardware time to settle
NEXT
Value = &H8             'see the table for this value (in Hex notation)
OUT &H60, Value

'The table below lists the Hex numbers to use for Value in the program above.
'You may control both the initial delay (the delay time before the characters
'begin repeating), and the repeat rate.  All of the possible values for the
'Characters Per Second parameter are not shown.   For example, any numbers
'between 30 and 16 CPS are valid, such as 01, 02, 03, through 06.


'                Table of keyboard delay and repeat rates (Hex)
'       ================================================================
'
'                             0.25    0.50    0.75    1.00 <--- initial delay
'                             ====    ====    ====    ====
'  30 characters per second:   00      20      40      60
'                                  .
'                                  .
'  16 characters per second:   07      27      47      67
'                                  .
'                                  .
'   8 characters per second:   0F      2F      4F      6F
'                                  .
'                                  .
'   4 characters per second:   17      37      57      77
'                                  .
'                                  .
'   2 characters per second:   1F      3F      5F      7F

