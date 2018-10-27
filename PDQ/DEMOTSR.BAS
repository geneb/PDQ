'********** DEMOTSR.BAS

' A complete demonstration of the mechanics of writing a TSR program
' using the PDQ library manual resources.
' by Robert L. Hummel


DEFINT A-Z                      'All variables are integer
'$INCLUDE: 'PDQDECL.BAS'        'Definitions

DIM Registers AS RegType        'RegType is defined in PDQDECL.BAS
'----------------------------------------------------------------------
' For every interrupt that is hooked, an 18-word storage space must be
' reserved. The elements used are 0-17.
'----------------------------------------------------------------------
Registers.IntNum = &H9
Action = 0

'----------------------------------------------------------------------
' Every TSR must have a unique ID string. The best format is the program
' name, version number, and copyright notice. This is used to search
' for previous copies and uninstall.
'----------------------------------------------------------------------
ID$ = "TsrDemo 1.0 (c) 1989 Robert L. Hummel"
Message$ = "This message from TsrDemo resident version."
ANS$ = " "

PRINT ID$                       'Say who we are

'----------------------------------------------------------------------
' Normally, you don't load more than one copy of a TSR. So check for
' a resident copy.
'----------------------------------------------------------------------
ResidentDGROUP = TSRInstalled%(ID$)
PRINT "TsrInstalled returned: "; HEX$(ResidentDGROUP)

'----------------------------------------------------------------------
' If the value is non-zero, another copy of the program has been found.
'----------------------------------------------------------------------
IF (ResidentDGROUP) THEN
   PRINT "Program already resident at DGROUP = "; HEX$(ResidentDGROUP)
   PRINT "Uninstall the program at that location (Y/N)? ";
   BIOSInput ANS$, 7
   PRINT
   IF ANS$ <> "Y" AND ANS$ <> "y" THEN STOP

'----------------------------------------------------------------------
' Unhook any interrupts the program has grabbed.
'----------------------------------------------------------------------
   IF UnHookInt%(Registers, ResidentDGROUP) THEN
      PRINT "Interrupt unhooked successfully."
   ELSE
      PRINT "Can't Unhook the interrupt."
      PRINT "Remove other TSRs, then try again."
      STOP
   END IF

'----------------------------------------------------------------------
' Remove the program from memory.
'----------------------------------------------------------------------
   IF DeInstallTSR%(ResidentDGROUP, ID$) THEN
      PRINT "Deinstallation successful."
   ELSE
      PRINT "Deinstallation failed. System Unstable. Reboot."
   END IF
   STOP

'----------------------------------------------------------------------
' If 0 is returned, the current copy is the only copy. Since the code
' currently executing is NOT part of the resident program, that means
' no resident version exists.
'----------------------------------------------------------------------
ELSE
   PRINT "This copy of the program was the first one found."
   PRINT "Install the program (Y/N)? ";
   BIOSInput ANS$, 7
   PRINT
   PRINT "Answer = "; ANS$
   IF ANS$ <> "Y" AND ANS$ <> "y" THEN STOP
   PRINT "Press Alt-H to activate"
END IF

'----------------------------------------------------------------------
' Install the program.
' Set the correct element equal to the interrupt number. Then call
' PointIntHere to install the code following the GOTO as an interrupt
' handler. The GOTO MUST follow the call.
' Note that the interrupt handler must be prepared to function IMMEDIATELY
' after this call, not just after the EndTSR call.
'----------------------------------------------------------------------
PRINT "Installing the program."

CALL PointIntHere(Registers)
GOTO EndIt
10                                  'this line number is needed for VB/DOS

'----------------------------------------------------------------------
' RESIDENT PORTION OF PROGRAM.
'----------------------------------------------------------------------
' This portion of the program gets control during an interrupt. The two
' calls to IntEntry1 and IntEntry2 must be the first calls executed in
' any interrupt handler.
' Note that no DOS I/O calls to the screen or keyboard can be used when
' resident. If I/O to a device (disk, printer, etc.) is contemplated,
' you must implement a full context switch.
'----------------------------------------------------------------------
CALL IntEntry1
CALL IntEntry2(Registers, Action)
'----------------------------------------------------------------------
' Do anything here within reason. I've chosen to implement a simple
' hotkey routine. This isn't safe because it doesn't check any other
' interrupts.
'----------------------------------------------------------------------
IF (TestHotKey(&H823)) THEN             '0823 = alt-h
   ResetKeyboard                        'forget the key
ELSE
   GotoOldInt Registers                 'not our key
END IF
'----------------------------------------------------------------------
' We can find out if we're the first resident copy or not.
'----------------------------------------------------------------------
CLS
PDQPrint Message$, 1, 1, &H70

ResidentDGROUP = TSRInstalled%(ID$)
PDQPrint RIGHT$("000" + HEX$(ResidentDGROUP), 4), 1, 60, &H70

IF ResidentDGROUP THEN
   PDQPrint "Res:Earlier resident version at DGROUP = ", 2, 1, &H70
ELSE
   PDQPrint "Res:I'm the only version in memory.", 2, 1, &H70
   PDQPrint "Res:Should I uninstall myself? ", 3, 1, &H70
   LOCATE 3, 32
   BIOSInput ANS$, 112
   IF ANS$ <> "Y" AND ANS$ <> "y" THEN GOTO ResEnd

   IF UnHookInt%(Registers, ResidentDGROUP) THEN
      PDQPrint "Res:Interrupt unhooked successfully.", 4, 1, &H70
   ELSE
      PDQPrint "Res:Can't Unhook the interrupt.", 4, 1, &H70
      PDQPrint "Res:Remove other TSRs, then try again.", 5, 1, &H70
      GOTO ResEnd
   END IF

   IF NOT DeInstallTSR%(ResidentDGROUP, ID$) THEN
      PDQPrint "Res:Deinstallation failed. System Unstable. Reboot.", 5, 1, &H70
   ELSE
      PDQPrint "Res:Deinstallation successful.", 5, 1, &H70
   END IF
END IF

ResEnd:
ReturnFromInt Registers         'return to the underlying app.

'----------------------------------------------------------------------
' MAKE THE PROGRAM RESIDENT.
'----------------------------------------------------------------------
EndIt:

PRINT "Old vector = "; HEX$(Registers.Segment); ":"; HEX$(Registers.Address)
PRINT "Program has been installed."

EndTSR ID$                      'exit while staying resident

