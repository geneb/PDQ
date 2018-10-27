;********** PAUSE.ASM - pauses for a specified number of timer ticks

;Copyright (c) 1989 Ethan Winer


;Syntax - CALL Pause(Ticks)

;returns when Ticks% 18ths of a second have passed

;NOTE: this routine is accurate to +0 / -.056 second


.Model Medium, Basic
.Code

Pause Proc, Ticks:Word

    Mov  BX,Ticks         ;get address for Ticks%
    Mov  CX,[BX]          ;put it in CX
    Or   CX,CX            ;see if it's either zero (a mistake) or negative
    Jz   Exit             ;zero is a mistake, avoid a LONG delay
    Jns  DoIt             ;not negative, so continue
    Neg  CX               ;we were called from SOUND, convert to positive

DoIt:
    Mov  BX,46Ch          ;make this number once to save a byte below
    Xor  AX,AX            ;look at the low system timer byte in low memory
    Mov  ES,AX            ;through ES

Outer:
    Mov  AL,ES:[BX]       ;get the current setting

Inner:
    Cmp  AL,ES:[BX]       ;has it changed?
    Je   Inner            ;no, keep checking
    Loop Outer            ;yes, loop until we've exhausted Ticks

Exit:
    Ret                   ;return to BASIC

Pause Endp
End
