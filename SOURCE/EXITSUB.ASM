;********* EXITSUB.ASM - PDQ routine for exiting a SUB or FUNCTION

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data?
    Extrn P$RetAdr   :Word  ;these are in SUBDATA.ASM
    Extrn P$RetSeg   :Word
    Extrn B$CurFrame :Word

.Code

B$EXSA Proc                 ;cleans up after a SUB or FUNCTION

    Pop  P$RetAdr           ;retrieve the address to return to later
    Pop  P$RetSeg           ;and the segment
    Lea  SP,[BP-06]         ;restore the stack pointer
    Pop  DI                 ;and retrieve the stuff saved earlier in B$ENRA
    Pop  SI
    Pop  B$CurFrame
    Pop  BP
    Jmp  DWord Ptr P$RetAdr ;return to caller via far jump

B$EXSA Endp
End
