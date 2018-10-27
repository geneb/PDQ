;********* CLS.ASM - PDQ replacement for BASIC's B$SCLS routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    Extrn P$Color: Byte   ;this is in COLORDAT.ASM
    Extrn P$TabTable:Byte ;this is in FHANDLES.ASM

.Data?
    Rows DB 1 Dup(?)      ;these are stored one-based (1-25, 1-80)
    Cols DB 1 Dup(?)

.Code

B$SCLS Proc, Dummy:Word

    Call Far Ptr _GetRows ;get the current number of rows/columns
    Xor  CX,CX            ;set upper left corner to 0,0
    Mov  DH,Rows          ;get the number of available rows
    Dec  DH               ;adjust 1-25 to 0-24
    Mov  DL,Cols          ;get the number of columns
    Dec  DL               ;as above
    
    Mov  AX,600h          ;clear window service
    Mov  BH,P$Color       ;use BASIC's current color
    Int  10h              ;let the BIOS do the dirty work
    Xor  DX,DX            ;home the cursor at 0,0
    Mov  BH,DH            ;do it on page zero
    Mov  AH,2             ;locate cursor service
    Int  10h              ;call the BIOS

    Mov  P$TabTable+1,0   ;a CLS resets the current screen Tab column to 0
    Ret                   ;return to caller

B$SCLS Endp


_GetRows Proc Uses AX BX ES BP

    Mov  AH,0Fh           ;get the current video mode BIOS service
    Int  10h              ;call the BIOS (some old BIOS's trash BP)
    Mov  Cols,AH          ;assign Cols above
    Mov  Rows,25          ;assume a 25 line screen
    Xor  AX,AX            ;look at low memory
    Mov  ES,AX            ;through ES
    Cmp  Word Ptr ES:[463h],0B4h   ;is it a mono display?
    Je   Exit                      ;yes, so we're all done

    Mov  AH,12h           ;ask for EGA info to see if it's an EGA or VGA
    Mov  BL,10h
    Int  10h
    Cmp  BL,10h           ;BL will still hold 10h if it's not an EGA
    Jz   Exit             ;not an EGA, we're outa' here
    Mov  AL,ES:[484h]     ;this bytes tells holds the number of screen rows
    Inc  AL               ;adjust 24, 42, or 49 up to 25, 43, or 50
    Mov  Rows,AL          ;set Rows to hold the correct value

Exit:
    Ret                   ;return to caller

_GetRows Endp
End
