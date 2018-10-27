;******* RANDOMIZ.ASM P.D.Q. replacement for BASIC's RANDOMIZE statement

;Copyright (c) 1991 Ethan Winer

;NOTE: Assemble this file with the /e math emulator switch.


.8087
.Model Medium, Basic
.Data
    Extrn P$Seed:Word           ;this is in PDQRAND.ASM

.Code

B$RNZP Proc, Value:QWord        ;this is the incoming double on the stack

    FLD  QWord Ptr Value        ;load the incoming argument on the 8087 stack
    FISTP Word Ptr P$Seed       ;and store it back out as an integer
    FWAIT                       ;wait for the 8087 to finish
    Ret                         ;return to BASIC

B$RNZP Endp
End
