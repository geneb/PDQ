;********** DOERROR.ASM - handles errors for all of the P.D.Q. DOS routines

;Copyright (c) 1989 Ethan Winer


;This procedure serves three important purposes in P.D.Q.  The first is to
;detect critical errors that are trapped using the CritErrOff routine.  If a
;critical error occurs when CritErrOff is in effect, the error is first saved
;by CritErrOff, and then control is returned to the caller.  However, the
;various P.D.Q. DOS routines have no way to know that the critical error
;handler intercepted the DOS call.  In earlier versions of P.D.Q. the DOS
;routines on detecting the carry set blindly stuffed AX into the P$PDQErr
;variable, on the assumption that it held the DOS error number.  However, the
;value in AX is irrelevant if the critical error handler was in effect.
;Further, when a critical error occurs the handler assigns the error value
;(71) directly.  Therefore, this routine checks if P$PDQErr is non-zero,
;which means that a critical error did in fact take place.  Otherwise, the
;DOS error number currently in AX is used instead.
;
;The second purpose for this routine is to see if ON ERROR is in effect.
;This is tested by examining the ON ERROR GOTO address, which is -1 if ON
;ERROR is not active.  If ON ERROR is in effect, then this routine cleans up
;the stack and jumps to the specified error code.  Otherwise, it assigns the
;current error value to P$PDQErr (returned by BASIC's built-in ERR function)
;allowing the caller to test it manually.
;
;Finally, the address, segment, and stack pointer of the routine that called
;P$DoError is also saved in case the user wants to use RESUME NEXT.


.Model Medium, Basic
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
    Extrn _SPSave:Word      ;this is in PDQDATA.ASM

.Code

P$DoError Proc

    Cmp  Byte Ptr P$PDQErr,0  ;did the Int24 critical error handler set this?
    Jne  CheckErr           ;yes, so leave the error as it is
    Mov  P$PDQErr,AX        ;no, use what's in AX

CheckErr:
    Cmp  P$ErrAdr,-1        ;is ON ERROR GOTO currently in effect?
    Jne  DoOnError          ;yes, go to the address originally specified
    Ret                     ;no, leave ERR set to show what happened and exit
    
DoOnError:
    Mov  BX,SP              ;yes, get the current stack pointer
    Mov  AX,[BX]            ;now save the address and segment of our caller
    Mov  P$NextAdr,AX       ;  in case they want to use RESUME NEXT later
    Mov  AX,[BX+02]
    Mov  P$NextSeg,AX
    
    Add  BX,4               ;remember where the stack must be to RESUME NEXT
    Mov  P$NextStack,BX     ;save it
    Mov  P$NextBP,BP        ;ditto for the caller's BP value
    
    Mov  BP,P$OnErrBP       ;force BP to the correct value for the main
    Mov  SP,_SPSave         ;and do the same for SP
    Jmp  DWord Ptr P$ErrAdr ;jump directly to the address in the main program
                            ;  code given earlier when ON ERROR was last used
P$DoError Endp
End
