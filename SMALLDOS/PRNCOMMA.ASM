;********** PRNCOMMA.ASM - SMALLDOS replacement for BASIC's B$PCSD routine

;Copyright (c) 1989 Ethan Winer


;This routine handles BASIC's PRINT when a trailing comma is used.

.Model Medium, Basic
    Extrn B$FPOS:Proc       ;this is in POS0.ASM
    Extrn B$PSSD:Proc       ;this is in PRINT.ASM
    Extrn B$SPAC:Proc       ;this is in SPACE$.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Data
    Extrn P$PrintHandle:Word     ;this is in PHANDLE.ASM
    Tab   DB 9                   ;a Tab character

.Code

B$PCSD Proc, Work:Word      ;print string and advance to next Tab stop
                            ;PCSD = Print Comma String Descriptor
    Push Work               ;pass the address for Work$ on to B$PSSD  
    Call B$PSSD             ;let B$PSSD do the real work

    Mov  BX,P$PrintHandle   ;load BX with the current print handle
    Cmp  BL,1               ;are we printing to the screen?
    Je   DoScreen           ;yes, calculate the number of spaces needed
                            ;no, the best we can do is send a Tab to the file
    Mov  DX,Offset Tab      ;show DOS where the Tab character is
    Mov  CX,1               ;specify a single character
    Mov  AH,40h             ;write service
    Int  21h                ;do it
    Jnc  Exit               ;no error, so we're all done
    Call P$DoError          ;let this guy handle the error
    Jmp  Short Exit         ;and then quit
    
DoScreen:
    Push AX                 ;this is a dummy argument, but POS(0) needs it
    Call B$FPOS             ;yes, see where the cursor is currently
    And  AH,00000111b       ;keep just the POS(0) MOD 8 portion
    Mov  AL,8               ;make an 8
    Sub  AL,AH              ;now AL holds the difference to the next Tab stop
    Dec  AL                 ;well, okay, now it does
    Cbw                     ;make a full word
    
    Push AX                 ;pass that on to SPACE$()
    Call B$SPAC             ;SPACE$ returns a descriptor address in AX
    Push AX                 ;pass that on to the PRINT routine
    Call B$PSSD             ;that'll do it

Exit:
    Ret                     ;return to caller

B$PCSD Endp
End
