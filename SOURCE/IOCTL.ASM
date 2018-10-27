;********* IOCTL.ASM - P.D.Q. replacement for BASIC's B$SICT routine

;Copyright (c) 1991 Ethan Winer


.Model Medium, Basic
    Extrn P$FreeTemp:Proc   ;this is in FREETEMP.ASM
    Extrn P$Num2Handle:Proc ;this is in NUM2HNDL.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM

.Code

B$SICT Proc, FileNum:Word, Work:Word

    Mov  BX,Work            ;get the address for Work$ descriptor
    Mov  DX,[BX+02]         ;put SADD(Work$) into DX
    Mov  CX,[BX]            ;and put LEN(Work$) into CX

    Mov  BX,FileNum         ;get the BASIC file number
    Call P$Num2Handle       ;convert that to the equivalent DOS file handle
    Mov  AX,4403h           ;service 44h, subfunction 3

    Int  21h                ;DOS does it all while we stand by and watch
    Jnc  Exit               ;if there was no error, simply exit
    Mov  AX,-1              ;create an "Illegal function call" error
    Call P$DoError          ;and handle ON ERROR if necessary

Exit:
    Push Work               ;pass the incoming string address to FreeTemp
    Call P$FreeTemp         ;delete it if necessary

    Ret                     ;return to caller

B$SICT Endp
End
