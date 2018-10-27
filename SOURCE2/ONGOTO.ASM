;******** ONGOTO.ASM - PDQ replacement for BASIC's B$OGTA and B$OGSA routines

;Copyright (c) 1989 Ethan Winer


;The code that calls ON GOTO (or ON GOSUB) is set up as follows:
;
;ON Value GOTO/GOSUB Label1, Label2, Label3
;   Mov  BX,Value
;   Call B$OGTA
;   DB   NumLabels
;   DW   Label1
;   DW   Label2
;   DW   Label3
;   the next statement in sequence continues here

.Model Medium, Basic
.Data?
    Extrn P$RetAdr:Word   ;these are in SUBDATA.ASM
    Extrn P$RetSeg:Word   ;they hold the return address to jump to

.Code

B$OGSA Proc
    DB   0B8h             ;this fakes the instruction below to Mov AX,E432h
B$OGSA Endp               ;B$OGTA can then decide how to return based on AH


B$OGTA Proc

    Xor  AH,AH            ;clear AH to show they used ON GOTO, not ON GOSUB
    Mov  DX,BX            ;transfer the ON GOTO value to DX
    Shl  DX,1             ;convert to words for indexing the address list

    Pop  BX               ;retrieve the caller's return address
    Pop  ES               ;and the code segment too
    Mov  P$RetSeg,ES      ;no matter what, this is the segment we'll jump to

    Mov  CL,ES:[BX]       ;load CL with the number of labels in the list
    Xor  CH,CH            ;clear CH so we can use all of CX
    Shl  CX,1             ;convert from bytes to words
    Push CX               ;save CX for a moment
    Inc  BX               ;bump BX past the "number of labels" byte
    Add  CX,BX            ;calculate the address following the list of labels
    Mov  P$RetAdr,CX      ;save it in case the ON GOTO value was out of range
    Pop  CX               ;restore CX to the number of labels in the list

    Or   DX,DX            ;is the ON GOTO value zero?
    Jz   Exit             ;yes, so use the return address already in place
    Cmp  DX,CX            ;is the value greater than the number of labels?
    Ja   Exit             ;yes, same as above

    Or   AH,AH            ;see if we're doing an ON GOSUB or an ON GOTO
    Jz   OnGoto           ;if AH is zero then they used ON GOTO, skip ahead
    Push P$RetAdr         ;show where the ON GOSUB routine should return to

OnGoto:
    Add  BX,DX            ;get the address of the address to return to
    Mov  BX,ES:[BX-02]    ;then load the actual address from the code segment
                          ;(-2 since the offset into the table is zero-based)
    Mov  P$RetAdr,BX      ;stuff that into the jump address

Exit:
    Jmp  DWord Ptr P$RetAdr ;jump directly to the appropriate address

B$OGTA Endp
End
