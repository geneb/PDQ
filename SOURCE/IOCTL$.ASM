;********* IOCTL$.ASM - P.D.Q. replacement for BASIC's B$FICT routine

;Copyright (c) 1991 Ethan Winer


.Model Medium, Basic
    Extrn P$Num2Handle:Proc ;this is in NUM2HNDL.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM
    Extrn P$MakeTemp:Proc   ;this is in MAKETEMP.ASM
    
.Code

B$FICT Proc Uses SI DI, FileNum:Word

    Local Buffer[255]:Byte  ;DOS will place the device's output string here

    Mov  BX,FileNum         ;get the BASIC file number
    Call P$Num2Handle       ;convert that to the equivalent DOS file handle
    Mov  AX,4402h           ;service 44h, subfunction 2
    Mov  CX,255             ;tell DOS to limit the string to 255 characters
    Lea  DX,Buffer          ;show DOS where to place the returned string

    Int  21h                ;DOS returns the length of the string in AX
    Jnc  Continue           ;if there was no error, simply exit
    Mov  AX,-1              ;create an "Illegal function call" error
    Call P$DoError          ;handle ON ERROR if necessary
    Xor  AX,AX              ;return a null string below

Continue:
    Mov  CX,AX              ;DOS returns the actual returned length in AX
    Call P$MakeTemp         ;grab CX bytes in pool, DI returns pointing there
    Mov  SI,DX              ;we'll copy the data from the buffer to the pool
    Rep  Movsb              ;copy the data into string space

Exit:
    Ret                     ;return to BASIC

B$FICT Endp
End
