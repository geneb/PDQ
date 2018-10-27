;********** LPRINT.ASM - PDQ replacement for BASIC's B$LPRT routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    Extrn P$PrintHandle:Word    ;this is in PHANDLE.ASM

.Code

B$LPRT Proc                 ;specify the next print to go the LPT1:

    Mov  P$PrintHandle, 4   ;set the handle for the next print to LPT1:
    Ret                     ;return to caller

B$LPRT Endp
End
