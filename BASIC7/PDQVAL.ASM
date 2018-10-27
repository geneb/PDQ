;----- PDQVAL.ASM - like BASIC's VAL for ints and long ints only, MUCH faster

;Copyright (c) 1990 Ethan Winer
;BC7 version J.Munro

;Syntax - Value = PDQValI%(Number$)
;         Value = PDQValL&(Number$)

.Model Medium, Basic
    Extrn B$MUI4:Proc     ;this is in MULTLONG.ASM
    Extrn StringLength:Proc ;these are QBX internal routines
    Extrn StringAddress:Proc

.Data?
    ValueLo DW 1 Dup (?)  ;this accumulates the value as we go
    ValueHi DW 1 Dup (?)
    DigitLo DW 1 Dup (?)  ;this tracks the current digit multiplier
    DigitHi DW 1 Dup (?)
    Mult    DW 1 Dup (?)  ;this holds either 10 (Decimal number) or 16 (Hex)
                          ;  for multiplying each digit position
.Code

PDQValI Proc              ;why waste space? -- PDQValL can serve both
PDQValI Endp              ;fall into the code below


PDQValL Proc Uses ES SI DI, Number:Word

    Cld                   ;insure that Lodsb will increment SI
    Xor  AX,AX            ;zero out AX for the assignments below
    Mov  DI,AX            ;clear DI as a "negative" flag
    Mov  ValueLo,AX       ;clear the Value words
    Mov  ValueHi,AX
    Mov  DigitHi,AX       ;seed the Digit words with 1
    Mov  DigitLo,1
    Mov  Mult,10          ;assume this'll be a regular decimal number

    Mov  SI,Number        ;get the address for Number$ descriptor
    Push ES
    Push SI
    Call StringLength     
    Mov  CX,AX            ;put its length into CX
    Pop  ES
    Push SI
    Call StringAddress
    Mov  ES,DX
    Xor  DX,DX
    Mov  SI,AX
    Or   CX,CX            ;is it a null string?
    Jnz  EatLoop          ;no, continue
    Jmp  Exit             ;yes, boy did someone ever blow it!
 
EatLoop:
    Mov  AL,ES:[SI]       ;get a digit
    Inc  SI
    Cmp  AL,32            ;is it a space?
    Loopz EatLoop         ;yes, eat it and Dec CX at the same time

    Inc  CX               ;no, bump CX back up because this was a valid char
    Dec  SI               ;and bump SI back as well to the last address

    Cmp  AL,38            ;now see if it's an "&" meaning a HEX value
    Jne  DecVal           ;no, skip ahead
    Mov  Byte Ptr Mult,16 ;yes, we'll be multiplying times 16 at each digit
    Inc  SI               ;eat the "&"
    Inc  SI               ;and the "H" too
    Dec  CX               ;show the string being that much shorter
    Dec  CX
    Jmp  Short HexVal     ;skip over the decimal-only code below

DecVal:
    Cmp  AL,"-"           ;is it a negative number?
    Jne  TryPlus          ;no, but see if it's a plus sign
    Dec  DI               ;yes, remember that by setting DI to -1 as a flag
@@:
    Inc  SI               ;advance over the minus (or plus) sign
    Dec  CX               ;show the string being that much shorter
    Jnz  ScanStr          ;there's more than just a minus/plus sign
    Sub  AL,AL            ;the minus/plus sign is all there is, clear AL to
    Jmp  Exit             ;  return 0 in DX:AX and then exit

TryPlus:
    Cmp  AL,"+"           ;is it a leading plus sign?
    Je   @B               ;yes, jump back to the code that eats the minus

ScanStr:
    Push SI               ;save SI while we scan for the last valid character

ScanLoop:
    Mov  AL,ES:[SI]       ;get a character
    Inc  SI
    Cmp  AL,"0"           ;is it lower than "0"?
    Jb   DoVal            ;yes, so we reached the "logical" end of the string
    Cmp  AL,"9"           ;is it higher than "9"
    Ja   DoVal            ;as above
    Inc  DX               ;show that we successfully got another digit
    Loop ScanLoop         ;until the end or an invalid character

DoVal:
    Pop  SI               ;point SI back to the start of the string again
    Mov  CX,DX            ;this is how many characters to scan
    Xor  AX,AX            ;clear AX in case it the entire string was invalid

HexVal:
    Std                   ;set direction to walk backwards through the string
    Jcxz Exit             ;ain't nothin' there
    Add  SI,CX            ;now SI points just past the end of the string
    Dec  SI               ;and now it's on the last character

ValLoop:
    Mov  AL,ES:[SI]       ;get the current character
    Dec  SI
    Sub  AL,"0"           ;convert from ASCII to a byte value
    Cmp  AL,9             ;did that bring it down into the range 0 through 9?
    Jbe  DecDigit         ;yes, so it's a decimal digit
    And  AL,011111b       ;no, first force it to upper case
    Sub  AL,7             ;then adjust "A" through "F" down to 10 through 15

DecDigit:
    Push CX               ;save CX because B$MUI4 trashes it
    Cbw                   ;convert this digit to a double word
    Cwd
    Push DX               ;pass that on to B$MUI4
    Push AX

    Push DigitHi          ;pass the current Digit value too
    Push DigitLo          ;  so we can multiply this digit times the
    Call B$MUI4           ;  weighted value (1, 16, 256, 4096, etc.)
    Add  ValueLo,AX       ;apply that to the accumulated value
    Adc  ValueHi,DX

    Mov  AX,Mult          ;get a 10 (or 16) in preparation for multiplication
    Cwd                   ;convert to a double word
    Push DX               ;again, we'll let B$MUI4 do the work
    Push AX
    Push DigitHi
    Push DigitLo

    Call B$MUI4           ;this returns the new value for Digit in DX:AX
    Mov  DigitLo,AX
    Mov  DigitHi,DX
    Pop  CX               ;retrieve the loop counter saved earlier
    Loop ValLoop          ;until we've processed the first character

    Mov  DX,ValueHi       ;assign DX:AX to the output value
    Mov  AX,ValueLo

    Inc  DI               ;see if the number was negative
    Jnz  Exit             ;no, continue
    Not  AX               ;yes, change the sign
    Not  DX               ;  by flipping the bits
    Add  AX,1             ;  then adding one
    Adc  DX,DI            ;  to the 32 bit result (DI is now zero)

Exit:
    Cld                   ;BASIC needs the direction flag cleared to forward
    Ret                   ;and exit

PDQValL Endp
End
