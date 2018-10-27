'********* DEMOBUF.BAS - performs very fast buffered sequential file input

DEFINT A-Z

'----- Declare this manually (rather than use PDQDECL.BAS) so the alternate
'      DECLARE statements below won't conflict with PDQDECL.BAS is used.
DECLARE FUNCTION PDQTimer& ()


'----- This Declare statement is for using BufIn the "normal" way.
DECLARE FUNCTION BufIn$ (FileName$, Done)


'----- These Declare statements save seven bytes per invocation of BufIn, by
'      avoiding the copying that BASIC performs for all string functions.
'      (B$SASS is BASIC's string assignment routine, called directly here.)
'      But more important than the seven bytes saved, BASIC's copying also
'      impinges on string space.  The length of the most recently returned
'      string steals string memory, until the next time BufIn is called.
'DECLARE FUNCTION BufIn% (FileName$, Done)
'DECLARE SUB Assign ALIAS "B$SASS" (BYVAL FromAddress, Dest$)

LINE INPUT "Enter a file name: ", FileName$

Start& = PDQTimer&
DO
   This$ = BufIn$(FileName$, Done)       'read the file the "normal" way
'  Assign BufIn%(FileName$, Done), This$ 'read the file the "low-code" way
   IF Done THEN EXIT DO                  'until done
'  PRINT This$                           'unREM to watch it work (but the
LOOP                                     '  (timings will be way off!)
Done& = PDQTimer&
PRINT "Buffered input: "; Done& - Start&

Start& = PDQTimer
OPEN FileName$ FOR INPUT AS #1
DO
   LINE INPUT #1, This$
'  PRINT This$
LOOP UNTIL EOF(1)
Done& = PDQTimer&
PRINT " BASIC's INPUT: "; Done& - Start&
CLOSE

