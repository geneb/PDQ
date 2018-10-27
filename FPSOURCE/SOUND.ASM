;********* SOUND.ASM - P.D.Q. replacement for BASIC's SOUND statement

;Copyright (c) 1991 Ethan Winer

;NOTE: Assemble this file with the /e math emulator switch.


.8087                       ;allow coprocessor instructions
.Model Medium, Basic
    Extrn PDQSound:Proc     ;this is in PDQSOUND.ASM

.Code

B$SOND Proc, Frequency:Word, Duration:DWord

    Lea  AX,Frequency       ;load address of the incoming integer frequency
    Push AX                 ;pass that on to PDQSound
    Dec  AX                 ;point two bytes lower on the stack
    Dec  AX                 ;(two Dec instructions is better than Sub AX,2)
    Push AX                 ;pass that on to PDQSound too

    Fld  DWord Ptr Duration     ;load the Sgl Prec duration onto the FP stack
    Fistp Word Ptr Duration+2   ;then store it as an integer on top of itself
    Fwait                       ;(anything on the stack is fair game!)
    Call PDQSound               ;let PDQSound do the real work
    Ret                         ;return to BASIC

B$SOND Endp
End
