;********** P$SOUND.ASM - make a sound for (n) milliseconds

;Copyright (c) 1990 Crescent Software
;Written by Paul Passarelli

;       Syntax: Call P$Sound(BYVAL Frequency, BYVAL MilliSeconds)
;               assumes Timer 2 has been previously initialized via P$Speaker

.Model Medium, BASIC
    Extrn P$Delay : Proc
    Extrn P$SPKR_ON : Proc
    Extrn P$SPKR_OFF : Proc

.CODE

P$Sound Proc, Frequency:Word, MilliSeconds:Word

    Cmp  Frequency,37   ;is it less than 37 Hz.?
    Jb   _Silent        ;yes, avoid a "Divide by zero" error

    Mov  DX,12h         ;put the clock frequency in DX:AX
    Mov  AX,331Ah       ; 1,192,730 Hz
    
    Div  Frequency      ;now AX holds the correct timer interval period

    Out  42h,AL         ;send the interval information to Timer 2
    Mov  AL,AH          ;get second byte (a word must be sent as two bytes)
    Out  42h,AL         ;send it

    Call P$SPKR_ON

_Silent:
    Push MilliSeconds   ;so P$Delay knows how long to wait
    Call P$Delay        ;delay for ÷ MilliSeconds%

    Add  CX,MilliSeconds;(we know CX is zero after calling Pause)
    Js   Exit           ;Duration was negative, leave the speaker turned on

    Call P$SPKR_OFF

Exit:
    Ret

P$Sound EndP
END
