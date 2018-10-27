'********* TIMER.BAS - shows how to emulate BASIC's TIMER function

'Copyright (c) 1989 Crescent Software
' . . . with special thanks to Bruce Tonkin


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'


'----- The code below lets us synchronize PDQTimer with the system clock.
'      That is, it waits until a new 1/18th second period has just begun,
'      thus eliminating the potential to under-report the time by as much
'      as 1/18th of a second.
OldTime& = PDQTimer&            'get the current timer count
DO
   SyncTime& = PDQTimer         'see what the count is now
LOOP WHILE OldTime& = SyncTime& 'wait until the next period just begins


'----- This code shows how to time an empty FOR/NEXT loop, while obtaining
'      results in seconds and hundreths as is possible with QuickBASIC.
Start& = PDQTimer&              'start timing
FOR X& = 1 TO 100000            'do something that'll take a while
    Z& = Z& + 1
NEXT
Done& = PDQTimer&               'done timing


'----- Now calculate the hundredth seconds based on 18.207 ticks per second.
ScaledUp& = 100000 * (Done& - Start&) \ 18207
PRINT
PRINT "The empty FOR/NEXT loop took "; Dollar$(ScaledUp&); " seconds."

