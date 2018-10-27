;********* DEFFN.ASM - PDQ replacement for BASIC's B$EXFA routine

;Copyright (c) 1989 Ethan Winer


;B$ENFA is called on entry to a DEF FN function.  In regular QB it checks the
;current stack pointer to ensure there is enough room for the current level
;of function nesting.  The code is commented out since there's not much we
;can do in that case.  However, it could be reinstated and added to DEBUG.ASM
;for debugging purposes when used with /d.
;
;B$EXFA is called to end a DEF FN function.  It gets the address to return to
;from the caller's stack frame, and then jumps there.

.Model Medium, Basic
;   Extrn B$LINA:Proc       ;this is in DEBUG.ASM

.Data?
    Extrn P$RetAdr:Word     ;these are in SUBDATA.ASM
    Extrn P$RetSeg:Word
    Extrn PDQ_Stack_Foot:Byte ;this is in PDQ.ASM

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
    Jmp  DWord Ptr P$RetAdr ;go for it

B$EXFA Endp
End
