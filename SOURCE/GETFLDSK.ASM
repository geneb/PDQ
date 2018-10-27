;********** GETFLDSK.ASM - PDQ replacement for BASIC's B$GET2 routine

;Copyright (c) 1991 Crescent Software


.Model Medium, Basic
    Extrn B$GET4:Proc       ;this is in GETSEEK.ASM

.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Extrn P$FldDesc:Word    ;this is in FIELD2.ASM
    
.Code

B$GET2 Proc, FileNum:Word, RecordHi:Word, RecordLo:Word

    Mov  AX,FileNum         ;get the BASIC file number
    Push AX                 ;pass it on to B$GET4

    Push RecordHi           ;pass the long integer record number to GET from
    Push RecordLo
    
    Dec  AX                 ;convert the file number to zero-based
    Shl  AX,1               ;times four to access a table of descriptors
    Shl  AX,1
    Add  AX,Offset P$FldDesc    ;now AX points to P$FldDesc(FileNum)
    Push DS                     ;pass the segmented descriptor address
    Push AX
    
    Sub  AX,AX              ;pass zero for the number of bytes
    Push AX                 ;  to show this is a conventional string
    Call B$GET4             ;let BASIC's "GET #n, RecordNum, VarName" do it
    Ret                     ;return to BASIC

B$GET2 Endp
End
