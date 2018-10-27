;********** POWER.ASM - raises any integer to any power

;Copyright (c) 1990 Crescent Software Inc.
;written by Paul Passarelli

;   DECLARE FUNCTION Power% (X, Y) - for return values < 32K
;or
;   DECLARE FUNCTION Power& (X, Y) - for any return value
;
;Syntax:  Value& = Power&(X, Y)
;
;         where Value& = X ^ Y, or zero if an error occurs


.Model Medium,BASIC
.Code

Power Proc Uses DI, Mantissa:Word, Exponent:Word

    Xor  DX,DX                  ;zero the hi word of the function output
    Mov  DI,DX                  ;assume the result will be positive

    Mov  BX,Mantissa            ;get the pointer to the mantissa
    Mov  AX,[BX]                ;AX is the implied register for multiplication
    Cmp  AX,1                   ;one raised to any power = 1
    Je   Finis                  ;jump if we're done
    Or   AX,AX                  ;zero to any power = zero
    Jz   OverFlow               ;0 ^ n is undefined

    Mov  BX,Exponent            ;get the pointer to the exponent
    Mov  CX,[BX]                ;the exponent in CX is the loop counter
    Or   CX,CX                  ;look at CX
    Jz   Unity                  ;any number to the zero power = 1
    Js   OverFlow               ;no fractional numbers
    Dec  CL                     ;the first power is implied
    Jz   Finis

    Cmp  CX,31                  ;because 2 ^ 31 wraps the sign bit
    Jae  OverFlow               ;anything larger would be shifted past the end

    Or   AX,AX                  ;is the mantissa negative
    Jns  Mant_Hold              ;no, nothing to do
    Neg  AX                     ;yes, work with a positive copy
    Test CL,1                   ;yes, see if the exponent was even or odd
    Jnz  Mant_Hold              ;the exponent was even, negatives will cancel
    Dec  DI                     ;used to be odd, the result must be negated

Mant_Hold:
    Mov  BX,AX                  ;save a copy of the mantissa
    Mov  BP,DX                  ;zero out BP for temp space

    Mul  AX                     ;square it.
    Dec  CL                     ;is it a simple square?
    Jz   Finis                  ;yes, it's positive, we're done

Expo:
    Mov  BP,DX                  ;save the starting hi part
    Mul  BX                     ;multiply the lo part
    Push DX                     ;save the top
    Xchg AX,BP                  ;bring back the hi part         
    Mul  BX                     ;multiply it
    Pop  DX                     ;revover the top no matter what

    Jo   Overflow               ;if a Mul goes over
    Add  DX,AX                  ;add this new top product
    Jc   OverFlow
    Mov  AX,BP                  ;restore the lo part from the first mult
    Loop Expo

    Or   DI,DI                  ;does the sign of the output need adjustment
    Jz   Finis                  ;no, we're done
    Not  AX                     ;yes, negate it
    Not  DX
    Add  AX,1
    Adc  DX,0
    Jmp Short Finis             ;return to basic

OverFlow:
    Xor  AX,AX                  ;return a zero to indicate the error
    Mov  DX,AX
    Jmp Short Finis
    
Unity:
    Mov  AX,1
    
Finis:
    Ret
    
Power Endp
End
