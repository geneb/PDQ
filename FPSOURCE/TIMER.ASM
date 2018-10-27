;********* TIMER.ASM - P.D.Q. replacement for BASIC's TIMER function

;Copyright (c) 1991 Ethan Winer

;NOTE: Assemble this file with the /e math emulator switch.


.8087
.Model Medium, Basic
.Data?
    Output DD 1 Dup (?)     ;the single precision output value goes here

.Data
    Divisor DQ 18.206481    ;this is the PC's clock frequency / 65,536
                            ;  (or the number of ticks per second)
.Code

B$TIMR Proc

    Xor  AX,AX              ;look at the BIOS long integer system time count
    Mov  ES,AX              ;  in low memory through ES
    Les  AX,ES:[046Ch]      ;get both words at once

    Push ES                 ;push them onto the stack
    Push AX
    Mov  BX,SP              ;point BX at the system time count
    
    FILD DWord Ptr [BX]     ;load the long integer count onto the 8087 stack
    FDIV QWord Ptr Divisor  ;divide by 18.2 to get the number of seconds
    FSTP DWord Ptr Output   ;store the result in Output
    FWAIT                   ;wait for the 8087 to finish

    Pop  AX                 ;discard the timer count now on the stack
    Pop  AX
    
    Mov  AX,Offset Output   ;show the caller where the output is located
    Ret                     ;return to BASIC

B$TIMR Endp
End
