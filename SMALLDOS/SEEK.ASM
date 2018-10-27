;********** SEEK.ASM - PDQ SMALLDOS replacement for BASIC's B$SSEK routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$Num2Handle:Proc   ;this is in NUM2HNDL.ASM
    Extrn P$DoError:Proc      ;this is in DOERROR.ASM

.Code

B$SSEK Proc, FileNum:Word, LocHi:Word, LocLo:Word

    Mov  BX,FileNum       ;get the file number
    Call P$Num2Handle     ;translate it to a DOS handle

    Mov  DX,LocLo         ;put the low portion into DX
    Mov  CX,LocHi         ;and put the high portion into CX
    Sub  DX,1             ;adjust BASIC's 1-based method to DOS' 0-based
    Sbb  CX,0                                

    Mov  AX,4200h         ;specify Move File Pointer service, relative to
                          ;  the start of the file
    Int  21h              ;call DOS
    Jnc  Exit             ;no errors, continue
    Call P$DoError        ;handle the error as needed

Exit:
    Ret                   ;return to BASIC

B$SSEK Endp
End
