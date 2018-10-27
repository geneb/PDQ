'-------- DEMOINT8.BAS - demonstrates DOS file access based on timer Int 8

'Copyright (c) 1991 Ethan Winer

'Compile as follows:
'
' bc demoint8 /o;
' link /far/packc/nod/noe/ex demoint8 _noread _noerror _noval str00256,,nul,pdq
' exe2com demoint8


DEFINT A-Z                      'always use integers

'$INCLUDE: 'PDQDECL.BAS'        'this holds Declares and defines RegType

DIM Registers AS RegType        'create the TYPE variable
CONST TenSeconds% = 182         '10 * 18.2 ticks per second

One = 1                         'using variables speeds things up later
Twenty = 20
Hi = 1500
Lo = 1200

ID$ = "DEMOINT8 V1.10"          'all TSR programs need an ID string
FileName$ = "yourfile.dat"      'the file name to search for
PRINT ID$                       'print it


'---- Trap timer Interrupt 8, and get control at each timer tick
Registers.IntNum = 8            'specify trapping Int 8
CALL PointIntHere(Registers)    'trap the interrupt
GOTO Simple                     'skip past the Int 8 handler to install PopUp
10                              'this line number is needed for VB/DOS

CALL IntEntry1                  'we arrive here at each timer tick
CALL IntEntry2(Registers, Zero) 'these are the two mandatory calls

CALL CallOldInt(Registers)      'ALWAYS call the original interrupt first
                                '  when taking over the timer interrupt

Counter = Counter + 1           'show that another tick happened
IF Counter >= TenSeconds% THEN         '>= in case PopRequest failed earlier
   Dummy = PopRequest%(Flag, Twenty)   'try for a second to pop up
END IF

CALL ReturnFromInt(Registers)   'return to the underlying application


'---- Install the pop-up handler that services the hot key and disk requests
Simple:
CALL PopUpHere(0, ID$)          '0 = no hot key recognized
GOTO EndIt                      'continue on and end as a TSR
20                              'this line number is needed for VB/DOS

IF NOT Registers.BusyFlag THEN  'if the interrupt isn't now busy
   Counter = 0                  'first reset the counter
   IF PDQExist%(FileName$) THEN 'if the file is present
     CALL PDQSound(Hi, One)     'make a chime sound
     CALL PDQSound(Lo, One)
     CALL PDQSound(Hi, One)
     CALL PDQSound(Lo, One)
   END IF
END IF
  
CALL PopDown                    'and pop down

EndIt:
CALL EndTSR(ID$)                'terminate and stay resident

