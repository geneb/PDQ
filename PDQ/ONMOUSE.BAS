'********** ONMOUSE.BAS - shows how to trap specific IRQ interrupts

'Copyright (c) 1989 Crescent Software

'This program uses the mouse as an example of trapping hardware interrupts.
'The mouse is used not because it is a useful device to intercept at this
'level, but because many (most?) programmers have one and can at least run
'this program.  One important point illustrated herein is how to enable the
'PC's PIC (Programmable Interrupt Controller), which is needed in some cases
'before a hardware interrupt can be made active.  Note that in this case, the
'mouse driver programs the PIC, so the steps shown below are redundant.  But
'the appropriate INP and OUT commands are shown so you can see what must be
'done in other situations.
'
'NOTE: ONMOUSE will not work in the QuickBASIC editing environment, because
'the very concept of PointIntHere cannot work in the QB P-code interpreter.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS

'----- Before a hardware interrupt will be recognized, the PIC (Programmable
'      Interrupt Controller) must be set to enable the specific IRQ number.
'      This is done by clearing the appropriate bit in the PIC register with
'      and AND instruction.
'
'          7 6 5 4 3 2 1 0   <--- bit (IRQ) numbers
'
'          1 1 1 0 1 1 1 1   <--- bits in the PIC mask register
'
'                ^ clear this bit to enable IRQ 4

SavePIC = INP(&H21)             'get and save the current state of the PIC
NewPIC = SavePIC AND &HEF       'clear bit 4 (the bits are numbered 0 - 7)
                                'for IRQ 3 use: NewPIC = SavePIC AND &HF7
                                '(&HEF=1110111 binary, &HF7=11110111 binary)
OUT &H21, NewPIC                'IRQ 4 is now enabled and ready for action

Registers.AX = 1                'turn on the mouse cursor just for fun
CALL interrupt(51, Registers)   'using Interrupt 51

Registers.IntNum = 12           'specify trapping IRQ 4 (IRQ number + 8)
                                '  (use 12 to trap Com1, 11 for Com2)

CALL PointIntHere(Registers)    'after this, all mouse activity jumps to the
GOTO WaitLoop                   '  next line below (CALL IntEntry1)
10                              'this line number is needed for VB/DOS

'----- the next line receives control whenever a mouse event occurs
CALL IntEntry1
CALL IntEntry2(Registers, 2)    '2 means work immediately (non-TSR mode)

CALL CallOldInt(Registers)      'finish servicing this interrupt before
                                '  doing anything else

EventNum = EventNum + 1         'count how many times a button was pressed
IF EventNum > 50 GOTO Done      '  or the mouse was jiggled, bail out at 50

OUT &H20, &H20                  'we're done handling the interrupt, so reset
CALL GotoOldInt(Registers)      '  the PIC and continue to the mouse driver

WaitLoop:
DO                              'sit here until 50 mouse events have occurred
LOOP

Done:
OUT &H21, SavePIC               'restore the original state of the PIC
Flag = UnHookInt%(Registers, 0) 'you MUST unhook the interrupt before ending

Registers.AX = 2                'now be polite and turn off the mouse cursor
CALL interrupt(51, Registers)   'using Interrupt 51

