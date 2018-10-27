'********** TEMPLATE.BAS - TSR "fill-in-the-blanks" program skeleton

'Copyright (c) 1990 Ethan Winer


'----- All P.D.Q. programs should start with DEFINT A-Z, to ensure that every
'      variable is by default an integer.  You can override that when needed
'      for long integers by using an ampersand (&) type identifier.
'
DEFINT A-Z


'----- The PDQDECL.BAS file contains DECLARE statements for all of the P.D.Q.
'      extensions and subroutines.  By including it in your program, you are
'      assured that BASIC will report an error if you attempt to call one of
'      them incorrectly.  PDQDECL also includes the RegType TYPE definition
'      needed by CALL INTERRUPT and the P.D.Q. interrupt handling routines.
'
'$INCLUDE: 'PDQDECL.BAS'


'----- Every P.D.Q. TSR program needs a unique ID string.
'
ID$ = "This is the P.D.Q. TSR template example, press Alt-T to activate."


'----- The following block of code detects a prior installation.  If the user
'      is asking to uninstall the program using a /U command line switch
'      (U stands for Uninstall), the code checks to see if the program is
'      already resident.  If so, it attempts to uninstall itself.  Otherwise,
'      it tells the user that the program is not resident.  If /U was used
'      and a copy is not now resident, the program prints an appropriate
'      message.  If you prefer to save the code size and memory necessary to
'      detect installation (1K or so), remove or REM out the following code.
'
DGroup = TSRInstalled%(ID$)             'see if we're already installed
IF INSTR(UCASE$(COMMAND$), "/U") THEN   'do they want to uninstall?
   IF DGroup THEN                       'are we already installed?
      Okay = PopDeinstall%(DGroup, ID$) 'yes, try to remove the earlier copy
      IF NOT Okay THEN                  'deinstallation failed, so tell them
         PRINT "Unable to un-install TEMPLATE.  Reboot now!"
      ELSE
         PRINT "Template removed."      'otherwise report success
      END IF
   ELSE
      PRINT "TEMPLATE is not resident.  Try again without /U."
   END IF
   END                                  'either way, end the program
ELSE
   IF DGroup THEN                       'already resident, they didn't use /U
      PRINT "TEMPLATE is already installed.  Press Alt-T to activate it."
      END
   END IF
END IF


'----- Any TSR that will be using PDQPrint must call PDQPrint at least once
'      as part of its initialization.  Here, the ID$ is used as a sign-on
'      message, which satisfies this requirement.  Note how CSRLIN and POS(0)
'      are used to print the message at the current cursor location.  (When
'      writing a simplified TSR such as this one it is not necessary to call
'      PDQPrint once before becoming resident.  This is really needed only
'      with manual interrupt handlers.)
'
CALL PDQPrint(ID$, CSRLIN, POS(0), 7)


'----- PopUpHere is the routine that actually sets up the hot-key intercept,
'      and also performs the housekeeping needed to implement a pop-up TSR.
'      PopUpHere expects a parameter that specifies the hot key, as well as
'      the ID string you are using.  Note that you must never change the
'      ID string in a P.D.Q. TSR, although printing it is okay.  Also note
'      that PopUpHere must be followed by a GOTO, to transfer execution to
'      the code that ends the program and keeps it resident in memory.
'
CALL PopUpHere(&H814, ID$)
GOTO EndIt
10    'This line number is needed for VB/DOS.


'----- The following code is invoked each time Alt-T is pressed.  You will
'      therefore place your own program statements here.  You may test-run
'      a P.D.Q. simplified TSR such as this one in the QB and QBX editing
'      environments by disabling the GOTO above.  When this is done, the
'      program will run through the following block of code once.  However,
'      you must also load PDQSUBS.BAS as a module.  PDQSUBS.BAS contains
'      dummy BASIC subprograms and functions for PopUpHere, TSRInstalled, and
'      so forth.  In this example, the only action that is performed is to
'      call PDQPrint to display a test message.  The call to PopDown must be
'      the last thing your program does as part of the pop-up handler, and it
'      returns control to the underlying application.
'
CALL PDQPrint("This is displayed when you press Alt-T", 2, 1, 112)
'
'      Add more statements here that will be executed each time the hot-key
'      is pressed.
'
CALL PopDown


'----- A P.D.Q. program never uses BASIC's END command.  Instead, the EndTSR
'      routine is called to terminate the program, and leave it resident in
'      memory.  This should be the very last statement in the main program.
'      The only exception to this is when a prior installation is detected,
'      as shown in the code near the start of this program.  In that case,
'      a second, non-resident copy of the program is being run.  Therefore,
'      END is used to halt the program and prevent a reinstallation.
'
EndIt:
CALL EndTSR(ID$)

