;********* DEFFN.ASM - PDQ replacement for BASIC 7's B$EXFA routine

;Copyright (c) 1989 Ethan Winer


;These are identical to the versions for QuickBASIC, except B$EXFA discards
;an extra stack parameter (the caller's code segment).  See the comments in
;the main DEFFN.ASM source file.

.Model Medium, Basic
;   Extrn B$LINA:Proc           ;this is in DEBUG.ASM

.Stack

.Data?
    Extrn P$RetAdr:Word         ;these are in SUBDATA.ASM
    Extrn P$RetSeg:Word

    Extrn PDQ_Stack_Foot:Byte   ;this is in PDQ.ASM

.Code

B$ENFA Proc

;   Cmp  SP,Offset PDQ_Stack_Foot   ;how're we doing?
;   Jae  Exit                       ;okay, we're outa here
;   Mov  P$PDQErr,126       ;not so hot, assign an "Out of stack space" error
;   Jmp  Far Ptr B$LINA     ;and let B$LINA do the rest

Exit:
    Ret                     ;return to BASIC (don't REM this out!)

B$ENFA Endp



B$EXFA Proc

    Add  SP,2               ;throw away the caller's address
    Pop  P$RetSeg           ;retrieve the segment to jump to
    Pop  P$RetAdr           ;and the address
    Add  SP,2               ;BASIC 7 requires this
    Jmp  DWord Ptr P$RetAdr ;go for it

B$EXFA Endp
End
