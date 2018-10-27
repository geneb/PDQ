;********** GETSEG.ASM - retrieves the current DEF SEG setting
 
;Copyright (c) 1990 Ethan Winer
 
;Declare: DECLARE FUNCTION GetSeg%()
;Usage:   CurrentSeg = GetSeg%
 
 
.Model Medium, Basic
.Data
    Extrn B$Seg:Word
 
.Code
 
GetSeg Proc
 
    Mov  AX,B$Seg           ;load the value currently stored in B$Seg
    Ret                     ;return to BASIC with the function output in AX
 
GetSeg Endp
End
