;********** RESUME.ASM - P.D.Q. replacement for BASIC's B$RESA and B$RESN

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
    Extrn P$DelAllTemps:Proc;this is in DELTEMPS.ASM
    
.Data?
    Extrn P$OnErrStack:Word ;these are in ONERRDAT.ASM
    Extrn P$OnErrBP:Word
    Extrn P$NextAdr:Word
    Extrn P$NextSeg:Word
    Extrn P$NextStack:Word
    Extrn P$NextBP:Word

.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Extrn P$ErrAdr:Word     ;these are in ONERRDAT.ASM
    Extrn P$ErrSeg:Word

.Code

B$RESA Proc                 ;this handles RESUME linelabel

    Cmp  P$ErrAdr,-1        ;is ON ERROR GOTO currently in effect?
    Je   Exit               ;no, return (otherwise P$ErrAdr may not be valid)

    Mov  SP,P$OnErrStack    ;set the stack pointer for the main module level
    Mov  BP,P$OnErrBP       ;and the value for BP when DoError was called
    Push P$ErrSeg           ;push the segment to go to (when ON ERROR was set)
    Push AX                 ;and the address of Linelabel passed to us by QB
    Call P$DelAllTemps      ;delete any temporary strings left lying around
    Mov  P$PDQErr,CX        ;we know that P$DelAllTemps returns with CX = 0
    
Exit:
    Ret                     ;"return" to the destination line label

B$RESA Endp



B$RESN Proc                 ;this handles RESUME NEXT

    Cmp  P$ErrAdr,-1        ;is ON ERROR GOTO currently in effect?
    Je   Exit               ;no, so simply return

    Mov  SP,P$NextStack     ;set the stack pointer for whomever bombed out
    Mov  BP,P$NextBP        ;and the value for BP when P$DoError was called
    Push P$NextSeg          ;as above, but use the segment and address of
    Push P$NextAdr          ;  the routine that failed
    Call P$DelAllTemps      ;delete any temporary strings left lying around
    Mov  P$PDQErr,CX        ;we know that P$DelAllTemps returns with CX = 0
    
Exit:
    Ret                     ;"return" to the destination line label

B$RESN Endp
End
