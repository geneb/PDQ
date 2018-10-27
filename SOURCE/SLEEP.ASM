;********** SLEEP.ASM - PDQ replacement for BASIC's B$SLEP routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn Pause:Proc      ;this is in PAUSE.ASM
    
.Data
    Ticks DW 1            ;this lets us pause in 1/18th second at a time

.Code

B$SLEP Proc, Dummy:Word, Seconds:Word

    Mov  AX,Seconds       ;get the number of seconds to wait
    Mov  CX,18            ;multiply times 18 to get the number of timer ticks
    Mul  CX               ;do the multiplication
    Mov  CX,AX            ;put it into CX for the Loop below

Clear:
    Xor  DX,DX            ;clear out the keyboard buffer in low memory
    Mov  ES,DX
    Mov  BX,41Ah          ;set BX to address the buffer pointer
    Mov  DL,1Eh           ;establish the buffer head at 41Eh (4 is implied)

    Cli                   ;disable interrupts until we're all done
    Mov  ES:[BX],DX       ;set the buffer head
    Mov  ES:[BX+02],DX    ;and clear the buffer tail to the same address
    Sti                   ;interrupts are now okay
    
Do:
    Cmp  ES:[BX+02],DX    ;see if anyone pressed a key by looking at the tail
    Jne  Exit             ;they did, so we're outa here
    Jcxz Do               ;if the seconds was given as zero, loop endlessly
    
    Mov  AX,Offset Ticks  ;else, call Pause to wait for one timer tick
    Push BX               ;save BX and CX because Pause trashes those
    Push CX
    Push AX               ;pass the Ticks argument on to Pause
    Call Pause            ;there will be a slight delay...
    Pop  CX               ;restore the registers
    Pop  BX
    Loop Do               ;and loop Ticks times

Exit:
    Ret                   ;return to caller

B$SLEP Endp
End
