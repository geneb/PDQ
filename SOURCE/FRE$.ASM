;********** FRE$.ASM - P.D.Q. replacement for QuickBASIC's FRE("") function

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$Compact :Proc   ;this is in DYNAMIC.ASM
    Extrn P$FreeTemp:Proc   ;this is in FREETEMP.ASM

.Data
    Extrn P$BytesFree:Word  ;this is in STR#####.ASM

.Code

B$FRSD Proc, Dummy          ;Dummy is the unused incoming string argument

    Push Dummy              ;delete the string argument if necessary
    Call P$FreeTemp
    Call P$Compact          ;then do a garbage collection on the string pool
    Mov  AX,P$BytesFree     ;finally load the number of bytes free
    Xor  DX,DX              ;this is a long integer function
    Ret                     ;return to BASIC

B$FRSD Endp
End
