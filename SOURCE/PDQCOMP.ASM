;********* PDQCOMP.ASM - compares a block of memory

;Copyright (c) 1989 Ethan Winer


;Syntax - Same = PDQCompare%(BYVAL FromSeg, BYVAL FromAddr, _
;                            BYVAL ToSeg, BYVAL ToAddr, BYVAL NumBytes)

.Model Medium, Basic
.Code

PDQCompare Proc Uses SI DI DS, FromSeg:Word, FromAdr:Word, ToSeg:Word, ToAdr:Word, NumBytes:Word

    Mov  SI,NumBytes        ;get the address for NumBytes
    Mov  CX,[SI]            ;put NumBytes into CX
    
    Mov  DS,FromSeg         ;get FromSeg by value
    Mov  SI,FromAdr         ;and FromAddr
    Mov  ES,ToSeg           ;and ToSeg
    Mov  DI,ToAdr           ;and ToAddr

    Cld                     ;forward ho
    Repe Cmpsb              ;here's the compare

    Mov  AX,-1              ;assume all the bytes matched as function output
    Je   Exit               ;we were right, skip over
    Inc  AX                 ;wrong RAM breath, increment AX up to zero

Exit:
    Ret                    ;return to BASIC
    
PDQCompare Endp
End
