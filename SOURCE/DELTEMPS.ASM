;********** DELTEMPS.ASM - deletes all temporary strings

;Copyright (c) 1990 Ethan Winer


;Note: RESUME.ASM counts on this code exiting with CX set to zero.

.Model Medium, Basic
    Extrn B$STDL:Proc       ;this is in STRDELET.ASM
    
.Data
    Extrn P$TempDesc: Word  ;this is in TEMPDESC.ASM, and it holds all of
                            ;  the temporary descriptors used in P.D.Q.
.Code

P$DelAllTemps Proc

    Mov  CX,20                  ;we're going to free 20 temporary strings
    Mov  DX,Offset P$TempDesc   ;show B$STDL where the first one is located

DelLoop:
    Push DX                 ;show B$STDL where the strings are
    Call B$STDL             ;delete each one by one
    Add  DX,4               ;point to the next possible temporary string
    Loop DelLoop

    Ret                     ;return to caller

P$DelAllTemps Endp
End
