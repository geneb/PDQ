;********** _CPRINT.ASM - PDQ replacement for BASIC's print routines
;
;Copyright (c) 1989 Ethan Winer
;Modified to support color by Dave Cleary (thanks Dave!)

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
    Extrn P$Color:Byte              ;Current color attribute


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



B$PSSD Proc Uses SI, Work:Word    ;print string w/out CRLF, leave PrintHandle

    Mov  BX,Work          ;get the address for Work$
    Mov  CX,[BX]          ;put its length into CX
    Mov  DX,[BX+02]       ;and its address into DX
    Jcxz Exit             ;it's a null string, exit

    Mov  BX,P$PrintHandle ;get the current print handle
    Cmp  BX,1             ;are we printing to the screen?
    Jne  DoDOS            ;no, print through DOS

    Cld                   ;ensure that we work forward through the string
    Push BX               ;save the print handle
    Push CX               ;save the string length
    Push BP               ;save BP (some old BIOSes trash BP during Int 10h)
    
    Mov  AH,15            ;select "get current video mode" service
    Int  10h              ;the active page will be returned in BH
    Mov  SI,DX            ;SI now points to the string
    Mov  BL,P$Color       ;BL now contains the current attribute
    Mov  AH,0Eh           ;print using BIOS function 0Eh

PrintLoop:
    Lodsb                 ;load AL with the character
    Cmp  AL,8             ;is it a back space?
    Je   NoAttr           ;yes, so don't paint the attribute
    Cmp  AL,10            ;ditto for a line feed
    Je   NoAttr
    Cmp  AL,13            ;and for a carriage return
    Je   NoAttr

    Push AX               ;save AX and CX while we "paint" the attribute
    Push CX
    Mov  AX,920h          ;use function 9 to print a space but not advance
                          ;  the cursor, using the color attribute in BL
    Mov  CX,1             ;print one space
    Int  10h              ;do the interrupt
    Pop  CX               ;retrieve the remaining character count
    Pop  AX               ;and the service number in AH

NoAttr:
    Int  10h              ;print and advance the cursor using function 0Eh
    Loop PrintLoop        ;loop until entire string is done

    Pop  BP               ;restore BP
    Pop  CX               ;restore the original string length
    Mov  AX,CX            ;tell NoErr we printed everything
    Pop  BX               ;restore the print handle
    Jmp  Short NoErr      ;and skip over the code that prints to a file

DoDOS:
    Xor  AX,AX            ;assume there will be no errors
    Mov  P$PDQErr,AX      ;this is less code/faster than Mov P$PDQErr,0
    Mov  AH,40h           ;write to file/device service
    Int  21h              ;call DOS to do it
    Jnc  NoErr            ;no DOS error
    Call P$DoError        ;handle the error as needed
    Jmp  Short Exit       ;and skip ahead

NoErr:
    Add  P$TabTable[BX],AL    ;update the current print Tab column (MOD 256)
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
