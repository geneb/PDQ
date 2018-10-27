;********** P$DELAY.ASM - a millisecond timer for P.D.Q.

;Copyright (c) 1990 Crescent Software
;Written by Paul Passarelli

;    Syntax:  Call P$Delay (BYVAL MilliSeconds)

.Model Medium, BASIC
    Public P$Fudge
    
.DATA
    P$Fudge     DB  0           ;flag, if P$Delay has been used before
    Fudge_Addr  DW  Offset Fudge_Fact
    Fudge_Fact  DD  54
    FiftyFour   DW  54
    
.CODE

P$Delay Proc, MilliSeconds:Word

    Xor  AX,AX          ;gimme a zero

    Cmp  [P$Fudge],AL   ;look at memory to see if here before
    Jne  Factor_Known   ;yes, skip the measurement part
    Dec  [P$Fudge]      ;show we are doing this once

    Push DS             ;save DS

    Cwd                 ;clear the hi-word of the 32 bit number
    Mov  DS,AX          ;we will skip the "ES:" override by using DS

    Mov  BX,46Ch        ;lo-mem address in BX of the timer
    Mov  CL,[BX]        ;get the current timer count
SyncLoop:
    Cmp  CL,[BX]
    Je   SyncLoop       ;now wait for the next timer tick
    Inc  CL             ;this is the new timer value

Even
TimeLoop:
    Add  AX,1           ;increment our local long integer
    Adc  DX,0           ;all of it if necessary.
    Cmp  CL,[BX]        ;has the timer turned over yet?
    Je   TimeLoop       ;no, keep incrementing the variables

    Pop  DS             ;we can bring back DS now.

    Div  FiftyFour      ;÷ 54.923434 milliseconds per timer tick

    Mov  BX,[Fudge_Addr]
    Mov  [BX],AX        ;Quotient
    Mov  [BX+2],DX      ;Remainder

    Jmp  Short Exit
    
Factor_Known:

    Mov  CX,AX          ;zero out CX as well
    Or   AX,MilliSeconds;(ms)
    Jz   Exit           ;if they want zero, give 'em zero!
    Jns  Abs_AX         ;if it's positive we're fine
    Neg  AX             ;take its absolute value
    Mov  MilliSeconds,AX
Abs_AX:

    Mov  BX,[Fudge_Addr]

    Mov  AX,[BX+2]      ;get the remainder in cycles/ms
    Mul  MilliSeconds   ;multiply by the number of iterations ms
    Push DX             ;save cycles
    Push AX             ;save it

    Mov  AX,[BX]
    Mul  MilliSeconds
    Pop  BX
    Add  AX,BX
    Pop  BX
    Adc  DX,BX

Even
DelayLoop:
    Cmp  CL,[BX]        ;dummy compare, this makes the loop similar to above
    Sub  AX,1           ;decrement HiWord:LoWord
    Sbb  DX,0
    Jns  DelayLoop

Exit:
    Ret
    
P$Delay EndP
End
