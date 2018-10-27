;********** BSAVE.ASM - PDQ replacement for BASIC's B$BSAV routine

;Copyright (c) 1989 Crescent Software


.Model Medium, Basic
    Extrn P$ZeroFile:Proc ;this is in ZEROFILE.ASM
    Extrn P$DoError:Proc  ;this is in DOERROR.ASM

.Data
    Extrn  P$PDQErr:Word  ;this is in ERRDATA.ASM
    Extrn  B$Seg:Word     ;this is in PDQDATA.ASM
    Header DB 0FDh        ;simulate BASIC's BSAVE header
           DW 0, 0, 0     ;segment, address, length

.Code

B$BSAV Proc Uses DI, File:Word, Adr:Word, NumBytes:Word

    Local Buffer[80]:Byte ;copy the file name here to add a CHR$(0)

    Mov  AX,File          ;get the address for the file name
    Lea  DX,Buffer        ;get the address for the start of the buffer
    Call P$ZeroFile       ;this copies and adds a CHR$(0) to the end for DOS
    Mov  P$PDQErr,CX      ;assume no errors (and CX is conveniently zero)

    Mov  AH,3Ch           ;create/truncate file
;   Xor  CL,CL            ;create a normal archive file (CX is already zero)
    Int  21h              ;do it

    Mov  BX,0             ;clear BX as a "Handle" flag for later
    Jc   ErrorExit        ;if Carry is set, there was an error

    Mov  BX,AX            ;save the file handle in BX for DOS services below
    Mov  DI,Offset Header ;point DI to the header data area
    Mov  DX,DI            ;put it into DX too for writing the header below
    Inc  DI               ;bump it past the FDh BSAVE ID byte
    Mov  AX,B$Seg         ;get the segment from which to save
    Stosw                 ;and put it into the header
    Mov  AX,Adr           ;same for the address
    Stosw
    Mov  AX,NumBytes      ;now get NumBytes directly from the stack
    Stosw                 ;and finally store that into the header as well

    Push AX               ;save the length for a moment
    Mov  CX,7             ;first write the seven header bytes
    Mov  AH,40h           ;DOS Write File service
    Int  21h              ;write the header
    Pop  CX               ;get the actual length back again
    Jc   ErrorExit        ;if carry, then something went wrong

    Push DS               ;save DS before we change it
    Mov  DS,B$Seg         ;point DS to the current DEF SEG segment
    Mov  DX,Adr           ;point DX to the specified offset
    Mov  AH,40h           ;write file service
    Int  21h              ;do the BSAVE
    Pop  DS               ;get DS back again
    Jc   ErrorExit        ;as usual
    
    Cmp  AX,CX            ;but did we write the full number of bytes?
    Jnb  Exit                   ;yes, skip ahead
    Mov  Byte Ptr P$PDQErr,61   ;no, make a "Disk full" error

Exit:
    Or   BX,BX            ;did we open the file successfully earlier?
    Jz   Done             ;if not, then don't try to close handle zero!
    Mov  AH,3Eh           ;otherwise, specify the close file service
    Int  21h              ;and do it

Done:
    Ret                   ;return to caller

ErrorExit:
    Call P$DoError        ;handle the error as needed
    Jmp  Short Exit       ;and get out while the gettin's good

B$BSAV Endp
End
