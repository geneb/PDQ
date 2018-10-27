;********* PDQRAND.ASM - random number sequence generator

;Copyright (c) 1989 Ethan Winer
;adapted from Computer Language Magazine, 12/89, T.A. Elkins


.Model Medium, Basic
.Data
    Public P$Seed                   ;so RND.ASM can get at it too

    P$Seed  DW 7397, 29447, 802
    Mult    DW 179, 183, 182
    ModV    DW 32771, 32779, 32783

.Code

PDQRandomize Proc, NewSeed:Word

    Mov  BX,NewSeed
    Mov  BX,[BX]
    Mov  P$Seed,BX
    Mov  P$Seed + 2, 29447
    Mov  P$Seed + 4, 802
    Ret

PDQRandomize Endp



PDQRand Proc Uses SI, Limit:Word

    Mov  CX,3                ;repeat for each Seed, Mult, and Mod value
    Xor  BX,BX               ;BX is the data index
    Mov  SI,BX               ;clear the accumulator

Again:
    Mov  AX,P$Seed [BX]      ;load the initial seed
    Mul  Mult [BX]           ;multiply it
    Div  ModV [BX]           ;and obtain the Mod value
    Mov  P$Seed [BX],DX      ;save that for the next time
    Add  SI,DX               ;add it into the accumulator
    Add  BL,2                ;point to the next set of values
    Loop Again               ;until all three values are exhausted

    Mov  AX,SI               ;transfer the value to AX
    Xor  DX,DX               ;convert to an unsigned double-word
    Mov  BX,Limit            ;get the address for Limit%
    Mov  BX,[BX]             ;get the value of Limit%
    Inc  BX                  ;otherwise we'd never get beyond Limit% - 1
    Div  BX                  ;divide 'em
    Mov  AX,DX               ;return RND MOD (Limit% + 1)
    Ret                      ;back to BASIC with AX holding the result

PDQRand Endp
End
