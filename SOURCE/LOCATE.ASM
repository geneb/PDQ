;********** LOCATE.ASM - PDQ replacement for BASIC's B$LOCT routine

;Copyright (c) 1990 Crescent Software
;written by Paul Passarelli

;See the comments in COLOR.ASM for an explanation of how BASIC routines can
;receive a varying number of parameters.

.Model Medium, Basic

.Data?
    Col     DB 1 Dup (?)
    Row     DB 1 Dup (?)
    Stop    DB 1 Dup (?)
    Start   DB 1 Dup (?)        ;On/Off is Bit 5 of CH, 1 turns it off

.Code

B$LOCT Proc Uses SI, NumArgs:Word

    Mov  SI,NumArgs             ;BASIC passes the number of arguments
    Inc  SI                     ;but it's actually one less than what we need
    Shl  SI,1                   ;moreover, Ret n uses two bytes per parameter
    Mov  CS:Patch,SI            ;self-modify the code below as necessary

    Cmp  SI,2                   ;check for zero arguments
    Ja   Default_Info           ;there are some, go get the current info
    Jmp  Exit                   ;they said LOCATE, but locate what???
                                ;unbelieveably, BC compiles LOCATE w/no args
Default_Info:
    Push BP                     ;some old BIOSes trash BP during an Int 10h
    Mov  AH,15                  ;select "get current video mode" service
    Int  10h                    ;the active page will be returned in BH,
                                ;  which is then used by the rest of LOCATE
    Mov  AH,3                   ;select "read cursor information" service
    Int  10h                    ;go get it!
    Pop  BP
    Mov  Word Ptr Stop,CX       ;save the current scan lines in one operation
    Mov  Word Ptr Col,DX        ;save the current row and column positions

    Mov  DX,4                   ;save this to know when we hit the last param
    Add  SI,DX                  ;this added to BP points to the first param

    Cmp  Word Ptr [BP+SI],0     ;are we getting a row?
    Je   GetCol                 ;no, move on
    Dec  SI                     ;yes
    Dec  SI                     ;point to the parameter

    Mov  AX,[BP+SI]             ;now get the row number
    Cmp  SI,DX                  ;is this the last parameter?
    Jbe  Locate_Only            ;yes, early conclusion
    Dec  AL                     ;no, adjust 1-25 to 0-24
    Mov  Row,AL                 ;and replace the default we got earlier

GetCol:
    Dec  SI                     ;point to the next parameter
    Dec  SI
    Cmp  SI,DX                  ;are we past the end point?
    Jbe  Locate_Only            ;yes, that was the last one given

    Cmp  Word Ptr [BP+SI],0     ;see if we are getting a column
    Je   GetOnOff               ;no, move on
    Dec  SI                     ;yes, point to the column parameter
    Dec  SI
    Mov  AX,[BP+SI]             ;get it
    Cmp  SI,DX                  ;are we past the end point?
    Jbe  Locate_Only            ;yes, early conclusion
    Dec  AL                     ;adjust 1-80 to 0-79
    Mov  Col,AL                 ;replace the default

GetOnOff:
    Dec  SI                     ;as above
    Dec  SI
    Cmp  SI,DX                  ;are we past the end point?
    Jbe  Locate_Only            ;yes, early conclusion

    Cmp  Word Ptr [BP+SI],0     ;see if we are getting the on/off switch
    Je   GetStart               ;no, move on
    Dec  SI
    Dec  SI
    Mov  AX,[BP+SI]             ;yes, see if we're turning it off

    Cmp  SI,DX                  ;are we past the end point?
    Jbe  Locate_Only            ;yes, early conclusion
    And  Start,11011111b        ;assume it will be turned on or left on
    Cmp  AL,1                   ;is this correct?
    Je   GetStart               ;yes, so that's done
    Or   Start,100000b          ;no, force it to turn off

GetStart:
    Dec  SI
    Dec  SI
    Cmp  SI,DX                  ;are we past the end point?
    Jbe  Locate_Size            ;yes, early conclusion

    Cmp  Word Ptr [BP+SI],0     ;see if we are getting a start line
    Je   GetStop                ;no, move on
    Dec  SI
    Dec  SI
    Mov  AX,[BP+SI]             ;yes, get it

    Cmp  SI,DX                  ;are we past the end point?
    Jbe  Locate_Size            ;yes, early conclusion
    And  Start,00100000b        ;clear the top scan line except for on/off
    Or   Start,AL
    Jnz  GetStop                ;it's supposed to be off, so we're done

GetStop:
    Dec  SI
    Dec  SI
    Cmp  SI,DX                  ;are we past the end point?
    Jbe  Locate_Size            ;yes, early conclusion

    Cmp  Word Ptr [BP+SI],0     ;see if we are getting a stop line
    Je   Locate_Size            ;no, move on
    Dec  SI
    Dec  SI
    Mov  AX,[BP+SI]             ;yes, get it
    Mov  Stop,AL                ;replace the default

Locate_Size:
    Mov  AH,1                   ;set service for scan line adjustment
    Mov  CX,Word Ptr Stop       ;load Stop and Start in one operation
                                ;no need to save BP here, it's restored below
    Int  10h                    ;turn it on or off as appropriate

Locate_Only:
    Mov  AH,2                   ;set service for Row / Col adgustment
    Mov  DX,Word Ptr Col        ;load Col and Row at once
    Int  10h                    ;locate the cursor position

Exit:
    Pop  SI                     ;we have to pop these manually
    Pop  BP
    DB   0CAh                   ;this is the opcode for Ret n
Patch DW 6                      ;assume 3 arguments (Ret 6)

B$LOCT Endp
End
