'********** POPUPFP.BAS - shows where and how to unhook floating point ints

'Copyright (c) 1991 Ethan Winer


'Compile and link as follows:
'
'  bc popupfp /o;
'  link /nod/noe/far/packc popupfp str00256 , , nul, pdq

DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

ID$ = "POPUPFP.BAS Version 1.0 - press Alt-P to pop up"
DGroup = TSRInstalled%(ID$)             'see if we're already installed

IF INSTR(UCASE$(COMMAND$), "/U") THEN   'do they want to uninstall?
   IF DGroup THEN                       'are we already installed?
      Okay = PopDeinstall%(DGroup, ID$) 'yes, try to remove the earlier copy
      IF NOT Okay THEN                  'deinstallation failed, so tell them
         PRINT "Unable to un-install POPUPFP.  Reboot now!"
      ELSE
         PRINT "POPUPFP removed."
      END IF
   ELSE
      PRINT "POPUPFP is not resident.  Try again without /U."
   END IF
   END                                  'either way, end the program
ELSE
   IF DGroup THEN                       'already resident, they didn't use /U
      PRINT "POPUPFP is already installed.  Press Alt-P to activate it."
      END
   END IF
END IF

PRINT ID$

CALL PopUpHere(&H819, ID$)      'pop up on Alt-P
GOTO EndIt
10                              'this line number is needed for VB/DOS

CALL EnableFP                   'first enable the floating point interrupts
X! = 1.2                        'floating point assignments are now ok
Y! = X! * 3.4                   'and so are calculations like this one

PRINT "You pressed Alt-P to pop me up.  Y! ="; Y!       'say hello
CALL StuffBuf(CHR$(13))         'this trick forces DOS to reissue its prompt

CALL DisableFP                  'always disable FP math before popping down!
CALL PopDown                    'pop down


EndIt:
CALL UnHookFP                   'unhook floating point interrupts
CALL EndTSR(ID$)                'then end as a TSR

