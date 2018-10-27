'********** MACRO.BAS - TSR keyboard macro program

'Copyright (c) 1991 Ethan Winer and Robert L. Hummel

'NOTES:
'
'  1. Note that the BIOS recognizes extended keys as having the scan code in
'     the high byte, and zero in the low byte.  This is the same method used
'     by INKEY$ when returning keys, which is different from the way P.D.Q.
'     hot keys are defined with PopUpHere.  That's why the Alt keys assigned
'     to the HotKey() array have a zero in the lower byte and the scan code
'     in the upper byte, rather than an 8 in the upper byte and the scan code
'     in the lower byte as shown in the hot key table in the P.D.Q. manual.
'
'  1a. (added 3-13-94)  You can also use regular keys (as opposed to extended
'     keys like Alt-1 in the code below) as an activator to playback a macro.
'     A regular key is defined by placing its hardware scan code (as shown in
'     the P.D.Q. manual table) in the high byte, and its ASCII value in the
'     low byte.  For example, to define "A" as the trigger for Macro #4 below
'     you would use this:
'
'       HotKey(4) = &H1E41  '&H1E is scan code for "A", &H41 = 65 = ASC("A")
'
'     A control key is also defined using both its scan code and ASCII value,
'     with the ASCII bytes ranging from 1 through 26 (Ctrl-A through Ctrl-Z)
'     and also 27 through 31 (Esc, Ctrl-\, Ctrl-], Ctrl-^, and Ctrl-[hyhen]).
'     Note that letter keys are case sensitive, so the "A" example above will
'     respond to "A" but not "a".
'
'  2. To specify an extended key within a macro output string simply use a
'     CHR$(0) plus the extended key's scan code.  For example, to have MACRO
'     simulate pressing the F1 key you would use CHR$(0) + ";".  (The ASCII
'     value of ";" is 59.)  Understand that Ctrl keys are not extended keys.
'     That is, Ctrl-A is simply CHR$(1), Ctrl-B is CHR$(2), and so forth.
'
'  3. To avoid having to maintain a 255-byte lookup table, this program does
'     not place a normal key's scan code into AH like the BIOS does.  In most
'     cases this will not present any problems and programs that actually
'     check for that (very few) will think that the keys were entered by
'     pressing Alt and typing the ASCII values on the numeric pad.  However,
'     some programs such as Word Perfect do distinguish between, for example,
'     the plus key on the keypad and the white plus on the top row of keys.
'
'For the smallest possible program, compile and link as follows:
'
'  bc macro /o;
'  link /nod/noe/ex/packc/far macro str00512 _noval _noerror _noread,,nul,pdq
'  exe2com macro
'
'Note that if you have many macro strings you may need to increase the size
'of the string pool by using a larger STR?????.OBJ stub file.


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'
 
ID$ = "MACRO 1.00"
DIM Reg16 AS RegType

CONST NumMacros = 4
DIM Macro$(1 TO NumMacros)
DIM HotKey(1 TO NumMacros)

Macro$(1) = "This is message 1"
Macro$(2) = "This is message 2"
Macro$(3) = "This is message 3"
Macro$(4) = "This is message 4" + CHR$(0) + "G" 'message plus Home key

HotKey(1) = &H7800                      'Alt-1 is the hot key for message 1
HotKey(2) = &H7900                      'Alt-2 types message 2
HotKey(3) = &H7A00                      'Alt-3
HotKey(4) = &H7B00                      'Alt-4

 
'--- Standard installation/deinstallation code
'
DGroup = TSRInstalled%(ID$)
IF INSTR(UCASE$(COMMAND$), "/U") THEN
  IF DGroup THEN
    Okay = UnHookInt(Reg16, DGroup)
    Okay = DeinstallTSR%(DGroup, ID$)
  ELSE
    PRINT "MACRO is not resident.  Try again without /U."
  END IF
  END
ELSE
  IF DGroup THEN
    PRINT "MACRO is already installed."
    END
  END IF
END IF
 
PRINT ID$                       'print the ID as a sign-on message
Ptr = 1                         'tracks where we are in a macro in progress


'--- Take over keyboard Interrupt &H16
'
Reg16.IntNum = &H16             'specify trapping Int 16h
CALL PointIntHere(Reg16)        'trap the interrupt
GOTO EndIt                      'skip past the Int 16h handler code
10                              'this line number is needed for VB/DOS
 
CALL IntEntry1                  'we arrive here when an app calls for a key
CALL IntEntry2(Reg16, Zero)     'these are the two mandatory calls


'--- If the underlying program requests service 2 (get shift key state)
'    pass on to the BIOS to handle it.
'
IF (Reg16.AX AND &HEF00) = &H200 THEN CALL GotoOldInt(Reg16)


'--- Calls to get the keyboard status also return the character.  In this
'    case, we'll return the macro expansion character if one is in progress.
'
IF (Reg16.AX AND &HEF00) = &H100 THEN       'if service 1 or service &H10
  IF Macro = 0 THEN CALL GotoOldInt(Reg16)  'if not now sending a macro
                                            '  let the BIOS do it all
  FOR X = 1 TO NumMacros                    'cycle through each hot key
    IF HotKey(X) = Macro THEN               'if this is the macro in progress
      Reg16.AX = MidChar%(Macro$(X), Ptr)   'grab the current character
      IF Reg16.AX = 0 THEN                  'it's an extended key
        Reg16.AX = MidChar%(Macro$(X), Ptr + 1) * 256   'scan code is 1 past
      END IF
      EXIT FOR                              'no need to continue searching
    END IF
  NEXT
 
  Reg16.Flags = Reg16.Flags AND NOT &H40    'clear the zero flag to show
  CALL ReturnFromInt(Reg16)                 '  that a key is pending
END IF


'--- Calls to wait for a key (service 0 or 10h) first empty the keyboard,
'    then empty the macro, then loop.  They are never sent into BIOS control.
'
XService = Reg16.AX AND &H1000              'remember if it's an extended svc

IF (Reg16.AX AND &HEF00) = 0 THEN           'service 0 or 10h
  IF Macro = 0 THEN                         'if a macro is not in progress
    DO                                      'sit in a loop
      Reg16.AX = &H100 OR XService          'if app used an extended service
      CALL CallOldInt(Reg16)                '  (101 key kbd.) so should we
    LOOP UNTIL (Reg16.Flags AND &H40) = 0   'while ZF = True (no key ready)

    Reg16.AX = XService                     'fetch the key that is now ready
    CALL CallOldInt(Reg16)                  'by calling the BIOS

    FOR X = 1 TO NumMacros                  'see if they pressed a hot key
      IF Reg16.AX = HotKey(X) THEN          'if this is one of our keys
        Macro = Reg16.AX                    'remember that in variable Macro
        EXIT FOR                            'and bail out early
      END IF
    NEXT
  END IF

  FOR X = 1 TO NumMacros                    'see if a macro is in progress
    IF HotKey(X) = Macro THEN               'if this macro is happening
      Reg16.AX = MidChar%(Macro$(X), Ptr)   'return current character via AX
      Ptr = Ptr + 1                         'bump the pointer for later
      IF Reg16.AX = 0 THEN                  'it's an extended key
        Reg16.AX = MidChar%(Macro$(X), Ptr) * 256 'return the scan code in AH
        Ptr = Ptr + 1                       'bump one extra for extended key
      END IF
      IF Ptr > LEN(Macro$(X)) THEN          'if that was the last character
        Macro = 0                           'reset the flag to show that
        Ptr = 1                             'and reset Ptr for later
      END IF
    END IF
  NEXT

  CALL ReturnFromInt(Reg16)             'we handled it all ourselves, return
END IF

EndIt:
CALL EndTSR(ID$)                        'end and stay resident
