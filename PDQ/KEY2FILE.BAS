'-------- KEY2FILE.BAS - captures keystrokes and sends them to a file

'Copyright (c) 1991 Ethan Winer


'Notice that Key2File does not append a CHR$(10) line feed after each
'carriage return that is typed.  Therefore, if you use the DOS TYPE command
'to examine the file that is created the results will not appear correctly.
'
'To create the smallest possible program and use the least amount of memory,
'compile and link as follows:
'
'  bc key2file /o;
'  link /nod/noe/ex key2file _flush _noread _noerror _noval str02048,,nul,smalldos pdq
'  exe2com key2file


DEFINT A-Z                      'always use integers

'$INCLUDE: 'PDQDECL.BAS'        'this holds Declares and defines RegType

DIM Registers AS RegType        'create the TYPE variable
Eighteen = 18                   'this speeds things up later
Zero$ = CHR$(0)                 'this too, by avoiding a call to CHR$()

ID$ = "Key2File Version 1.1"    'all TSR programs need an ID string
PRINT ID$                       'print it
PRINT "Press Ctrl-Alt-U to flush the buffer and uninstall"

DGROUP = TSRInstalled%(ID$)     'see if we're already installed
IF DGROUP THEN
   PRINT "Already installed!"
   END
END IF

OPEN "KEY2FILE.DAT" FOR OUTPUT AS #1    'receives a copy of keys typed


'---- Trap keyboard Interrupt 16H, and get control at each character request
Registers.IntNum = &H16         'specify trapping Int 16h
CALL PointIntHere(Registers)    'trap the interrupt
GOTO PopUp                      'skip past the Int 16h handler to PopUpHere
10                              'this line number is needed for VB/DOS

CALL IntEntry1                  'we arrive here when an app calls for a key
CALL IntEntry2(Registers, Zero) 'these are the two mandatory calls
  
Service = Registers.AX          'first save the service number now in AH
CALL CallOldInt(Registers)      'then call the original Int 16h handler

'---- (Service AND &HEF00) below tests if the service was either 0 or &H10
IF (Service AND &HEF00) = 0 THEN    'the underlying program just got a key
   IF Registers.AX AND &HFF THEN    'it's not an extended character
      Buffer$ = Buffer$ + CHR$(Registers.AX AND &HFF)
   ELSE                             'it is an extended key, handle that
      Buffer$ = Buffer$ + Zero$ + CHR$(Registers.AX \ 256)
   END IF

   IF LEN(Buffer$) >= 100 THEN       '>= in case PopRequest failed earlier
      Dummy = PopRequest%(Flag, Eighteen)   'try for one second to pop up
   END IF
END IF

CALL ReturnFromInt(Registers)   'return to the underlying application


'---- Install the pop-up handler that services the hot key and disk requests
PopUp:
CALL PopUpHere(&HC16, ID$)      'Ctrl-Alt-U
GOTO EndIt                      'continue on and end as a TSR
20                              'this line number is needed for VB/DOS

IF NOT Registers.BusyFlag THEN  'if the interrupt isn't now busy
   PRINT #1, Buffer$;           'print what's in the buffer
   Buffer$ = ""                 'free up the buffer for later
   Flush                        'flush the file forcing the data to disk
END IF

IF NOT Flag THEN                'we're here via the hotkey, not PopRequest
   CLOSE #1                     'close the file
   Success1 = PopDeinstall%(DGROUP, ID$)      'try to deinstall as a TSR
   Success2 = UnHookInt%(Registers, DGROUP)   'try to unhook Interrupt 16h
   IF Success1 AND Success2 THEN
      PRINT "Key2File removed"                'we made it, say so
      CALL StuffBuf(CHR$(13))                 'force DOS to issue new prompt
   ELSE
      PRINT "Unable to remove, reboot now!"   'it failed, warn them
   END IF
END IF

Flag = 0                        'clear the flag as explained in the manual
CALL PopDown                    'no matter what, pop down


EndIt:
CALL EndTSR(ID$)                'terminate and stay resident

