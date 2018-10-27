;********** PRINT.ASM - PDQ replacement for BASIC's print routines
;
;Copyright (c) 1989 Ethan Winer
;
;----------------------------------------------------------------------
; 1/3/90    .001    Remove B$PEOS.  (rlh)
;----------------------------------------------------------------------
.Model Medium, Basic
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM
    Extrn P$DoError:Proc  ;this is in DOERROR.ASM

.Data
    Extrn P$PDQErr:Word             ;this is in ERRDATA.ASM
    Extrn P$PrintHandle: Word       ;this is in PHANDLE.ASM
                                    ;1 = screen, 4 = LPT1:, anything else
                                    ;  is a disk file or STDERR (#255)
    Extrn P$Descr:Word              ;this is in PRINTDAT.ASM, it points to
                                    ;  an empty CRLF (13, 10) to be printed
    Extrn P$TabTable:Byte           ;this is in FHANDLES.ASM
    
.Code

B$PESD Proc, Work:Word    ;print string with CRLF, reset PrintHandle
                          ;PESD = Print End-of-line String Descriptor
    Push Work             ;pass the address for Work$ on to B$PSSD
    Call Far Ptr B$PSSD   ;let B$PSSD print the string

    Mov  AX,Offset P$Descr;show B$PSSD where the CRLF descriptor is
    Push AX               ;pass it on to B$PSSD
    Call Far Ptr B$PSSD   ;let B$PSSD print the string
    
    Mov  BX,P$PrintHandle ;see which handle we just printed to
    Mov  P$TabTable[BX],0 ;an end-of-line PRINT resets the current Tab column

    Mov  P$PrintHandle,1  ;reset the print handle to the screen for next time
    Ret                   ;return to caller

B$PESD Endp



B$PSSD Proc, Work:Word    ;print string w/out CRLF, leave PrintHandle

    Mov  BX,Work          ;get the address for Work$
    Mov  CX,[BX]          ;put its length into CX
    Mov  DX,[BX+02]       ;and its address into DX

    Mov  BX,P$PrintHandle ;get the current print handle
    Cmp  BX,1             ;are we printing to the screen?
    Je   DoScreen         ;yes, leave P$PDQErr alone
    Xor  AX,AX            ;no, so assume there will be no errors
    Mov  P$PDQErr,AX      ;this is less code/faster than Mov P$PDQErr,0

DoScreen:
    Mov  AH,40h           ;write to file/device service
    Int  21h              ;call DOS to do it
    Jnc  NoErr            ;no DOS error
    Call P$DoError        ;handle the error as needed
    Jmp  Short Exit       ;and skip ahead

NoErr:
    Add  P$TabTable[BX],AL    ;update the current print Tab column counter
    Cmp  AX,CX                ;but did we write as many bytes as we wanted?
    Jnb  Exit                 ;yes, so we're all done
    Mov  Byte Ptr P$PDQErr,61 ;the disk must be full and there's no DOS error
                              ;  number for that, use BASIC's instead
Exit:
    Push Work             ;delete the string if necessary
    Call P$FreeTemp
    Ret                   ;return to caller

B$PSSD Endp
End
