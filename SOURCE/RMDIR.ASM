;********** RMDIR.ASM - PDQ replacement for BASIC's B$RDIR routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$ZeroFile:Proc ;this is in ZEROFILE.ASM
    Extrn P$DoError:Proc  ;this is in DOERROR.ASM

.Data
    Extrn P$PDQErr:Word   ;this is in ERRDATA.ASM

.Code

B$RDIR Proc, DirName:Word

    Local Buffer[80]:Byte ;copy the directory name here to add a CHR$(0)

    Mov  AX,DirName       ;get the address for the directory name
    Lea  DX,Buffer        ;get the address for the start of the buffer
    Call P$ZeroFile       ;this copies and adds a CHR$(0) to the end for DOS
    Mov  P$PDQErr,CX      ;assume no errors (and CX is conveniently zero)

    Mov  AH,3Ah           ;remove directory service
    Int  21h              ;call DOS
    Jnc  Exit             ;no error, exit
    Call P$DoError        ;handle the error as needed

Exit:
    Ret                   ;return to caller

B$RDIR Endp
End
