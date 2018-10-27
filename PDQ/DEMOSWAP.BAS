'********** DEMOSWAP.BAS - Swapping version of SCRNCAP.BAS

'Copyright (c) 1989-1991 Ethan Winer

'This program must be compiled to disk before running.


'To take as little DOS memory as possible when this program is installed as
'a TSR link it with POPSWAP.OBJ and the other stub files like this:
'
'  BC demoswap /o;
'  LINK /nod/noe/ex popswap +
'    demoswap str00512 _noread _noval _locate _noerror, demoswap, nul, pdq;


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'                'PDQDECL contains P.D.Q. declarations

DIM Registers AS RegType                'RegType is defined in PDQDECL.BAS
One = 1                                 'these variables save code size below
Seven = 7

ID$ = "DEMOSWAP 1.0, press Alt-B to pop up"

DGroup = TSRInstalled%(ID$)             'see if we're already installed
IF INSTR(UCASE$(COMMAND$), "/U") THEN   'do they want to uninstall?
  IF DGroup THEN                        'yes, but are we already installed?
    DEF SEG = 0                         'yes, check if Int. &HAA is valid
    IF PDQPeek2%(&HAA * 4 + 2) THEN     'the segment is non-zero, onward ho
      Registers.AX = &H830              'specify this program's ID code in AX
      Registers.BX = 1                  'this tells the kernel to deinstall
      Registers.CX = 18 * 5             'try for 5 seconds to get control
      CALL Interrupt(&HAA, Registers)   'call the resident kernel
      PRINT "DEMOSWAP removed"          'and assume it was successful
    ELSE                                'swapping failed at installation
      IF PopDeinstall%(DGroup, ID$) THEN    'so deinstall the usual way
        PRINT "DEMOSWAP removed"            'report success if it worked
      ELSE                                  'or failure if it didn't
        PRINT "Deinstallation failed, reboot now!"
      END IF
    END IF
  ELSE
    PRINT "DEMOSWAP is not resident"
  END IF
  END                                   'either way, end the program
ELSE
  IF DGroup THEN                        'already resident, they didn't use /U
    PRINT "DEMOSWAP is already installed, press ALT-B to activate"
    END
  END IF
END IF

ScrnSize = 480                          '3 lines * 80 cols for prompt & input
BufSeg = AllocMem%(ScrnSize)            'allocate memory to save the screen
                                        '  BEFORE calling Swap2Disk/Swap2EMS

'----- set up the TSR as a pop-up using Alt-B (B = Both EMS and Disk)
HotKey = &H830

IF Swap2EMS%(HotKey) THEN                       'try first to swap to EMS
  PRINT "EMS swapping installed"                'it worked, say so
ELSE
  PRINT "EMS not available, error"; ERR         'EMS not available, say why
  IF Swap2Disk%("C:\DEMOSWAP.SWP", HotKey) THEN 'so try to swap to disk next
    PRINT "DISK swapping installed"             'that worked, report success
  ELSE                                          'disk swap failed, say why
    PRINT "Disk swapping failed, error"; ERR; "- installing as a normal TSR"
  END IF
END IF

PRINT ID$                                           'say hello
FileName$ = "                                  "    'create a string to edit

CALL PopUpHere(HotKey, ID$)     'Alt-B, pass the unique ID string
GOTO EndIt                      'skip past the interrupt handler below
10                              'this line number is needed for VB/DOS

'----- The following code is invoked each time the hot key is pressed or
'      when Interrupt &HAA is called.
IF SwapCode% = 1 THEN           'we arrived here via CALL INTERRUPT &HAA
  Okay = PopDeinstall%(0, ID$)  '0=deinstall ourselves from within this copy
  CALL PopDown                  'then pop down to complete the process
END IF

DEF SEG = 0                                     'see what type of monitor
CONST ScrCols = 80                              'default to 80 columns
ScrRows = 25                                    'assume monochrome, 25 lines
ScrSeg = &HB000                                 'at video segment &HB000
IF PEEK(&H463) <> &HB4 THEN                     'not mono so it must be color
   ScrSeg = &HB800                              'assign the color segment
   Registers.AX = &H1200                        'ask for the EGA info service
   Registers.BX = &H10                          '  to check for > 25 rows
   Interrupt &H10, Registers
   IF (Registers.BX AND &HFF) <> &H10 THEN      'if BL <> 10h then it's E/VGA
      ScrRows = PEEK(&H484) + 1                 'get rows, adjust to 1-based
   END IF
END IF

BlockCopy ScrSeg, Zero, BufSeg, Zero, ScrnSize  'save the underlying screen
SaveCsr& = CursorSave&                          'and the cursor location too


'----- draw a box and prompt for the file name
PDQPrint "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿", One, One, Seven
PDQPrint "³ Enter a name for the screen:                                    ³", 2, One, Seven
PDQPrint "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ", 3, One, Seven

'LSET FileName$ = ""                            'unREM to clear the field
LOCATE 2, 32                                    'position the cursor
BIOSInput FileName$, 112                        'let them input name

IF INSTR(FileName$, ".") = 0 THEN               'this block is optional
   LSET FileName$ = RTRIM$(FileName$) + ".SCR"  'remove it to not add the
END IF                                          '  default .SCR extension

BlockCopy BufSeg, Zero, ScrSeg, Zero, ScrnSize  'restore the screen contents
CursorRest SaveCsr&                             'and the cursor location/size

DEF SEG = ScrSeg                                'use the appropriate segment
BSAVE RTRIM$(FileName$), 0, ScrRows * ScrCols * 2    'save the screen to disk

CALL PopDown                                    'return to the underlying app.

EndIt:
CALL EndTSR(ID$)                                'this installs us as a TSR

