;********** BLOAD.ASM - PDQ replacement for BASIC's B$BLOD routine

;Copyright (c) 1989 Crescent Software


.Model Medium, Basic
    Extrn P$ZeroFile:Proc ;this is in ZEROFILE.ASM
    Extrn P$DoError:Proc  ;this is in DOERROR.ASM

.Data
    Extrn B$Seg:Word      ;this is in PDQDATA.ASM
    Extrn P$PDQErr:Word   ;this is in ERRDATA.ASM

.Code

B$BLOD Proc, File:Word, Adr:Word, Dummy:Word

    Local Buffer[80]:Byte ;copy the file name here to add a CHR$(0)

    Mov  AX,File          ;get the address for the file name
    Lea  DX,Buffer        ;get the address for the start of the buffer
    Call P$ZeroFile       ;this copies and adds a CHR$(0) to the end for DOS
    Mov  P$PDQErr,CX      ;assume no errors (and CX is conveniently zero)

    Mov  AX,3D00h         ;open file service, for read mode only
    Int  21h              ;call DOS
    Jc   ErrorExit        ;if the carry flag is set, there was an error

    Mov  BX,AX            ;save handle in BX
    Mov  AX,4200h         ;move file pointer relative to start of file
    Xor  CX,CX            ;file offset = 0
    Mov  DX,7             ;  plus 7 bytes to skip BASIC's BLOAD header
    Int  21h              ;do it
    Jc   ErrorExit        ;an error here is unlikely, but ...

    Mov  DX,Adr           ;get the address to load to
    Push DS               ;save DS before we change it
    Mov  DS,B$Seg         ;and the segment from BASIC's DEF SEG area
    Mov  CX,0FFFFh        ;request full 65535 bytes to be read
    Mov  AH,3Fh           ;read file service
    Int  21h              ;do it
    Pop  DS               ;get DS back again
    Jc   ErrorExit        ;as usual

    Mov  AH,3Eh           ;close file service
    Int  21h              ;do it
    Jc   ErrorExit

Exit:
    Ret                   ;return to caller

ErrorExit:
    Call P$DoError        ;handle the error as needed
    Jmp  Short Exit       ;and get out

B$BLOD Endp
End
