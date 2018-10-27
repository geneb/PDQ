;********* SWAPNUMS.ASM - PDQ replacement for BASIC's B$SWP2/4/8 routines

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
.Data
    NumBytes DB 0, 0        ;store the number of bytes to swap here

.Code
    Extrn B$SWPN:Proc       ;this is in SWAPTYPE.ASM


B$SWP2 Proc                 ;enter here to swap two bytes
    Mov  AL,2
    Db   3Dh                ;this creates a phony Cmp instruction
B$SWP2 Endp


B$SWP4 Proc                 ;enter here to swap four bytes
    Mov  AL,4
    Db   3Dh
B$SWP4 Endp


B$SWP8 Proc                 ;enter here to swap eight bytes
    Mov  AL,8
B$SWP8 Endp


P$SwapNums Proc             ;Seg1:Word, Adr1:Word, Seg2:Word, Adr2:Word

    Mov  NumBytes,AL        ;assign the number of bytes
    
    Pop  AX                 ;first remove the caller's return segment:address
    Pop  BX                 ;to "insert" the added parameters B$SWPN needs
    
    Pop  CX                 ;then remove the second parameter from the stack
    Pop  DX                 ;now only the first parameter is there
    Push Word Ptr NumBytes  ;push the number of bytes as B$SWPN expects

    Push DX                 ;now place the second parameter back again
    Push CX
    Push Word Ptr NumBytes  ;and use the same length again

    Push BX                 ;finally, replace the caller's return information
    Push AX
    Jmp  B$SWPN             ;and let the TYPE swap routine do the real work

P$SwapNums Endp
End
