;******** MKDMBF.ASM - PDQ replacement for BASIC's B$FMDF routine

;by Ethan Winer using code derived from Cobb's Inside Assembler newsletter
;(after fixing the code to handle zero properly!)

.Model Medium, Basic
    Extrn P$MakeTemp:Proc    ;in MAKETEMP.ASM

.Code

B$FMDF Proc Uses DI SI, Word3:Word, Word2:Word, Word1:Word, Word0:Word

    Mov  AX,Word3       ;copy the high word into AX
    Mov  DX,AX          ;keep a copy for later
    Mov  CL,4           ;number of bits to shift
    Shr  AX,CL          ;shift 'em good

    And  AX,7FFh        ;mask off the sign bit
    Jz   @F             ;if the exponent is zero skip over
    Sub  AX,37Eh        ;adjust the exponent bias only if non-zero!
    
@@:
    Mov  Byte Ptr Word3+1,AL    ;store just the exponent

    Mov  AX,DX          ;load the copy of the high word into AX again
    Mov  SI,Word0       ;and then load the rest into DX:BX:SI
    Mov  BX,Word1
    Mov  DX,Word2
    Mov  CX,3           ;the number of times to shift bits

@@:
    Shl  SI,1           ;shift the mantissa left one place
    Rcl  BX,1
    Rcl  DX,1
    Rcl  AL,1
    Loop @B

    Shl  AX,1           ;shift the sign bit into the Carry flag
    Rcr  AL,1

    Mov  Word0,SI       ;store the output back onto the stack
    Mov  Word1,BX
    Mov  Word2,DX
    Mov  Byte Ptr Word3,AL

    Mov  CX,8           ;a double precision number is eight bytes long
    Call P$MakeTemp     ;claim pool memory and return w/descriptor in BX

    Lea  SI,Word0       ;point SI to the input value on the stack
    Rep  Movsb          ;copy from the stack to the string pool

    Mov  AX,BX          ;show BASIC where the output descriptor is located

Exit:
    Ret                 ;return to BASIC

B$FMDF Endp
End
