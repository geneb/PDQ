;********* ERROR.ASM - PDQ replacement for BASIC's B$SERR routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$DoError:Proc  ;this is in DOERROR.ASM
    
.Data
    Extrn P$PDQErr: Word  ;this is in ERRDATA.ASM

.Code

B$SERR Proc, ErrValue:Word

    Mov  AL,Byte Ptr ErrValue   ;get the error value
    Cmp  AL,5                   ;is it Error 5?
    Jne  Try4             ;no, but see if it's Error 4
    Mov  AL,-1            ;yes, convert 5 to -1 (Illegal function call)

Try4:
    Cmp  AL,4             ;is it Error 4?
    Jne  NormalErr        ;no, skip ahead
    Mov  AL,-2            ;yes, substitute a -2 (Out of data)
    
NormalErr:
    Cbw                   ;convert what we have to a full word
    Mov  P$PDQErr,AX      ;and stick it where ERR can find it
    Call P$DoError        ;if ON ERROR is on effect this'll handle it
    Ret                   ;otherwise return to caller

B$SERR Endp
End
