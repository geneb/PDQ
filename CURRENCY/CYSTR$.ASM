;*********** CYSTR$.ASM

;Copyright (c) 1991 Ethan Winer

;Because of the use of floating point math, assemble this file with /e.

.8087
.Model Medium, Basic

    Extrn B$STR8:Proc               ;this is in B$STR8.ASM

.Data
    Extrn P$10000:DWord             ;this is in CYDATA.ASM

.Code

B$STCY Proc Value:QWord

    Fild QWord Ptr Value            ;load the Currency number to the FP stack
    Fdiv DWord Ptr P$10000          ;adjust to .0001-based
    Fstp QWord Ptr Value            ;save it back out as a double precision
    Lea  BX,Value                   ;pass the result on to B$STR8
    Push [BX+06]
    Push [BX+04]
    Push [BX+02]
    Push [BX]
    Call B$STR8                     ;let Rob do the hard stuff
    Ret                             ;return to BASIC with AX from B$STR8
                                    ;  holding the result descriptor address
B$STCY Endp
End
