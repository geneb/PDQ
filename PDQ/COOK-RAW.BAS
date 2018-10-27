'********** COOK-RAW.BAS - shows how to set a devices cooked/raw status

'Copyright (c) 1992 Ethan Winer


'When you read from or write to a file DOS transfers the data exactly as it
'is encountered, even if you send special characters such as CHR$(9) Tabs or
'CHR$(26) end-of-file bytes.  Therefore, recognizing CHR$(26) bytes is up to
'BASIC or whatever high-level language is being used -- DOS treats all bytes
'in all files equally.  However, when a program reads from the keyboard or
'prints using LPRINT via DOS (as P.D.Q. does), DOS normally intervenes and
'examines each byte for special control codes.  This is because DOS handles
'devices differently than it handles files.  For example, if you copy a .COM
'file to another directory, DOS copies the entire file -- even if the file
'has CHR$(26) EOF bytes in it.  In contrast, copying the same file to the CON
'device stops at the EOF byte, and only the characters before the first EOF
'byte appear on the screen.
'
'The DOS service that reads the keyboard will end the program when Ctrl-C is
'pressed.  Likewise, when you send a Tab character to the printer, DOS looks
'for that character and if found expands it to an equivalent number of blank
'spaces.  The DOS service that P.D.Q. uses for INPUT$ has to work both with
'files and the keyboard device.  But to be compatible with regular BASIC, it
'is very important that pressing Ctrl-C in response to INPUT$ doesn't end the
'program!  Likewise, you might want to use LPRINT or OPEN "LPT1" FOR OUTPUT
'to send binary data to a printer to download a font file or perhaps print a
'graphic image.
'
'The key to controlling whether DOS interprets each character being passed to
'or from a device is to select what is called the "Raw" or "Cooked" status of
'the device.  When the Raw mode is active DOS does not examine or interpret
'special codes.  In Cooked mode DOS does intervene when it detects certain
'byte values, depending on the device.  By default, devices are handled using
'Cooked mode; files are always handled in Raw mode and you can't change that.
'
'This program shows how to set the Raw/Cooked status for any device.  There
'are two subprograms used -- SetCooked and SetRaw -- and they both expect a
'DOS handle as a parameter.  The handle for the standard printer (as used by
'LPRINT) is always 4, and that's what this example uses.  If you plan to open
'the printer or other device manually you should use FILEATTR to obtain the
'equivalent DOS handle like this:
'
'  Device$ = "LPT1"
'  FileNumber = FREEFILE
'  OPEN Device$ FOR OUTPUT AS #FileNumber
'  Handle = FILEATTR(FileNumber, 0)
'
'We devised this program for a customer that needed to set the Raw mode when
'printing to a network printer.  In that case, it is necessary to open the
'printer explicitly, and then set the Raw mode based on that device's handle
'as shown above.  Setting the standard printer handle (4) to Raw mode was not
'sufficient because a network print spooler holds the data until the program
'ends.  By being able to set the Raw mode for an opened device, a subsequent
'CLOSE then tells the network that the print data has been completely sent.
'
'These subprograms use DOS service &H440x to retrieve the device's current
'status, which includes information other than just the Raw/Cooked status.
'The device handle is passed in the BX register, and the status is returned
'bit-coded in DL.  DOS requires that you clear the DH portion of DX when
'setting Raw or Cooked mode, and this is handled using AND.  The byte that
'specifies Raw mode is then either set with OR (in SetRaw) or cleared using
'AND (in SetCooked).
'
'This example does not send binary data as part of the test, because there's
'no way for us to know what types of binary data your particular printer can
'accommodate.  You may modify the LPRINT statement to send a CHR$(9) or some
'other binary data to test that it works properly.


DEFINT A-Z
'$INCLUDE: 'PDQDECL'                    'SetCooked/SetRaw not declared here

DECLARE SUB SetCooked (Handle)
DECLARE SUB SetRaw (Handle)

DIM SHARED Regs AS RegType              'so both subprograms can use it

Handle = 4                              'this is the standard printer handle
CALL SetRaw(Handle)
LPRINT "This is printed in Raw mode, and DOS will not disturb binary data."

CALL SetCooked(Handle)
LPRINT "This is printed in Cooked mode, and DOS will expand CHR$(9) Tabs."

SUB SetCooked (Handle) STATIC

  Regs.AX = &H4400                  'get the device data for this handle
  Regs.BX = Handle
  CALL Interrupt(&H21, Regs)
  Status = Regs.DX AND &HFF         'save the device data, clear DH for DOS
  
  Regs.DX = Status AND (NOT 32)     'specify Cooked mode
  Regs.AX = &H4401                  'set the device data for this handle
  CALL Interrupt(&H21, Regs)

END SUB

SUB SetRaw (Handle) STATIC
 
  Regs.AX = &H4400                  'get the device data for this handle
  Regs.BX = Handle
  CALL Interrupt(&H21, Regs)
  Status = Regs.DX AND &HFF         'save the device data, clear DH for DOS

  Regs.DX = Status OR 32            'specify Raw mode
  Regs.AX = &H4401                  'set the device data for this handle
  CALL Interrupt(&H21, Regs)

END SUB
