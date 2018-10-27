;*********** CVDMBF.ASM - PDQ replacement for BASIC's B$MCVD routine

;by Ethan Winer using code derived from Cobb's Inside Assembler newsletter
;(after fixing the code to handle zero properly!)


.Model Medium, Basic
    Extrn P$FreeTemp:Proc   ;this is in FREETEMP.ASM

.Data?
   Output DW 4 Dup (?)      ;a copy of the data goes here

.Code

B$MCVD Proc Uses DI, MBFString

    Mov  DI,MBFString       ;get the incoming string descriptor address
    Mov  DI,[DI+02]         ;now DI points to the string's data

    Mov  AX,[DI+06]         ;load AX:DX:BX:DI with the four MBF words
    Mov  DX,[DI+04]
    Mov  BX,[DI+02]
    Mov  DI,[DI]

    Mov  CX,3               ;the number of bits to shift
    
Do:
    Shr  AL,1               ;shift the mantissa right one place
    Rcr  DX,1
    Rcr  BX,1
    Rcr  DI,1
    Loop Do

    Or   AH,AH              ;is the exponent zero?
    Jnz  @F                 ;no, continue
    Mov  AL,AH              ;yes, assign all zeros
    Mov  [Output],AX        ;store the lower three words here
    Mov  [Output+02],AX
    Mov  [Output+04],AX
    Jmp  Short Zero         ;and skip ahead to assign the highest word

@@:
    Mov  [Output],DI        ;store the lower three words
    Mov  [Output+02],BX
    Mov  [Output+04],DX

    Mov  DL,AL              ;swap the sign and exponent bits
    Mov  AL,AH
    Sub  AH,AH
    Add  AX,37Eh            ;adjust the exponent bias
    Test DL,10h             ;is the sign bit set?
    Jz   @F                 ;no, skip ahead
    Or   AH,8               ;yes, so set the IEEE sign bit too

@@:
    Mov  CL,4
    Shl  AX,CL
    And  DL,0Fh
    Or   AL,DL

Zero:
    Mov  [Output+06],AX     ;store the result

    Push MBFString          ;delete the incoming string if it's a temporary
    Call P$FreeTemp
    
    Mov  AX,Offset Output   ;show BASIC where the output value is located
    Ret
    
B$MCVD Endp
End
