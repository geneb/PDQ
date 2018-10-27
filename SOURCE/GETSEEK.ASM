;********** GETSEEK.ASM - PDQ replacement for BASIC's B$GET4 routine

;Copyright (c) 1989 Crescent Software


.Model Medium, Basic
    Extrn B$SSEK:Proc     ;this is in SEEK.ASM
    Extrn B$Get3:Proc     ;this is in GET.ASM

.Code

B$GET4 Proc Uses DS, FileNum:Word, OffsetHi:Word, OffsetLo:Word, Variable:DWord, NumBytes:Word

    Push FileNum          ;pass the BASIC file number on to B$SSEK
    Push OffsetHi         ;and the long integer offset to seek to
    Push OffsetLo
    Call B$SSEK           ;seek to the specified location in the file

    Push FileNum          ;pass the file name on to B$FGET3
    Lds  AX,Variable      ;get the segmented variable address
    Push DS               ;and pass that on too
    Push AX
    Push NumBytes         ;and send the length on too
    Call B$GET3           ;B$GET3 will do the actual GET
    Ret                   ;return to BASIC

B$GET4 Endp
End
