;******** POWER2.ASM - quickly raises 2 to a power between 0 and 31

;Copyright(c) 1990 Crescent Software Inc.
;written by Paul Passarelli

;Syntax:
;
;   DECLARE FUNCTION Power2% (Argument) - for return values < 32K
;or
;   DECLARE FUNCTION Power2& (Argument) - for any return value
;
;   Value& = Power2&(Argument)
;
;   where Value& = 2 ^ N, or zero if an error occurs
;
;   note: 2 ^ 31 returns as a negative value (-214783648)


.Model Medium, BASIC
.Code

Power2 Proc

    Mov  BX,SP            ;use BX instead of BP for less code
    Mov  BX,[BX+04]       ;get the address for the incoming argument
    Mov  CX,[BX]          ;get the exponent pushed from the stack

    Xor  AX,AX            ;clear the accumulator
    Xor  DX,DX            ;and the high word of the long

    Cmp  CX,32            ;first check for overflow
    Jae  Finis            ;the 32nd shift would wrap it

    Inc  AX               ;establish the output bit
    Jcxz Finis            ;if its negative we're done
    Clc                   ;no extra bits

Shift:                    ;raise the bit to the exponent
    Rcl  AX,1
    Rcl  DX,1
    Loop Shift

Finis:
    Ret  2                ;return to BASIC, 2 bytes * 1 param

Power2 Endp
End
