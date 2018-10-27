;********** ONERROR.ASM - PDQ replacement for BC's B$OEGA routine

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
.Data?
    Extrn P$OnErrStack:Word ;these are in ONERRDAT.ASM
    Extrn P$OnErrBP:Word

.Data
    Extrn P$ErrAdr:Word     ;these are in ONERRDAT.ASM
    Extrn P$ErrSeg:Word
    
.Code

B$OEGA Proc ;ErrorSeg:Word, ErrorAdr:Word - so you can see what's coming in

    Pop  AX                 ;pop the address for this procedure to return to
    Pop  DX                 ;and the segment too
    Pop  P$ErrAdr           ;pop the address to go to if an error occurs
    Pop  P$ErrSeg           ;and that segment as well
    Mov  P$OnErrStack,SP    ;this is the caller's stack pointer
    Mov  P$OnErrBP,BP       ;and the main-level value for BP
    Push DX                 ;now restore the caller's segment
    Push AX                 ;and the address
    Ret                     ;return to BASIC with the parameters removed

B$OEGA Endp
End
