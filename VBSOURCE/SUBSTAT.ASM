;********* SUBSTAT.ASM - PDQ routine for STATIC SUB and FUNCTION support

;Copyright (c) 1989 Ethan Winer
; 11/03/92  Thomas G. Hanlin III   updated for VB-DOS (new stack size)
; 11/18/92  Thomas G. Hanlin III   updated for VB-DOS (merged in B$ENFA)


.Model Medium, Basic

.Data?
    Extrn P$RetAdr   : Word ;these are in SUBDATA.ASM
    Extrn P$RetSeg   : Word
    Extrn B$CurFrame : Word

.Code

;----- B$ENFA is called upon entry to a DEF FN function

B$ENFA Proc
    Xor  CX,CX              ;no parms (DEF FN parms aren't passed on the stack)
B$ENFA Endp

;----- B$ENSA is called upon entry to a STATIC SUB or FUNCTION

B$ENSA Proc

    Pop  P$RetAdr           ;retrieve the address to return to later
    Pop  P$RetSeg           ;and the segment

    Push BP                 ;set up stack addressing manually
    Mov  BP,SP
    Mov  B$CurFrame,SP      ;set the current frame pointer

    Push B$CurFrame         ;save the registers and data we'll be changing
    Push SI
    Push DI
    Push CX
    Xor  AX,AX
    Push AX
    Push AX
    Push AX
    Push AX
    Push AX
    Push AX
    Push AX

    Sub  SP,CX              ;allocate space for the incoming parameters
    Jmp  DWord Ptr P$RetAdr ;return to caller via far jump

B$ENSA Endp
End
