;******** SUBSTAT.ASM - PDQ routine for STATIC SUB and FUNCTION support (BC7)

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic

.Data?
    Extrn P$RetAdr   : Word ;these are in SUBDATA.ASM
    Extrn P$RetSeg   : Word
    Extrn B$CurFrame : Word

.Code

;----- B$ENSA is called upon entry to a STATIC SUB or FUNCTION

B$ENSA Proc

    Pop  P$RetAdr           ;retrieve the address to return to later
    Pop  P$RetSeg           ;and the segment

    Push BP                 ;set up stack addressing manually
    Mov  BP,SP
    Push B$CurFrame         ;save the registers and data we'll be changing
    Mov  B$CurFrame,BP      ;set the current frame pointer

    Push SI
    Push DI
    Push CX
    Xor  AX,AX
    Rept 5
       Push AX
    Endm

    Sub  SP,CX              ;allocate space for the incoming parameters
    Jmp  DWord Ptr P$RetAdr ;return to caller via far jump

B$ENSA Endp
End
