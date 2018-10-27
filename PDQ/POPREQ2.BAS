  '***** POPREQ2.BAS - example from the manual section "Using PopRequest"
 
  DEFINT A-Z
  '$INCLUDE: 'PDQDECL.BAS'

  DIM Reg8 AS RegType
  DIM Reg9 AS RegType
  ID$ = "Pop me up with Alt-A, Alt-B, or Alt-C"
  PRINT ID$


  '-- Set up the manual interrupt 8 handler.
  Reg8.IntNum = 8                'specify timer interrupt 8
  CALL PointIntHere(Reg8)        'trap the interrupt
  GOTO Trap9                     'go install the Int 9 handler
10                               'this line number is needed for VB/DOS

  CALL IntEntry1                 'arrive here at each timer tick
  CALL IntEntry2(Reg8, Action)
  CALL CallOldInt(Reg8)          'first defer to original handler

  Ticks = Ticks + 1              'another 1/18th second has passed
  IF Ticks > 182 THEN            'but has ten seconds passed yet?
    Success = PopRequest(Flag8, 18)  'try to pop up for one second
  END IF

  CALL ReturnFromInt(Reg8)       'all done with this timer tick


Trap9:
  '-- Set up the manual interrupt 9 handler.
  Reg9.IntNum = 9                'specify keyboard interrupt 9
  CALL PointIntHere(Reg9)        'trap the interrupt
  GOTO PopUp                     'go set up the popup handler
20                               'this line number is needed for VB/DOS

  CALL IntEntry1                 'arrive here at each timer tick
  CALL IntEntry2(Reg9, Action)

  IF TestHotKey%(&H81E) THEN     'test for each possible key, and
     KeyHit$ = "Alt-A"           '  assign a string based on which
  ELSEIF TestHotKey%(&H830) THEN '  key it was
     KeyHit$ = "Alt-B"
  ELSEIF TestHotKey%(&H82E) THEN
     KeyHit$ = "Alt-C"
  ELSE
     CALL GotoOldInt(Reg9)       'not our key, defer to the BIOS
  END IF

  CALL ResetKeyboard             'eat the key, clear the hardware
  Success = PopRequest(Flag9, 18)'try to pop up for one second
  IF NOT Success THEN
     'If PopRequest failed because the timer handler's PopRequest
     '  was already in progress, then ignore it.  But you could set
     '  other flags here and perhaps try again later.
  END IF

  CALL ReturnFromInt(Reg9)       'all done with keyboard handler


PopUp:
  '-- Set up the simplified pop-up handler.
  CALL PopUpHere(0, ID$)         '0 disables hot key detection
  GOTO EndIt                     'skip over and end as a TSR
30                               'this line number is needed for VB/DOS

  '-- We get here if any of the recognized hot keys are pressed,
  '   and also every ten seconds.
  IF Flag8 THEN                  'if non-zero the timer got us here
    PRINT "The timer handler sent me here."
    Flag8 = 0                    'clear the service flag for later
    Ticks = 0                    'and start a new 10-second period
  ELSEIF Flag9 THEN              'otherwise Int9 sent us here
    PRINT "You pressed hot key "; KeyHit$
    Flag9 = 0
  END IF

  CALL PopDown                   'either way, pop down


EndIt:
  CALL EndTSR(ID$)               'terminate and stay resident

