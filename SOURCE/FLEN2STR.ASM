;********** FLEN2STR.ASM - PDQ replacement for BASIC's B$LDFS routine

;Copyright (c) 1989 Ethan Winer

;This routine makes a copy of a fixed-length string (or the fixed-length
;portion of a TYPE variable) in "near" memory.


.Model Medium, Basic
    Extrn P$MakeTemp:Proc ;this is in MAKETEMP.ASM
    
.Code

B$LDFS Proc Uses SI DI DS, FLenStr:DWord, NumBytes:Word

    Mov  CX,NumBytes      ;get the length of the fixed-length string
    Call P$MakeTemp       ;claim space in the string pool
    Lds  SI,FLenStr       ;get the segmented address for the incoming string
    Rep  Movsb            ;make a copy of the fixed-length new string there
    Mov  AX,BX            ;show BASIC where the output descriptor is
    Ret                   ;return to caller

B$LDFS Endp
End
