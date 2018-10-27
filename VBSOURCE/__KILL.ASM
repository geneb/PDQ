;********** _KILL.ASM - "stripped-down" version of KILL, no wild card support

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


.Model Medium, Basic
    Extrn P$FixStr:Proc   ;this is in FIXSTR.ASM
    Extrn P$ZeroFile:Proc ;this is in ZEROFILE.ASM
    Extrn P$DoError:Proc  ;this is in DOERROR.ASM

.Data
    Extrn P$PDQErr:Word   ;this is in ERRDATA.ASM

.Code

B$KILL Proc, FileName:Word

    Local Buffer[80]:Byte ;copy the file name here to add a CHR$(0)

    Push FileName         ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  FileName,AX      ;

    Mov  AX,FileName      ;get the address for the file name
    Lea  DX,Buffer        ;get the address for the start of the buffer
    Call P$ZeroFile       ;this copies and adds a CHR$(0) to the end for DOS
    Mov  P$PDQErr,CX      ;assume no errors (CX is known to be zero)

    Mov  AH,41h           ;delete file service
    Int  21h              ;call DOS
    Jnc  Exit             ;no error, exit gracefully
    Call P$DoError        ;handle the error as needed

Exit:
    Ret                   ;return to caller

B$KILL Endp
End
