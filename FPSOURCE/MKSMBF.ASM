;******** MKSMBF.ASM - PDQ replacement for BASIC's B$FMSF routine

;by Ethan Winer using code derived from Cobb's Inside Assembler newsletter
;(after fixing the code to handle zero properly!)


.Model Medium, Basic
    Extrn P$MakeTemp:Proc    ;in MAKETEMP.ASM

.Code

B$FMSF Proc Uses DI SI, HighWord:Word, LoWord:Word

    Mov  AX,HighWord    ;convert the number to MBF in place on the stack
    Rcl  AX,1           ;slide the sign bit into the Carry flag
    Rcr  AL,1           ;and then into the correct bit position for MBF

    Or   AX,AX          ;is the exponent zero?
    Je   @F             ;yes, skip ahead
    Add  AH,2           ;no, adjust the exponent bias

@@:    
    Mov  HighWord,AX    ;copy the adjusted value back onto the stack

    Mov  CX,4           ;a single precision number is four bytes long
    Call P$MakeTemp     ;claim pool memory and return w/descriptor in BX

    Lea  SI,LoWord      ;point SI to the input value on the stack
    Rep  Movsb          ;copy from the stack to the string pool

    Mov  AX,BX          ;show BASIC where the output descriptor is located

Exit:
    Ret                 ;return to BASIC

B$FMSF Endp
End
