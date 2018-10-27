;********* CLOSE.ASM - SMALLDOS version of CLOSE, needs exactly 1 file number

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$Num2Handle: Proc  ;this is in NUM2HNDL.ASM
    Extrn P$DoError: Proc     ;this is in DOERROR.ASM

.Data
    Extrn P$HandleTbl:Word    ;this is in FHANDLES.ASM

.Code

B$CLOS Proc, FileNum:Word, NumArgs:Word

    Mov  BX,FileNum       ;get the incoming BASIC file number
    Call P$Num2Handle     ;translate to a DOS handle, returns -1 if invalid

    Mov  AH,3Eh           ;close file service
    Int  21h              ;call DOS to actually do it
    Jnc  Done             ;no error, skip ahead and clear the handle entry
    Call P$DoError        ;handle the error as needed
    Jmp  Short Exit       ;and get out

Done:
    Mov  BX,FileNum       ;get the file number again
    Dec  BX               ;adjust 1-15 to 0-14 for indexing the handle table
    Shl  BX,1             ;convert bytes to words
    Mov  Word Ptr P$HandleTbl[BX],0  ;show this handle being no longer in use

Exit:
    Ret                   ;return to BASIC

B$CLOS Endp
End
