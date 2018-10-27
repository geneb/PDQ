;***** PDQSPKR.ASM - initialize the speaker, turn it on and turn it off

;    Copyright 1990 (c) Crescent Software, Inc.
;    written by Paul Passarelli

.Model Medium,BASIC
.CODE

P$Speaker Proc

    Cmp  Byte Ptr CS:[P$SPKR_Init],0    ;see if we have already been here 
    Jnz  Init                           ;yes, leave it be for a smoother sound
    Dec  Byte Ptr CS:[P$SPKR_Init]      ;no, set the flag
    Mov  AL,10110110b                   ;select initialize Timer 2
    Out  43h,AL                         ;do it to it!

Init:
    Ret
    
    P$SPKR_Init DB 0
    
P$Speaker EndP



P$SPKR_ON Proc

    In   AL,61h         ;read timer port "B"
    Or   AL,00000011b   ;set the bits to turn the speaker on
    Out  61h,AL         ;turn it on
    Ret
    
P$SPKR_ON EndP



P$SPKR_OFF Proc

    In   AL,61h         ;read timer port "B"
    And  AL,11111100b   ;set the bits to turn the speaker off
    Out  61h,AL         ;turn it off
    Ret
    
P$SPKR_OFF EndP
End
