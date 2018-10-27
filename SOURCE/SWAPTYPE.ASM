;********* SWAPTYPE.ASM - PDQ replacement for BASIC's B$SWPN routine

;Copyright (c) 1989 Ethan Winer


;This routine handles swapping fixed-length and TYPE variables.


.Model Medium, Basic
.Code

B$SWPN Proc Uses SI DI DS ES, Var1:DWord, Length1:Word, Var2:DWord, Length2:Word

    Lds  SI,Var1          ;get the segmented address of the first variable
    Mov  CX,Length1       ;and its length
    Les  DI,Var2          ;get the second variable
    Cmp  CX,Length2       ;are they the same length?
    Jne  Exit             ;no, and we don't support that

DoSwap:
    Mov  AL,[SI]          ;get a byte from the first variable
    Xchg AL,ES:[DI]       ;swap it with the second variable
    Mov  [SI],AL          ;complete the swap
    Inc  SI               ;point to the next byte in each variable
    Inc  DI
    Loop DoSwap           ;continue until done

Exit:
    Ret                   ;return to BASIC

B$SWPN Endp
End
