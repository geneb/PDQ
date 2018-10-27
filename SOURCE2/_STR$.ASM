;********* _STR$.ASM - alternate STR$ function avoids leading blank

;Copyright (c) 1989 Crescent Software
;written by Jay Munro

.Model Medium, Basic
    Extrn P$MakeTemp: Proc      ;this is in MAKETEMP.ASM
    
.Data?
    DescrLength DW  1 Dup(?)
    DescrAddr   DW  1 Dup(?)
    Buffer      DB 11 Dup(?)    ;actual string space
    Sign        DB  1 Dup(?)    ;sign flag

.Code

B$STI2 Proc, Value:Word

    Mov  AX,Value         ;get the value directly from the stack
    Cwd                   ;convert it to a long integer
    Push DX               ;push the high word first
    Push AX               ;then the low word
    Call Far Ptr B$STI4   ;call Jay's routine
    Ret                   ;return to caller

B$STI2 Endp



B$STI4 Proc Uses SI DI, HiWord:Word, LoWord:Word

    Mov  BX,LoWord               ;get the low word
    Mov  AX,HiWord               ;and high word
    Mov  Sign,0                  ;assume a positive number
    Or   AX,AX                   ;check for a negative number
    Jns  Div10                   ;skip if not negative
    Xor  DX,DX                   ;clear some temporary space
    Neg  BX                      ;negate low word
    Sbb  DX,AX                   ;subtract with borrow, 0-AX to get negative
    Mov  AX,DX                   ;retread AX with negative number
    Dec  Sign                    ;set sign flag

Div10:
    Mov  SI,Offset Sign          ;point SI just past our string space
    Mov  CX,10                   ;set divisor to 10
    Xor  DI,DI                   ;clear DI as counter

GetDigit:
    Dec  SI                      ;point SI at correct character
    Inc  DI                      ;register that we have a character
    Xor  DX,DX                   ;clear DX to take remainder
    Div  CX                      ;divide AX first (High word)
    Mov  BP,AX                   ;save quotient
    Mov  AX,BX                   ;get low word
    Div  CX                      ;DX had leftover from first divide
    Mov  BX,AX                   ;save quotient
    Mov  AX,BP                   ;put high word back
    Add  DL,30h                  ;make it an ASCII digit from remainder
    Mov  [SI],DL                 ;put it in our string
    Or   AX,AX                   ;is high word zero?
    Jnz  GetDigit                ;no keep going
    Or   BX,BX                   ;is low word zero?
    Jnz  GetDigit                ;no keep going

    Cmp  Sign,-1                 ;did we have a negative number?
    Jnz  Exit                    ;no
    Dec  SI                      ;yes put in minus sign
    Inc  DI                      ;set digit count to include minus sign
    Mov  Byte Ptr [SI],"-"       ;put "-" in string

Exit:
    Mov  CX,DI                   ;P$MakeTemp needs the number of bytes in CX
    Call P$MakeTemp              ;claim that many bytes in the string pool
    Rep  Movsb                   ;copy the STR$() output there
    Mov  AX,BX                   ;return the output descriptor address in AX
    Ret

B$STI4 Endp
End
