;********** EOF.ASM - PDQ replacement for BASIC's B$FEOF routine

;written by John Conrad
;Copyright (c) 1989 Crescent Software


.Model Medium, Basic
    Extrn P$Num2Handle:Proc  ;this is in NUM2HNDL.ASM
    Extrn P$DoError:Proc     ;this is in DOERROR.ASM

.Data?
    ItsyByte DB 1 Dup (?)    ;we'll do a test read here

.Code

B$FEOF Proc, FileNum:Word

    Mov  BX,FileNum          ;get the file number
    Call P$Num2Handle        ;translate it to a DOS handle

    Mov  DX,Offset ItsyByte  ;show DOS where to stick it
    Mov  AH,3FH              ;ask DOS to
    Mov  CX,1                ;read one byte
    Int  21h                 ;call DOS
    Jc   ErrExit             ;probably a bad file handle

    Mov  DX,-1               ;assume EOF (-1 = TRUE)
    Or   AX,AX               ;did we get a byte of data?
    Jz   Exit                ;if AX = 0, then we didn't
    Cmp  ItsyByte,26         ;we got a byte but is it a CHR$(26) EOF mark?
    Je   Exit                ;yes, so that's the end of the file

    Mov  CX,DX               ;not the end, seek back a byte with CX:DX = -1
    Mov  AX,4201h            ;ask DOS to move the pointer back one byte
    Int  21h
    Xor  DX,DX               ;put zero in DX (EOF = FALSE)
    Jmp  Short Exit          ;and say goodbye

ErrExit:
    Call P$DoError           ;handle the error as needed
    Mov  DX,-1               ;on error, return EOF = TRUE

Exit:
    Mov  AX,DX               ;put the return value in AX
    Ret                      ;return to BASIC

B$FEOF Endp
End
