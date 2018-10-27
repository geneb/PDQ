  '***** POPREQ1.BAS - example from the manual section "Using PopRequest"
 
  DEFINT A-Z
  '$INCLUDE: 'PDQDECL.BAS'

  DIM Regs AS RegType
  ID$ = "Pop up this program with Alt-J"
  PRINT ID$

  '-- Set up the manual interrupt 8 handler.
  Regs.IntNum = 8               'specify timer interrupt 8
  CALL PointIntHere(Regs)       'trap the interrupt
  GOTO PopUp                    'skip past the Int 8 handler
10                              'this line number is needed for VB/DOS

  CALL IntEntry1                'we arrive here at each timer tick
  CALL IntEntry2(Regs, 0)       'these are the two mandatory calls
  CALL CallOldInt(Regs)         'first defer to original handler

  Ticks = Ticks + 1             'another 1/18th second has passed
  IF Ticks > 182 THEN           'but has ten seconds passed yet?
    Dummy = PopRequest%(Flag, 18) 'yes, try to pop-up for 1 second
  END IF

  CALL ReturnFromInt(Regs)      'all done with this timer tick

  '-- Set up the simplified pop-up handler.
PopUp:
  CALL PopUpHere(&H824, ID$)    '&H824 = Alt-J
  GOTO EndIt                    'skip over and end as a TSR
20                              'this line number is needed for VB/DOS

  '-- The following block of code is executed each time Alt-J
  '   is pressed, and also every 10 seconds.
  CLS
  IF Flag THEN                  'PopRequest sent us here
    PRINT "The timer handler sent me here."
    Flag = 0                    'in case Alt-J is pressed later
    Ticks = 0                   'start a new 10-second period
  ELSE                          'Alt-J was pressed
    PRINT "You pressed Alt-J."
  END IF

  CALL PopDown                  'either way, pop down


EndIt:
  CALL EndTSR(ID$)              'terminate and stay resident

