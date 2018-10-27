'======================================================================
'=  DialTSR  (TSR Phone Dialer Demonstration)                         =
'=  by Jonathan Zuck                                                  =
'=  Copyright 1990, User Friendly, Inc.                               =
'=                                                                    =
'=       bc dialtsr /o;                                               =
'=       link /noe /nod dialtsr str00512 _noval _noread , , nul , pdq =
'=       exe2com dialtsr                                              =
'=                                                                    =
'======================================================================

DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType                'RegType is defined in PDQDECL.BAS
One = 1                                 'these variable save code size below
Two = 2
Three = 3
Seven = 7

DialStr$ = "ATDT"                       'These are for Hayes compatible
HangStr$ = "ATH"                        '  modems

'I chose to use the BIOS here for a number of reasons:
'  1. There is less code overhead
'  2. There are fewer compatibility questions
'  3. It parallels the FNBIOSPrint routine in SETUPTSR.BAS and as
'     such has greater application then OUTs



DEF FNBIOSDial% (Character)
    FNBIOSDial% = 0                     'assume no errors
    Registers.AX = 256 + Character      'put the character into AL, 1 into AH
    Registers.DX = 0                    'specify Com1: (use 1 for Com2: etc.)
    Interrupt &H14, Registers           'call the BIOS write service
    PRINT HEX$(Registers.AX)
    IF Registers.AX AND &H8000 THEN     'check bit 7 of AH, error if set
       FNBIOSDial% = -1
    END IF
END DEF
   
'Modem initialization, only need once and it doesn't matter if the underlying
'applications change it.  In fact, if you have executed a command like:
'   MODE COM1:9600,N,8,1,P
'you don't need to initialize at all

Registers.AX = 67                       'put the character into AL, 0 into AH
Registers.DX = 0                        'specify Com1: (use 1 for Com2: etc.)
Interrupt &H14, Registers               'call BIOS

ID$ = "ResDial (c) 1990 User Friendly, Inc. - press Ctrl-D to activate"
Row = CSRLIN                            'print at the current cursor location
Column = POS(0)

PDQPrint ID$, Row, Column, Seven

ScrnSize = 480                          '3 lines * 80 cols for prompt & input
BufSeg = AllocMem%(ScrnSize)            'allocate memory to save the screen
DEF SEG = 0                             'see what type of monitor
IF PEEK(&H463) = &HB4 THEN ScrSeg = &HB000 ELSE ScrSeg = &HB800
Num2Dial$ = "                                 "

'----- set up the TSR as a pop-up using Ctrl-D
CALL PopUpHere(&H420, ID$)              'Ctrl-D, pass the unique ID string
GOTO EndIt                              'skip past the interrupt handler below
10                                      'this line number is needed for VB/DOS

'----- the following code is invoked each time Ctrl-D is pressed

BlockCopy ScrSeg, Zero, BufSeg, Zero, ScrnSize  'save the underlying screen
Row = CSRLIN                                    'and the cursor location too
Column = POS(0)

'----- draw a box and prompt for the phone number
PDQPrint "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿", One, One, Seven
PDQPrint "³ Enter a phone number to dial:                                   ³", Two, One, Seven
PDQPrint "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ", Three, One, Seven

LOCATE 2, 33                                 'position the cursor
BIOSInput Num2Dial$, 112                     'get number

'This is where we dial the number:
   
FOR X = 1 TO 4
    Char = ASC(MID$(DialStr$, X, One))       'first send the "ATDT"
    ComErr = FNBIOSDial%(Char)
    IF ComErr THEN GOTO NoCom
NEXT
        
FOR X = 1 TO 33                              'now the number, spaces ignored
    ComErr = FNBIOSDial%(ASC(MID$(Num2Dial$, X, One)))
    IF ComErr THEN GOTO NoCom
NEXT
        
ComErr = FNBIOSDial%(13)                     'all AT commands terminate with
IF ComErr THEN GOTO NoCom                    'a CR


PDQPrint "Dialing, hit a key to hang up:", Two, Three, Seven

WHILE BIOSInkey% = 0: WEND                   'Now pick up the phone...
FOR X = 1 TO 3                               'and hang up the modem
    ComErr = FNBIOSDial%(ASC(MID$(HangStr$, X, One)))
    IF ComErr THEN GOTO NoCom
NEXT

NoCom:
BlockCopy BufSeg, Zero, ScrSeg, Zero, ScrnSize  'restore the screen contents
LOCATE Row, Column                              'and the cursor location


CALL PopDown                                    'back to underlying app.

EndIt:
CALL EndTSR(ID$)                        'this installs us as a TSR

