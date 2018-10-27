;********* SWAP$.ASM - PDQ replacement for BASIC's B$SWSD routine

;Copyright (c) 1989 Ethan Winer


;This routine handles swapping conventional string variables.


.Model Medium, Basic
.Code

B$SWSD Proc Uses BX          ;enters with SI & DI pointing to the descriptors

    Mov  AX,[SI]             ;get the first length word
    Xchg AX,[DI]             ;and exchange it with the second
    Mov  [SI],AX             ;complete the length portion of the swap

    Mov  BX,[SI+02]          ;get the first address word
    Xchg BX,[DI+02]          ;and exchange it with the second
    Mov  [SI+02],BX          ;complete the address portion of the swap
    
    Or   AX,AX               ;is the second string null?
    Jz   TryFirst            ;yes, we don't have to assign it a back pointer
    Mov  [BX-02],SI          ;no, so set the first string's old back pointer

TryFirst:
    Cmp  Word Ptr [DI],0     ;is the first string null?
    Je   Exit                ;yes, so we're all done
    Mov  BX,[DI+02]          ;no, get the first string's data address
    Mov  [BX-02],DI          ;and assign the second string's old back pointer

Exit:
    Ret                      ;return to caller

B$SWSD Endp
End
