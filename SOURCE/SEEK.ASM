;********** SEEK.ASM - PDQ replacement for BASIC's B$SSEK routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$Num2Handle:Proc   ;this is in NUM2HNDL.ASM
    Extrn P$DoError:Proc      ;this is in DOERROR.ASM
    Extrn B$MUI4:Proc         ;this is in MULTLONG.ASM (or MULTLNG3.ASM)

.Data
    Extrn P$RecordTbl:Word    ;this is in FHANDLES.ASM

.Code

B$SSEK Proc, FileNum:Word, LocHi:Word, LocLo:Word

    Mov  DX,LocLo         ;put the low portion into DX
    Mov  CX,LocHi         ;and put the high portion into CX
    Sub  DX,1             ;adjust BASIC's 1-based method to DOS' 0-based
    Sbb  CX,0

    Mov  BX,FileNum         ;get the BASIC file number
    Push BX                 ;save it for a moment
    Dec  BX                 ;adjust to zero-based
    Shl  BX,1               ;these are words, not bytes
    Mov  AX,P$RecordTbl[BX] ;get the record length if appropriate (if RANDOM)
    Pop  BX                 ;get the BASIC file number back again
    Call P$Num2Handle       ;translate it to a DOS handle

    Or   AX,AX            ;is it in fact a random access file?
    Jz   NotRandom        ;no, skip ahead
    Push BX               ;yes, save the DOS handle because B$MUI4 trashes BX
    
    Push CX               ;send the record number to the existing B$MUI4
    Push DX               ;  long integer multiply routine
    Cwd                   ;now convert to the record length to a double word
    Push DX               ;adn pass that on to B$MUI4 as well
    Push AX
    Call B$MUI4           ;B$MUI4 returns its answer in DX:AX

    Pop  BX               ;retrieve the DOS handle
    Mov  CX,DX            ;swap the bytes around to the method DOS requires
    Mov  DX,AX

NotRandom:
    Mov  AX,4200h         ;Move File Pointer service, relative to top of file
    Int  21h              ;call DOS
    Jnc  Exit             ;no errors, continue
    Call P$DoError        ;handle the error as needed

Exit:
    Ret                   ;return to BASIC

B$SSEK Endp
End
