;********** COMPAR43.ASM - 80386 PDQ replacement for BASIC's B$CPI4 routine

;Copyright (c) 1989 Ethan Winer

;This routine compares two long integer variables.
;See the comments in COMPARE4.ASM for an explanation of the Uses AX below.


.Model Medium, Basic
.Code
.386

;B$CPI4 compares two long integers, and returns the flags set appropriately.

B$CPI4 Proc Uses AX, X:DWord, Y:DWord

    Mov  EAX,X            ;get the first argument
    Cmp  EAX,Y            ;compare it with the second
    Ret                   ;return to BASIC

B$CPI4 Endp
End
