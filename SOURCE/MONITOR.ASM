;----- MONITOR.ASM - reports the type of display adpater currently in use
;
;Copyright (c) 1989 Ethan Winer - with special thanks to Rick Furr
;
;Calling syntax:  MonType = Monitor%
;
;where MonType is assigned:
;
;    1 = Monochrome adapter
;    2 = Hercules monochrome adapter
;    3 = CGA adapter
;    4 = EGA adapter w/mono monitor
;    5 = EGA adapter w/color monitor
;    6 = VGA adapter w/mono monitor
;    7 = VGA adapter w/color monitor
;    8 = MCGA adapter w/mono monitor
;    9 = MCGA adapter w/color monitor
;   10 = EGA adapter w/CGA monitor
;   11 = IBM 8514/A

.Model Medium, Basic
.Data
    MonSeg  DW 0          ;holds the current monitor segment
    CGAPort DW 0          ;holds the CGA port to check for horizontal retrace
    MonType DW 0          ;holds the monitor type code

.Code

PDQMonitor Proc Uses BP   ;save BP - older PC BIOS's trash BP during Int 10h

    Mov  AX,MonType       ;assume we've already checked the monitor type
    Or   AX,AX            ;have we been here before?
    Jz   Continue         ;no, skip ahead and continue checking
    Jmp  Exit             ;yes, don't bother checking again

Continue:
    Mov  MonSeg,0B800h    ;assume a color monitor
    Xor  AX,AX            ;now see if the current monitor is mono
    Mov  ES,AX            ;look in low memory
    Mov  AL,ES:[463h]     ;in the BIOS data area
    Cmp  AL,0B4h          ;is it mono?
    Jne  Color            ;nope
    Sub  MonSeg,800h      ;adjust MonSeg for a monochrome monitor

    Mov  CX,8000h         ;we're going to test this 32,768 times
    Mov  DX,3BAH          ;Hercules video status port
    In   AL,DX            ;if bit 7 ever changes, it's a Herc card
    And  AL,80h           ;isolate just the bit we care about
    Mov  AH,AL            ;save it in AH

HercLoop:
    In   AL,DX            ;now read register repeatedly
    And  AL,80h           ;isolate the bit again
    Cmp  AL,AH            ;has it changed?
    Jne  Hercules         ;yes, a Herc card must be installed
    Loop HercLoop         ;the bit hasn't changed yet, keep looping
    Jmp  Short Color      ;if we got this far, it's not a Hercules

Hercules:
    Mov  AX,2             ;indicate a Hercules adapter
    Jmp  Exit             ;and get out of here

Color:
    Mov  AX,1A00h         ;see if it's a VGA adapter
    Int  10h
    Cmp  AL,1Ah           ;was it a VGA?
    Jne  EGA              ;no, but maybe it's an EGA
    Xor  BH,BH            ;yes, clear BH so we can use all of BX
    Dec  BL               ;adjust for our monitor return code method
    Mov  AX,BX            ;assign AX from BL in case it is a VGA
    Mov  DL,ES:[463h]     ;and get the mono/color byte in low memory

    Cmp  BL,6             ;if it really is a VGA, BL will now be 6 or 7
    Jne  TryColorVGA      ;it's not a mono VGA, so see if it's a color VGA
    Cmp  DL,0B4h          ;if this isn't B4h then it must be an 8514/A
    Je   Exit             ;it is a mono VGA, so we're all done
    Mov  AX,11            ;the only combination that reports a mono VGA AND
    Jmp  Short Exit       ;  shows a color monitor in low memory is an 8514/A

TryColorVGA:
    Cmp  BL,7             ;is it a color VGA?
    Jne  EGA              ;no, so see if it's an EGA
    Cmp  DL,0B4h          ;does low-memory show a mono monitor anyway?
    Jne  Exit             ;no, so we're correct in reporting a color VGA
    Dec  AL               ;yes, they used MODE MONO, so force a 6 (VGA mono)
    Jmp  Short Exit       ;and get out

EGA:
    Mov  AH,12h           ;ask for EGA info to see if it's an EGA
    Mov  BL,10h
    Int  10h
    Cmp  BL,10h           ;BL will still hold 10h if it's not an EGA
    Je   CGA              ;not an EGA, so it must be a CGA or plain mono

    And  CL,00000110b     ;but wait - see if EGA is emulating a CGA
    Cmp  CL,0110b         ;well, is it?
    Je   ECGA             ;yes, let the code at label ECGA: handle it

    Mov  AX,5             ;assume EGA is connected to a color monitor
    Or   BH,BH            ;but is it really?
    Jz   Exit             ;yes, leave AX set to 5 and get outa' here
    Dec  AX               ;no, show that it's a mono monitor with an EGA board
    Jmp  Short Exit       ;and go bye bye

ECGA:
    Mov  AX,10            ;assume EGA w/color monitor
    Or   BH,BH            ;is the monitor color?
    Jz   Exit             ;yea boy - a Poor Man's EGA (640 x 200 x 16 colors)
                          ;  this can use QuickBasic's SCREEN 8
                          ;  if it's not then fall through to the CGA section

CGA:
    Mov  AL,ES:[463h]     ;see again if the current monitor is color or mono
    Cmp  AL,0B4h          ;is it mono?
    Mov  AX,1             ;assume it is
    Je   Exit             ;and it is

    Mov  AX,1A00h         ;see if it's a PS/2 using an MCGA monitor
    Int  10h              ;call the BIOS
    Or   AL,AL            ;is AL still 0 meaning it's not an MCGA?
    Mov  AX,3             ;indicate a CGA monitor in case it's not an MCGA
    Mov  CGAPort,3DAh     ;and assign the retrace port for the other routines
    Jz   Exit             ;"Or AL,AL" above says not MCGA, so it must be CGA

    Mov  CGAPort,0        ;it is an MCGA, so clear the CGA retrace flag again
    Cmp  BL,0Bh           ;is it monochrome?
    Mov  AX,8             ;assume it is
    Je   Exit             ;we were right
    Inc  AX               ;no, so it must be color - bump AX up to 9

Exit:
    Mov  MonType,AX       ;save the monitor type for the other video routines
    Ret                   ;monitor type is returned in AX

PDQMonitor Endp
End
