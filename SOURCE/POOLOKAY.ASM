;********* POOLOKAY.ASM - checks the integrity of the P.D.Q. string pool

;Copyright (c) 1990 Ethan Winer

;This routine walks through the active portion of the P.D.Q. string pool,
;and checks that each string's back pointer points to a valid descriptor that
;in turn points back to the string data.  PoolOkay is designed as an integer
;function, and returns -1 if the pool is intact, or 0 if it is not.

.Model Medium, Basic
.Data?
    Extrn P$StrPool:Byte    ;this is in STR#####.ASM

.Data
    Extrn P$BytesUsed:Word  ;this is in STR#####.ASM

.Code

PoolOkay Proc Uses SI

    Mov  SI,Offset P$StrPool;get the address for the start of the string pool
    Mov  DX,P$BytesUsed     ;see how many bytes are in use
    Add  DX,SI              ;now DX points to the end of the pool
    Cld                     ;ensure string ops are forward

MainLoop:
    Cmp  SI,DX              ;have we reached the end yet?
    Je   GoodExit           ;yes, so we're all done

    Lodsw                   ;get the current back pointer
    Test AL,1               ;is this an abandoned string?
    Jnz  Abandoned          ;yes, skip over it
    Mov  BX,AX              ;no, copy the descriptor's address into BX
    
    Cmp  SI,[BX+02]         ;does the string descriptor point to us?
    Jne  BadExit            ;no, so the pool has been corrupted
    Cmp  Word Ptr [BX],0    ;is the string length zero?
    Je   BadExit            ;yes, and zero-length strings don't belong here
    
    Add  SI,[BX]            ;okay, bump past this data based on the length
    Jmp  Short MainLoop     ;and keep walking through the pool

Abandoned:
    Shr  AX,1               ;convert the back pointer into the data length
    Add  SI,AX              ;now SI points to the next higher back pointer
    Jmp  Short MainLoop     ;continue scanning the pool

GoodExit:
    Mov  AX,-1              ;return -1 (true) for the function output
    Ret                     ;return to caller

BadExit:
    Xor  AX,AX              ;return 0 (false)
    Ret                     ;return to caller

PoolOkay Endp
End
