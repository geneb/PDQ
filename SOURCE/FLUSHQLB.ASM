;********* FLUSHQLB.ASM - satisfies calls to Flush when in the QB environment

;Copyright (c) 1990 Ethan Winer

;This is an empty "stub" file for use in PDQ.QLB only.  The corresponding
;object module is added to the PDQ.QLB Quick Library automatically by the
;QUICKLIB.BAT file.


.Model Medium, Basic
.Code

_Flush Proc                 ;the underscore is for CDECL compatibility

    Ret                     ;return to BASIC

_Flush Endp
End
