'-------- LPT2FILE.BAS - captures printer output and sends it to a file

'Copyright (c) 1990 Ethan Winer
'Inspired by our buddy, Harald Zoschke

'The STR02048.OBJ alternate string pool in the link instructions below allows
'approximately 1000 characters to be "spooled" in one operation.  When most
'programs send data to the printer, they do so in lines of 132 characters or
'less (not including two more for the terminating carriage return and line
'feed).  However, there are some situations where more characters are sent in
'a continuous stream.  For example, if you copy a file to the printer with
'
'   COPY filename LPT1:
'
'DOS reads up to 64K of the file at a time, and sends it all at once.  The
'problem within the context of a P.D.Q. "simplified" TSR such as this one is
'that DOS is busy that entire time.  Thus, PopRequest cannot successfully
'invoke the simplified handler.  In most cases, you can use a string pool of
'only 256 bytes (STR00256.OBJ), since LPT2FILE flushes the printed output to
'disk when 100 characters have been received.  I showed 2048 just to be safe,
'though using a smaller pool size of course reduces the TSR's memory usage.
'
'One suggested addition to this program would be to obtain the LPT number
'from the command line, and use that instead of assuming LPT1.  Bear in mind
'that LPT1 is indicated with a 0 in the DX register, LPT2 with a 1, and LPT3
'with a 2.  Another might be to print better messages.  Of course, by keeping
'the chatter to a minimum, the file size and memory requirements are also
'minimized.  You could also accept a command-line argument that specifies the
'output disk file name.
'
'Note the way StuffBuf is called with an Enter key stroke, to tell DOS to
're-display the prompt when LPT2FILE is deinstalled.  Since the "Uninstalled"
'message is printed behind DOS' back, it does not know that it should display
'its prompt again.  REM out the call to StuffBuf to see what I mean.
'
'To create the smallest possible program and use the least amount of memory,
'compile and link as follows:
'
'  bc lpt2file /o;
'  link /nod/noe/ex lpt2file flush _noread _noerror _noval str02048,,nul,smalldos pdq
'  exe2com lpt2file


DEFINT A-Z                      'always use integers

'$INCLUDE: 'PDQDECL.BAS'        'this holds Declares and defines RegType

DIM Registers AS RegType        'create the TYPE variable
Eighteen = 18                   'this speeds things up later

ID$ = "LPT2File Version 1.2"    'all TSRs need an ID string
PRINT ID$                       'print it
PRINT "Press Ctrl-Alt-U to flush the buffer and uninstall"

DGROUP = TSRInstalled%(ID$)     'see if we're already installed
IF DGROUP THEN
   PRINT "Already installed!"
   END
END IF

OPEN "LPT2FILE.DAT" FOR OUTPUT AS #1    'for the copy of data sent to LPT1:


'---- Trap printer Interrupt 17H, and receive control for each character sent
Registers.IntNum = &H17         'specify trapping Int 17h
CALL PointIntHere(Registers)    'trap the interrupt
GOTO PopUp                      'skip past the Int 17h handler to PopUpHere
10                              'this line number is needed for VB/DOS

CALL IntEntry1                  'we arrive here each time something prints
CALL IntEntry2(Registers, Zero) 'these are the two mandatory calls
  
Service = Registers.AX \ 256    'get the current service number in AH
Char = Registers.AX AND 255     'and get the character from AL
LptNo = Registers.DX            'and the printer number (0 = LPT1:)

CALL CallOldInt(Registers)      'first send the character to the printer

IF Service = 0 AND LptNo = 0 THEN   'our LPT number and "Print char." service?
   Buffer$ = Buffer$ + CHR$(Char)   'yes, build the string
   IF LEN(Buffer$) >= 100 THEN      '>= in case PopRequest failed earlier
      Dummy = PopRequest%(Flag, Eighteen)   'try for one second to pop up
   END IF
END IF

CALL ReturnFromInt(Registers)   'return to the underlying application


'---- Install the pop-up handler that services the hot key and disk requests
PopUp:
CALL PopUpHere(&HC16, ID$)      'Ctrl-Alt-U
GOTO EndIt                      'continue on to end as a TSR
20                              'this line number is needed for VB/DOS

IF NOT Registers.BusyFlag THEN
   PRINT #1, Buffer$;           'print what's in the buffer
   Buffer$ = ""                 'free up the buffer for later
   Flush                        'flush the file forcing the data to disk
END IF

IF NOT Flag THEN                'we're here via the hotkey, not PopRequest
   CLOSE #1                     'close the file
   Success1 = PopDeinstall%(DGROUP, ID$)      'try to deinstall as a TSR
   Success2 = UnHookInt%(Registers, DGROUP)   'try to unhook Interrupt 16h
   IF Success1 AND Success2 THEN
      PRINT "Lpt2File removed"                'we made it, say so
      CALL StuffBuf(CHR$(13))                 'force DOS to issue new prompt
   ELSE
      PRINT "Unable to remove, reboot now!"   'it failed, warn them
   END IF
END IF

Flag = 0                        'clear the flag as explained in README.TSR
CALL PopDown                    'no matter what, pop down


EndIt:
CALL EndTSR(ID$)                'terminate and stay resident

