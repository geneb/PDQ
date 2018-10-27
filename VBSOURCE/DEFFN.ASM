;********* DEFFN.ASM - PDQ replacement for BASIC's B$EXFA routine

;Copyright (c) 1989 Ethan Winer
; 11/18/92  Thomas G. Hanlin III   updated for VB-DOS
;    -- merged B$ENFA into B$ENSA (in SUBSTAT.ASM), rewrote B$EXFA


;B$EXFA is called to end a DEF FN function.  It gets the address to return to
;from the caller's stack frame, and then jumps there.

.Model Medium, Basic

.Code

B$EXFA Proc
    Lea  SP,[BP-02]         ;restore the stack pointer
    Pop  BP                 ;toss the junk
    Pop  BP                 ;restore the base pointer
    Ret                     ;return to caller
B$EXFA Endp
End
