;********** GET.ASM - PDQ replacement for BASIC's B$GET3 routine

;Copyright (c) 1989 Crescent Software


.Model Medium, Basic
    Extrn P$Num2Handle:Proc   ;this is in NUM2HNDL.ASM
    Extrn P$DoError:Proc      ;this is in DOERROR.ASM

.Data
    Extrn P$PDQErr:Word       ;this is in ERRDATA.ASM

.Code

B$GET3 Proc, FileNum:Word, Variable:DWord, NumBytes:Word

    Push DS               ;save DS before we change it 
    Lds  BX,Variable      ;get the variable's address
    Mov  CX,NumBytes      ;and the number of bytes to load
    Or   CX,CX            ;is the caller asking for zero bytes?
    Jnz  ReadIt           ;no, use the number of bytes that was passed
    Mov  CX,[BX]          ;yes, so it's going into a string - get the length
    Mov  BX,[BX+02]       ;and the address of its first character

ReadIt:
    Mov  DX,BX            ;transfer the load address to DX
    Mov  BX,FileNum       ;put the file number into BX
    Call P$Num2Handle     ;convert it to a BASIC handle number

    Mov  AH,3Fh           ;read file service
    Int  21h              ;do it
    Pop  DS               ;restore DS for addressability to P$PDQErr
    Jnc  NoError          ;no error, but see if we got all they asked for
    Call P$DoError        ;handle the error as needed
    Jmp  Short Exit       ;and exit

NoError:
    Cmp  CX,AX            ;did we read the full number of bytes?
    Je   Exit                   ;yes, so we're all done
    Mov  Byte Ptr P$PDQErr,62   ;no, set the "Input past end" error

Exit:
    Ret                   ;return to caller

B$GET3 Endp
End
