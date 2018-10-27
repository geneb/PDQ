;********** FRE$.ASM - P.D.Q. replacement for QuickBASIC's FRE("") function

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


.Model Medium, Basic
    Extrn P$FixStr:Proc   ;this is in FIXSTR.ASM
    Extrn P$Compact :Proc   ;this is in DYNAMIC.ASM
    Extrn P$FreeTemp:Proc   ;this is in FREETEMP.ASM

.Data
    Extrn P$BytesFree:Word  ;this is in STR#####.ASM

.Code

B$FRSD Proc, Dummy          ;Dummy is the unused incoming string argument

    Push Dummy             ;if it's a far string literal, make it a near string
    Call P$FixStr          ;
    Mov  Dummy,AX          ;

    Push Dummy              ;delete the string argument if necessary
    Call P$FreeTemp
    Call P$Compact          ;then do a garbage collection on the string pool
    Mov  AX,P$BytesFree     ;finally load the number of bytes free
    Xor  DX,DX              ;this is a long integer function
    Ret                     ;return to BASIC

B$FRSD Endp
End
