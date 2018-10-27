;********* CONCAT2$.ASM - PDQ replacement for BASIC 7's B$SACT routine

;Copyright (c) 1990 Ethan Winer


;This routine assigns and concatenates in a single operation.


.Model Medium, Basic
    Extrn B$SCAT:Proc       ;this is in CONCAT$.ASM
    Extrn B$SASS:Proc       ;this is in ASSIGN$.ASM

.Code

B$SACT Proc, Dest:Word, Source1:Word, Source2:Word

    Push Source1            ;pass string 1 to the concatenation routine
    Push Source2            ;and pass the second string too
    Call B$SCAT             ;this returns a descriptor address in AX
    Push AX                 ;pass that on to the string assign routine
    Push Dest               ;and pass the destination string too
    Call B$SASS             ;assign the result
    Ret

B$SACT Endp
End
