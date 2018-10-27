;********** PLAY.ASM - P.D.Q. replacment for BASIC's B$SPLY routine

;Copyright (c) 1990 Crescent Software
;Written by Paul Passarelli
; 11/3/92  Thomas G. Hanlin III   added far string support

.Model Medium, BASIC
    Extrn P$FixStr : Proc       ;this is in FIXSTR.ASM
    Extrn  P$Delay : Proc       ;this is in P$DELAY.ASM
    Extrn  P$Sound : Proc       ;this is in P$SOUND.ASM
    Extrn  P$Speaker  : Proc    ;these are in SPEAKER.ASM
    Extrn  P$SPKR_ON  : Proc    ;turns speaker on
    Extrn  P$SPKR_OFF : Proc    ;turns speaker off

.Data
    Clock     DD  30720   ;product of "120 * 4 * 8 * 8"
    Tempo     DW  120     ;T120 default 1/4 notes/minute  range 32-255
    NoteLen   DW  4       ;L4 default  1/4 note  range 1-64
    SNL       DW  7       ;stacato 3/4, normal 7/8, legato 1/1,  on/off
    Octave    DB  2       ;default to the second from top octave
    ScoreEnd  DW  ?

    BufAdr    DW  Offset EndBuf
    EndBuf    DD  ?
    Extrn  P$Fudge: Byte  ;this is in P$DELAY.ASM

.Code

B$SPLY Proc Uses SI DI, Tune:Word

    Push Tune             ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Tune,AX          ;

    Cmp  P$Fudge,0        ;has our delay timer been initialized?
    Jne  Init_Play        ;yes, just worry about what to play

    Xor  AX,AX            ;create a zero to push
    Push AX               ;select no delay time
    Call P$Delay          ;initializes itself the first time it's called
    Call P$Speaker        ;get the speaker ready too

Init_Play:
    Cld                   ;work forward through the string
    Mov  SI,Tune          ;string descriptor to SI
    Mov  CX,[SI]          ;length of the string in CX
    Jcxz Caller
    Mov  SI,[SI+2]        ;have SI point to the actual string data
    Push SI               ;save the starting address for the exit routine
    Push CX               ;save the length for exit routine

;-- Save the four bytes past the end of the string, and install four CHR$(0)
;   bytes as an "end" marker.
    Push SI               ;save it ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
    Add  SI,CX            ;1 past the end                            ³
    Push SI               ;save it ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ³
    Push DS               ;set ES = DS                             ³ ³
    Pop  ES               ;                                        ³ ³
    Mov  DI,BufAdr        ;local storage for stuff past the end    ³ ³
    MovSW                 ;copy the data to local storage          ³ ³
    MovSW                 ;                                        ³ ³
    Dec  SI               ;so we're not 1 past the end             ³ ³
    Mov  ScoreEnd,SI      ;point to last character of the string   ³ ³
    Pop  DI               ;point to old data to kill ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ ³
    Xor  AX,AX            ;make a zero                               ³
    StoSW                 ;store 'em                                 ³
    StoSW                 ;store 'em                                 ³
    Pop  SI               ;get the beginning of the string back ÄÄÄÄÄÙ

ReadMusic:
    Call Get_Cap          ;fetch an upper case letter, then see what we do
    Jc   Exit             ;Quit? (carry means the end of the string)
    Mov  DI,SI            ;no, keep a copy of the string pointer handy

    Cmp  AL,"T" ;54h      ;set the tempo?
    Je   _Tempo
    Cmp  AL,">" - 20h     ;play an octave higher? (-20h because Get_Cap ANDs)
    Je   _Up_Octave
    Cmp  AL,"<" - 20h     ;or do we play an octave lower?
    Je   _Dn_Octave
    Cmp  AL,"O" ;4Fh      ;change the octave?
    Je   _Octave
    Cmp  AL,"M" ;4Dh      ;play stacato, normal, or legato?
    Je   _M_SNL
    Cmp  AL,"P" ;50h      ;pause a Pth note?  (P8 = 1/8 note, P2 = 1/2 note)
    Je   _Pause

    Call Regular_Note     ;a note perhaps?   A-G  or  N(0-96)

    Cmp  AL,"L" ;4Ch      ;maybe change the length of the notes?
    Jne  ReadMusic
    Call _Length
    Jmp  Short ReadMusic

Exit:
    Call P$SPKR_OFF       ;REM this line to allow continous tone after 'PLAY'
    Pop  CX               ;length of the string in CX
    Pop  SI               ;have SI point to the actual string data
    Add  SI,CX            ;1 past the end
    Mov  DI,BufAdr        ;local storage for stuff past the end
    Xchg SI,DI            ;recover the four bytes past the end of the string
    MovSW
    MovSW
Caller:
    Ret                   ;return to BASIC



_Tempo:
    Call __Meter          ;get the number to set the tempo to
    Cmp  AX,32            ;compare it to the lowest value
    Jb   Tempo_0          ;below? don't do it
    Mov  Tempo,AX         ;accept the new tempo
Tempo_0:
    Jmp  ReadMusic


_Up_Octave:
    Cmp  Octave,0         ;may we ?
    Jbe  _Up_Octave_0     ;no.
    Dec  Byte Ptr Octave  ;yes.
_Up_Octave_0:
    Jmp  ReadMusic


_Dn_Octave:
    Cmp  Octave,6         ;may we ?
    Jae  _Dn_Octave_0     ;no.
    Inc  Byte Ptr Octave  ;yes.
_Dn_Octave_0:
    Jmp  ReadMusic


_Octave:
    Call __Meter
    Cmp  SI,DI            ;did we read any characters?
    Je   _Octave_0        ;no, we can't do anything
    Mov  AH,6             ;maximum
    Cmp  AL,AH            ;is it above
    Ja   _Octave_0        ;yes, go away
    Sub  AH,AL            ;normalize the shift count
    Mov  Octave,AH        ;set the octave
_Octave_0:
    Jmp  ReadMusic


_M_SNL:
    Call Get_Cap          ;get the next char
    Jc   _M_SNL_0         ;carry says we failed
    Mov  DX,8             ;all of the NoteLen
    Cmp  AL,"L" ;4Ch      ;do we set Legato?
    Je   _M_Set
    Dec  DX               ;7/8 of the NoteLen
    Cmp  AL,"N" ;4Eh      ;do we set Normal?
    Je   _M_Set
    Dec  DX               ;3/4 of the NoteLen
    Cmp  AL,"S" ;53h      ;do we set Stacato?
    Jne  _M_SNL_0
_M_Set:
    Mov  SNL,DX
_M_SNL_0:
    Jmp  ReadMusic


_Pause:
    Call P$SPKR_OFF
    Call __Meter          ;see what kind of rest we take
    Jbe  _Pause_0         ;check for an error  CF=1 or ZF=1
    Mov  CX,AX            ;save it
    Mov  BX,Offset Clock
    Mov  AX,[BX]          ;put the long in DX:AX
    Mov  DX,[BX+2]
    Div  Tempo            ;divide by the tempo
    Shl  AX,1             ;multiply by 2
    Shl  AX,1             ;   "      4
    Shl  AX,1             ;   "      8
    Cwd                   ;clear DX
    Div  CX               ;divide by the note fraction
    Push AX               ;pass the parameter
    Call P$Delay          ;be quiet for AX milliseconds
_Pause_0:
    Jmp  ReadMusic


_NumberNote:
    Pop  AX               ;clear the stack
    Call __Meter
    Jnz  a_Note
    Cwd                   ;zero in DX
    Call __Note
    Jmp  ReadMusic
a_Note:
    Add  AL,12            ;make 4 the lowest note, can't do 1, 2, or 3
    Cmp  AL,108           ;this would be too high
    Ja   _NumberNote_0
    Add  AL,-96           ;establish a shift count
    Neg  AL               ;make it a positive number
    Mov  BX,12            ;12 to BL  0 to BH
    Div  BL               ;AX \ 12
    Mov  BL,AH            ;remainder to BX
    Shl  BL,1             ;remainder * 2
    Mov  DI,Offset SCALE  ;point to the note table
    Mov  DX,CS:[DI+BX]    ;select the note
    Mov  CL,AL            ;shift count in CL
    Shr  DX,CL            ;put it in the correct octave
    Call __Note
_NumberNote_0:
    Jmp  ReadMusic

Regular_Note:
    Cmp  AL,"N" ;4Eh      ;make a numbered sound?
    Je   _NumberNote
    Mov  DI,Offset NoteA
    Cmp  AL,"A"
    Je   Musical_Note
    Mov  DI,Offset NoteB
    Cmp  AL,"B"
    Je   Musical_Note
    Mov  DI,Offset NoteC
    Cmp  AL,"C"
    Je   Musical_Note
    Mov  DI,Offset NoteD
    Cmp  AL,"D"
    Je   Musical_Note
    Mov  DI,Offset NoteE
    Cmp  AL,"E"
    Je   Musical_Note
    Mov  DI,Offset NoteF
    Cmp  AL,"F"
    Je   Musical_Note
    Mov  DI,Offset NoteG
    Cmp  AL,"G"
    Je   Musical_Note
    RetN                  ;not a note, allow the next test

Musical_Note:
    Pop  AX               ;clear the stack
    Push SI
    Cmp  SI,ScoreEnd
    Ja   Musical_Note_0
    Push NoteLen
    Lodsb                 ;look for a Sharp "+" and "#", or a flat "-"
    Cmp  AL,"-"           ;look for flat first
    Ja   Natural
    Jb   Sharp
    Inc  DI               ;have DI point to a higher address & lower note
    Inc  DI               ;this assumes it will be flat
    Jmp  Short Aquired
Sharp:
    Cmp  AL,"#"
    Jb   Natural
    Je   Sharpen
    Cmp  AL,"+"
    Jne  Natural
Sharpen:
    Dec  DI               ;have DI point to a lower address & higher note
    Dec  DI
    Jmp  Short Aquired
Natural:
    Dec  SI
Aquired:
    Call _Length          ;see if we use a temp note length
    Mov  DX,CS:[DI]       ;get the base frequency from the table

    Mov  CL,Octave        ;get the shift count
    Shr  DX,CL            ;shift it down

    Call __Note           ;play the note
    Pop  NoteLen          ;recover the standard note length
Musical_Note_0:
    Pop  SI
    Clc
    Jmp  ReadMusic


_Length:
    Call __Meter
    Jnbe _Length_1        ;jmp if CF=0 and ZF=0
    RetN
_Length_1:
    Cmp  AX,64
    Ja   _Length_0
    Mov  NoteLen,AX
_Length_0:
    RetN                  ;called from multiple places


__Note:
    Sub  SP,2             ;the silent part
    Mov  BP,SP
    Push DX               ;the frequency
    Mov  BX,Offset Clock
    Mov  AX,[BX]
    Mov  DX,[BX+2]

    Div  Tempo
    Shl  AX,1             ;multiply by 2
    Shl  AX,1             ;   "      4
    Shl  AX,1             ;   "      8
    Cwd
    Div  NoteLen          ;DX:AX \ notelen
    Mov  BX,AX            ;BX gets the notes duration
    Mul  SNL              ;times 6 or 7 or 8
    Mov  CL,3
    Shr  AX,CL

    Sub  BX,AX            ;0 or 1 or 2 8ths
    Jnz  _Duration
    Neg  AX
_Duration:
    Mov  [BP],BX
    Push AX               ;the duration
    Call P$Sound          ;listen to the sound
    Call P$Delay          ;wait for the silent part
    RetN


__Meter:                  ;returns 0 to 255 in AX
    Xor  DX,DX            ;zero DX
    Mov  BX,1910h         ;same as:  Mov  BH,""  Mov  BL,""  but less code
                          ;these are translation products from Get_Cap
    Mov  AH,16            ;AH will convert 2 digits before cleared by Mul
    Cwd                   ;1 byte less then Xor  DX,DX

    Call Get_Cap          ;1st char of number
    Jc   __Meter_0        ;carry for failure

    Cmp  AL,BL            ;was it above zero "0"?
    Jb   No_Digit
    Cmp  AL,BH            ;was it below nine "9"?
    Ja   No_Digit
    Sub  AL,AH            ;convert to digit
    Mov  DL,AL            ;save in DL

    Call Get_Cap          ;now, get the 2nd char of number
    Jc   No_Digit         ;carry if there was a failure
    Cmp  AL,BL            ;was it above zero "0"?
    Jb   No_Digit
    Cmp  AL,BH            ;was it below nine "9"?
    Ja   No_Digit
    Sub  AL,AH            ;convert to digit
    Xchg DL,AL            ;swap w/ 1st digit
    Mov  DH,10            ;for the multiply
    Mul  DH               ;1st digit to the tens place
    Add  DL,AL            ;this digit to the units

    Call Get_Cap          ;now, get the 3rd char of number
    Jc   No_Digit         ;carry for failure
    Cmp  AL,BL            ;was it above zero "0"
    Jb   No_Digit
    Cmp  AL,BH            ;was it below nine "9"
    Ja   No_Digit
    Sub  AL,16            ;convert to digit
    Xchg DL,AL            ;swap w/ 1st 2 digits
    Mul  DH               ;get 1st 2 into the tens & hundreds
    Mov  DH,AH
    Add  AX,DX            ;add the 3rd as units
    RetN                  ;and we're done no problems.
No_Digit:
    Jc   No_Dig_No_Score
    Dec  SI               ;undo a useless read
No_Dig_No_Score:
    Xor  AX,AX            ;clear AX to accept the output
    Mov  DH,AL            ;clear the high byte of the temp accumulator
    Add  AX,DX            ;set the result and set the zero flag
    RetN
__Meter_0:
    Mov  AH,0
    RetN


Get_Cap:                  ;fetches next char from string and capitalizes it
    Mov  AL,0             ;start with a clean slate
    Cmp  [ScoreEnd],SI    ;check for the end of the string
    Jc   Get_Cap_0        ;jump on failure
    LodSB                 ;get a character
    Cmp  AL," "           ;is it a CTRL-character or space?
    Jbe  Get_Cap          ;yes, absorb it
    And  AL,(not 32)      ;no, force upper case and clear carry
Get_Cap_0:
    RetN

B$SPLY EndP


;      Table of frequencies
         dw  8372         ;C8
SCALE:
NoteB:   dw  7902         ;B7
         dw  7458         ;A#7
NoteA:   dw  7040         ;A7
         dw  6644         ;G#7
NoteG:   dw  6272         ;G7
         dw  5920         ;F#7
NoteF:   dw  5588         ;F7
NoteE:   dw  5274         ;E7
         dw  4978         ;D#7
NoteD:   dw  4698         ;D7
         dw  4434         ;C#7
NoteC:   dw  4186         ;C7
         dw  3952         ;B6

END
