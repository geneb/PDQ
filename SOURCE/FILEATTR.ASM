;********* FILEATTR.ASM - PDQ replacement for BASIC's B$FATR routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$Num2Handle:Proc   ;this is in NUM2HNDL.ASM
    
.Code

B$FATR Proc, FileNum:Word, Action:Word

    Mov  BX,FileNum       ;get the file number, ignore the action code
    Call P$Num2Handle     ;translate it to a DOS handle
    Mov  AX,BX            ;put the handle into AX for the function output
    Cwd                   ;convert it to a long integer like BASIC expects
    Ret                   ;return to BASIC

B$FATR Endp
End
