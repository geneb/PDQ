;********** PRNCOMMA.ASM - PDQ replacement for BASIC's B$PCSD routine

;Copyright (c) 1989 Ethan Winer


;This routine handles BASIC's PRINT when a trailing comma is used.


.Model Medium, Basic
    Extrn B$PESD:Proc     ;this is in PRINT.ASM
    Extrn B$PSSD:Proc     ;this is in PRINT.ASM
    Extrn B$SPAC:Proc     ;this is in SPACE$.ASM

.Data
    Extrn P$PrintHandle:Word    ;this is in PHANDLE.ASM
    Extrn P$TabTable:Byte       ;this is in FHANDLES.ASM
    Extrn P$Descr:Word          ;this is in PRINTDAT.ASM
    Extrn P$NullDesc:Word       ;this is in PRINTDAT.ASM

.Code

B$PCSD Proc, Work:Word    ;print string and advance to next Tab stop
                          ;PCSD = Print Comma String Descriptor
    Push Work             ;pass the address for Work$ on to B$PSSD
    Call B$PSSD           ;let B$PSSD (PRINT with semicolon) do the real work
    
    Mov  BX,P$PrintHandle ;load BX with the current print handle
    Mov  AL,P$TabTable[BX];get the current column count for this DOS handle
    Cmp  BL,1             ;are we printing to the screen?
    Jne  GoodZone         ;no, so skip this mess
    
    Cmp  AL,69            ;are we past the fifth "print zone"?  (0-based)
    Jbe  GoodZone         ;no, skip over
    Mov  AX,Offset P$NullDesc   ;yes, pass the address of the empty public
    Push AX                     ;  descriptor on to B$PESD
    Call B$PESD           ;and print it to reset the Tab table and do a CRLF
    Jmp  Short Exit       ;all done

GoodZone:
    Xor  AH,AH            ;convert to an unsigned word for dividing below
    Mov  CX,14            ;divide by 14 to obtain CurColumn MOD 14, because
    Div  CL               ;  BASIC sees the screen as blocks of 14 characters
    Sub  CL,AH            ;now CL tells how many blanks to print

    Push CX               ;pass that on to SPACE$() as the number of blanks
    Call B$SPAC           ;this returns a descriptor address in AX
    Push AX               ;pass that on to B$PSSD (PRINT with a semicolon)
    Call B$PSSD           ;this prints the blanks to the current file handle

Exit:
    Ret                   ;return to caller

B$PCSD Endp
End
