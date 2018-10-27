;********** COMPARE4.ASM - PDQ replacement for BASIC's B$CPI4 routine

;Copyright (c) 1989 Ethan Winer

;This routine compares two long integer variables.


.Model Medium, Basic
.Code

;B$CPI4 compares two long integers, and returns the flags set appropriately.

;It shouldn't be necessary to save AX (Uses AX below), except for a bug in
;QuickBASIC.  When using a statement such as IF X& > Y& AND A& < B& THEN, the
;intermediate result of the first comparison is held in AX.  That is, AX is
;set to either 0 or -1, depending on the truth of the first comparison.  The
;bug is that AX is not saved before the second comparison is performed, so we
;must save it in this compare routine.  Examining the code that BC generates
;for string comparisons shows that AX is indeed saved, so that routine does
;not need to explicitly save AX.

B$CPI4 Proc Uses AX, Hi1:Word, Lo1:Word, Hi2:Word, Lo2:Word

    Mov  AX,Hi1         ;get the high word of the first value
    Cmp  AX,Hi2         ;compare that to the high word of the second value
    Jne  Exit           ;they're different, and the flags are now correct

    Mov  AX,Lo1         ;get the low word of the first value
    Cmp  AX,Lo2         ;compare that to the low word of the second value
    Je   Exit           ;they're the same, and the flags are now correct

    Mov  AX,1           ;set AH = 0, AL = 1
    Ja   @F             ;Value1 is greater, generate a GT condition
    Xchg AH,AL          ;Value2 is greater, generate a LT condition
    
@@:
    Cmp  AL,AH          ;set the flags accordingly
    
Exit:
    Ret

B$CPI4 Endp
End
