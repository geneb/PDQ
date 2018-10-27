;********* POINT1.ASM - PDQ replacement for BASIC's POINT function (one parm)

;POINT1.ASM  Copyright (c) 1992  Thomas G. Hanlin III


.Model Medium

.Data

Extrn  P$GXPos1: Word         ; X coordinate
Extrn  P$GYPos1: Word         ; Y coordinate




.Code

B$PNT1   Proc

    Mov  BX,SP
    Mov  AX,[BX+4]          ;code
    Shr  AX,1               ;return X coord?
    Mov  AX,P$GXPos1        ;(assume so)
    Jnc  Done               ;  yep, got it
    Mov  AX,P$GYPos1        ;return Y coord

Done:
    Add Word Ptr SS:[BX],5  ;skip real math stuff (in caller)
    Ret  2                  ;return to caller

B$PNT1   EndP
End
