;********* SUBRECUR.ASM - PDQ routine for recursive SUB and FUNCTION support

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


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
    Mov  B$CurFrame,SP      ;set the current frame pointer

    Push B$CurFrame         ;save the registers and data we'll be changing
    Push SI
    Push DI
    Push CX
    Push AX
    Push AX
    Push AX
    Push AX
    Push AX
    Push AX
    Push AX

    Sub  SP,CX              ;allocate space for the incoming parameters
    Mov  DI,SP              ;prepare to zero-out the stack space
    Push ES                 ;save ES for a moment
    Push DS                 ;copy DS into ES for the Stosw below
    Pop  ES
    Shr  CX,1               ;convert bytes to words
    Inc  CX                 ;round up
    Xor  AX,AX              ;clear to zeros
    Rep  Stosw              ;go for it
    Pop  ES                 ;restore ES

    Jmp  DWord Ptr P$RetAdr ;return to caller via far jump

B$ENRA Endp
End
