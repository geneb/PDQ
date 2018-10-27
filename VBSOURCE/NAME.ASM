;********** NAME.ASM - PDQ replacement for BASIC's B$NAME routine

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


.Model Medium, Basic
    Extrn P$FixStr:Proc     ;this is in FIXSTR.ASM
    Extrn P$ZeroFile:Proc  ;this is in ZEROFILE.ASM
    Extrn P$DoError:Proc   ;this is in DOERROR.ASM

.Data
    Extrn P$PDQErr:Word    ;this is in ERRDATA.ASM

.Code

B$NAME Proc Uses DI ES, OldName:Word, NewName:Word

    Local Buffer1[80]:Byte ;copy the old file name here to add a CHR$(0)
    Local Buffer2[80]:Byte ;ditto for the new name

    Push OldName          ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  OldName,AX       ;

    Push NewName          ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  NewName,AX       ;

    Mov  AX,OldName       ;get the address for the existing file name
    Lea  DX,Buffer1       ;get the address for the start of the first buffer
    Call P$ZeroFile       ;this copies and adds a CHR$(0) to the end for DOS
    Mov  P$PDQErr,CX      ;assume no errors (and CX is conveniently zero)

    Push DX               ;save DX for the second use of P$ZeroFile
    Mov  AX,NewName       ;get the address for the new file name
    Lea  DI,Buffer2       ;get address for the start of the second buffer
    Mov  DX,DI            ;copy to DX where ZeroFile expects it
    Call P$ZeroFile       ;this adds a CHR$(0) to the end for DOS
    Pop  DX

    Mov  AH,56h           ;rename file service
    Int  21h              ;call DOS
    Jnc  Exit             ;no error, no problem!
    Call P$DoError        ;handle the error as needed

Exit:
    Ret                   ;return to caller

B$NAME Endp
End
