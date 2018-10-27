;********** PUTSEEK.ASM - PDQ replacement for BASIC's B$PUT4 routine

;Copyright (c) 1989 Crescent Software


.Model Medium, Basic
    Extrn B$SSEK:Proc     ;this is in SEEK.ASM
    Extrn B$PUT3:Proc     ;this is in PUT.ASM

.Code

B$PUT4 Proc Uses DS, FileNum:Word, OffsetHi:Word, OffsetLo:Word, Variable:DWord, NumBytes:Word

    Push FileNum          ;pass the BASIC file number on to B$SSEK
    Push OffsetHi         ;and the long integer offset to seek to
    Push OffsetLo
    Call B$SSEK           ;seek to the specified location in the file

    Push FileNum          ;pass the file name on to B$FPUT3
    Lds  AX,Variable      ;get the segmented variable address
    Push DS               ;and pass that on too
    Push AX
    Push NumBytes         ;and send the length on too
    Call B$PUT3           ;B$PUT3 will do the actual PUT
    Ret                   ;return to BASIC

B$PUT4 Endp
End
