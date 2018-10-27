;----- PDQVAL.ASM - like BASIC's VAL for ints and long ints only, MUCH faster

;Copyright (c) 1988 Crescent Software
;written by Paul Passarelli
; *** indicates improvements by Myrna Traver Larson, 7/1/90
; Rcl to Shl modifications by Jay Munro 7/3/90
; 11/3/92  Thomas G. Hanlin III   added far string support

;Syntax - Value = PDQValI%(Number$)
;         Value = PDQValL&(Number$)

.Model Medium, Basic
    Extrn P$FixStr:Proc   ;this is in FIXSTR.ASM

.Code

PDQValI Proc
PDQValI Endp


PDQValL Proc, Number:Ptr
    Push Number           ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Number,AX        ;

    Cld                   ;insure that Lodsb will increment SI
    Mov  SI,Number        ;get the address for Number$ descriptor
    Xor  DX,DX            ;clear DX as the Hi word
    Mov  BX,DX            ;clear BX as the Lo word
    Mov  CX,[SI]          ;put its length into CX
    Jcxz Exit             ;it's a null string, exit

    Mov  SI,[SI+02]       ;put the address of Number$ data into SI
    Mov  DI,DX            ;clear DI as a "negative" flag
    Jmp  Short Eat2       ;skip ahead

Eat1:                     ;remove all leading spaces
    Dec  CX               ;show that we got another digit
    Jz   Exit             ;we're all done, bye

Eat2:
    Lodsb                 ;get a digit
    Cmp  AL,32            ;is it a space?
    Je   Eat1             ;yes, eat it

    Dec  SI               ;no, point back to where we were
    Mov  AH,DH            ;zero out AH (DH is still 0)

    Cmp  AL,"-"           ;is it a negative number?

    Jne  SaveSign         ;no, skip ahead
    Dec  DI               ;yes, remember this in DI
    Inc  SI               ;point SI past the minus sign
    Dec  CX               ;show Number$ being one character shorter
    Jz   Exit             ;it's a null string, exit with a value of 0

SaveSign:
; *** put the flag on the stack.  This frees up DI.
    Push DI

PDQValWork:
    Lodsb                 ;get a digit
    Sub  AL,32            ;see if it's a space
    Jz   Sign             ;yes, so we're all done 
    Sub  AL,10h           ;convert "0" through "9" to actual values
    Js   Sign             ;if it's punctuation we're out-a-here
    Cmp  AL,9             ;the highest digit (in decimal)
    Ja   Sign             ;too big, go finish up

    ;this is faster than Multiplying (though it sure looks funny!)
    Shl  BX,1             ;double BX
    Rcl  DX,1             ;double DX

    Mov  BP,BX            ;save value of BX * 2
    Mov  DI,DX            ;and of DX * 2
    Shl  BX,1             ;BX * 4
    Rcl  DX,1             ;DX * 4
    Shl  BX,1             ;BX * 8
    Rcl  DX,1             ;DX * 8

    Add  BX,BP            ;BX * 10
    Adc  DX,DI            ;DX * 10

    Add  BX,AX            ;add the accumulator to the low word
    Adc  DX,0             ;and carry it through to the high word

Space:
    Loop PDQValWork       ;until done

Sign:
    Pop  DI               ; *** get the sign flag back from the stack
    Inc  DI               ;see if the number was negative
    Jnz  Exit             ;no, continue
    Not  BX               ;yes, change the sign
    Not  DX               ; by flipping the bits
    Add  BX,1             ; then adding one
    Adc  DX,0             ; to the 32 bit result

Exit:
    Mov  AX,BX            ;move the low word to AX for the function output
    Ret                   ;return to BASIC

PDQValL Endp
End
