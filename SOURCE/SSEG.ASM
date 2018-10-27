;********** SSEG.ASM - P.D.Q. replacement for BASIC 7's SSEG function

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
.Code

B$SSEG Proc

    Mov  AX,DS              ;all P.D.Q. strings are near, so return DS
    Retf 2                  ;return to BASIC discarding the dummy argument

B$SSEG Endp
End
