;********** MONSETUP.ASM - central monitor detection routine and data area

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
    Public  P$MonSeg        ;so everyone else can get at them
    Public  P$CGAPort 

.Data
    P$CGAPort DW 0          ;holds CGA retrace port and serves as "snow" flag
    P$MonSeg  DW 0          ;this is the current video display segment
                            ;if it is non-zero, then we've been here before
.Code

P$MonSetup Proc Uses CX     ;a user reported a screwy BIOS that trashes CX

    Xor  AX,AX              ;make a zero to examine low memory
    Cmp  P$MonSeg,AX        ;have we already checked the monitor type?
    Jne  Exit               ;yes, get on with it

    Mov  ES,AX              ;no, look in low memory through ES
    Mov  P$MonSeg,0B000h    ;assume a monochrome monitor
    Mov  P$CGAPort,AX       ;and clear the "snow check" flag

    Cmp  Byte Ptr ES:[463h],0B4h    ;is it monochrome?
    Je   Exit                       ;yes, skip ahead
    Add  P$MonSeg,800h              ;no, adjust to the color segment

    Mov  AH,12h             ;see if it's an EGA or VGA
    Mov  BL,10h             ;using the "Request EGA info" service
    Push BP                 ;some old PC BIOS's trash BP during an Int 10h
    Int  10h                ;call the BIOS
    Pop  BP                 ;get BP back again

    Cmp  BL,10h             ;BL will still hold 10h if it's not an EGA
    Jne  Exit               ;it's an EGA or VGA
    Mov  P$CGAPort,3DAh     ;it's a CGA, set the flag

Exit:
    Ret                     ;return to caller

P$MonSetup Endp
End
