;********* LOF.ASM - PDQ replacement for BASIC's B$FLOF routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$Num2Handle:Proc ;this is in NUM2HNDL.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Code

B$FLOF Proc Uses SI DI, FileNum:Word

    Mov  BX,FileNum       ;get the BASIC file number
    Call P$Num2Handle     ;translate it to a DOS handle

    Xor  CX,CX            ;set the file pointer 0 bytes from where it is now
    Mov  DX,CX            ;CX holds the high word, DX holds the low word
    
    Mov  AX,4201h         ;Move File Pointer service, relative to current LOC
                          ;(this asks DOS where we currently are in the file)
    Int  21h              ;call DOS
    Jc   ErrExit          ;oops

    Mov  DI,DX            ;save where we are now (DX:AX) in DI:SI
    Mov  SI,AX
    Mov  AX,4202h         ;ask DOS to seek to the end of the file
    Xor  CX,CX            ;this is done by requesting zero bytes with AL = 2
    Mov  DX,CX            ;(that is, seek to a location 0 bytes from the end)
    Int  21h              ;call DOS
    Jc   ErrExit          ;it's unlikely there'd be an error now, but ...

    Push DX               ;save the length now in DX and AX for a moment
    Push AX
    Mov  DX,SI            ;get the original seek position back again
    Mov  CX,DI
    Mov  AX,4200h         ;and reset the file to where it had been
    Int  21h              ;call DOS
    Jc   ErrExit
    Pop  AX               ;get AX and DX back again
    Pop  DX

Exit:
    Ret                   ;return to BASIC

ErrExit:
    Call P$DoError        ;handle the error as needed
    Xor  AX,AX            ;and return zero for the function output
    Cwd                   ;LOF is a long integer function
    Jmp  Short Exit

B$FLOF Endp
End
