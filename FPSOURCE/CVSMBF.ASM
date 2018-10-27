;*********** CVSMBF.ASM - PDQ replacement for BASIC's B$MCVS routine

;by Ethan Winer using code derived from Cobb's Inside Assembler newsletter
;(after fixing the code to handle zero properly!)


.Model Medium, Basic
    Extrn P$FreeTemp:Proc   ;this is in FREETEMP.ASM

.Data?
   Output DW 2 Dup (?)      ;a copy of the data goes here

.Code

B$MCVS Proc, MBFString

    Mov  BX,MBFString       ;get the incoming string descriptor address
    Mov  BX,[BX+02]         ;now BX points to the string's data
    Mov  AX,[BX]            ;grab the low word
    Mov  Output,AX          ;store it in the output
    
    Mov  AX,[BX+02]         ;now grab the high word
    Or   AH,AH              ;is the exponent zero?
    Jz   @F                 ;yes, leave it alone
    
    Sub  AH,2               ;fix the exponent
    Rcl  AL,1               ;slide the sign bit into the carry flag
    Rcr  AX,1               ;and then slide the sign and exponent into place

@@:
    Mov  [Output+2],AX      ;store that in the output too
    
    Push MBFString          ;delete the incoming string if it's a temporary
    Call P$FreeTemp
    
    Mov  AX,Offset Output   ;show BASIC where the output value is located
    Ret
    
B$MCVS Endp
End
