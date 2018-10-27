;********** GETFLD.ASM - PDQ replacement for BASIC's B$GET1 routine

;Copyright (c) 1991 Crescent Software


.Model Medium, Basic
    Extrn B$GET3:Proc       ;this is in GET.ASM

.Data
    Extrn P$FldDesc:Word    ;this is in FIELD2.ASM
    
.Code

B$GET1 Proc, FileNum:Word

    Mov  AX,FileNum         ;get the BASIC file number
    Push AX                 ;pass it on to B$PUT3
    
    Dec  AX                 ;convert the file number to zero-based
    Shl  AX,1               ;times four to access a table of descriptors
    Shl  AX,1
    Add  AX,Offset P$FldDesc    ;now AX points to P$FldDesc(FileNum)
    Push DS                     ;pass the segmented descriptor address
    Push AX
    
    Sub  AX,AX              ;pass zero for the number of bytes
    Push AX                 ;  to show this is a conventional string
    Call B$GET3             ;let BASIC's "GET #n, , VarName" handle it
    Ret                     ;return to BASIC

B$GET1 Endp
End
