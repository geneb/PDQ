;**** SUBRECUR.ASM - PDQ routine for recursive SUB and FUNCTION support (BC7)

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic

.Data?
    Extrn P$RetAdr   : Word ;these are in SUBDATA.ASM
    Extrn P$RetSeg   : Word
    Extrn B$CurFrame : Word

.Code

;----- B$ENRA is called upon entry to a recursive SUB or FUNCTION

B$ENRA Proc

    Pop  P$RetAdr           ;retrieve the address to return to later
    Pop  P$RetSeg           ;and the segment
    
    Push BP                 ;set up stack addressing manually
    Mov  BP,SP
    Push B$CurFrame         ;save the current stack frame pointer
    Mov  B$CurFrame,SP      ;set it to the new stack frame
    
    Push SI
    Push DI
    Push CX
    Push AX

    Add  CX,10              ;BASIC 7 needs 10 bytes more than QB4 and BC 6
    Sub  SP,CX              ;allocate space for the incoming parameters
    Mov  DI,SP              ;prepare to zero-out the temp. vars. on the stack
    Push ES                 ;save ES for a moment
    Push DS                 ;copy DS into ES for the Stosw below
    Pop  ES
    Shr  CX,1               ;convert bytes to words
    Xor  AX,AX              ;clear to zeros
    Rep  Stosw              ;go for it
    Pop  ES                 ;restore ES
    
    Jmp  DWord Ptr P$RetAdr ;return to caller via far jump

B$ENRA Endp
End
