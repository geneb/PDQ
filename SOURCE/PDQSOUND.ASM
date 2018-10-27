;********** PDQSOUND.ASM - small code replacement for BASIC's SOUND statement

;Copyright (c) 1989 Ethan Winer


;Syntax: CALL PDQSound(Frequency%, Duration%)
;
;Where Frequency% is the frequency in Hertz (cycles per second) and Duration%
;is the number of 1/18ths second to sustain the tone.  These parameters are
;identical to those for the SOUND statement in the BASIC reference manual,
;and the range of values for the pitch is the same: 37 to 32767 Hz.  If the
;duration is given as a negative value, then the sound will remain on until
;it is called again with a positive Duration.  This lets you create smoother
;glissandos and other effects, by using negative values except for the last
;time.  Otherwise, turning the speaker on and off between each call creates a
;slight clicking sound.


.Model Medium, Basic
    Extrn Pause:Proc      ;this is in PAUSE.ASM
    
.Data
    BeenHere DB 0         ;this remembers if we already initialized Timer 2
    
.Code

PDQSound Proc, Frequency:Word, Duration:Word

    Cmp  BeenHere,0       ;have we already been here?
    Jnz  DoIt             ;yes, so leave it as is for a smoother sound
    Mov  BeenHere,-1      ;no, set the flag

    Mov  AL,10110110b     ;initialize Timer 2
    Out  43h,AL

DoIt:
    Mov  DX,12h           ;load DX:AX with 1,190,000 to convert
    Mov  AX,2870h         ;  the incoming frequency to period (1/f)
    Mov  BX,Frequency     ;get the address for Frequency%
    Mov  BX,[BX]          ;put Frequency% into BX
    Cmp  BX,37            ;is it less than 37 Hz.?
    Jb   Exit             ;yes, avoid a "Divide by zero" error
    Div  BX               ;now AX holds the correct timer interval period

    Out  42h,AL           ;send the interval information to Timer 2
    Mov  AL,AH            ;get second byte (a word must be sent as two bytes)
    Jmp  Short $+2        ;tiny delay allows time for the hardware to settle
    Out  42h,AL           ;send it

    In   AL,61h           ;read timer port "B"
    Or   AL,00000011b     ;set the bits to turn the speaker on
    Jmp  Short $+2        ;teensy delay
    Out  61h,AL           ;turn it on

    Push Duration         ;show Pause where the address for Duration% is
    Call Pause            ;delay for Duration% clock ticks

    Mov  BX,Duration      ;get the address for Duration
    Add  CX,[BX]          ;(we know CX is zero after calling Pause)
    Js   Exit             ;Duration was negative, leave the speaker turned on

    In   AL,61h           ;no, read timer port "B"
    And  AL,11111100b     ;set the bits to turn the speaker off
    Jmp  Short $+2        ;teensy delay
    Out  61h,AL           ;turn it off

Exit:
    Ret                   ;return to BASIC

PDQSound Endp
End
