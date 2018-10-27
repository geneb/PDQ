;********** B_ONEXIT.ASM - allows auto-execution upon program termination

;Copyright (c) 1990 Crescent Software
;written by Dave Cleary

Comment !

This procedure allows one or more assembler routines to chain themselves into
the "termination process" automatically.  When a P.D.Q. (or regular BASIC)
program ends by running out of statements, or by using END, STOP, or SYSTEM,
BASIC makes a call to a central routine that in turn tells DOS to end the
program.  Therefore, it is simple to obtain the address of that procedure,
and instead store the address of another procedure.  When the replacement
routine is finished it then calls the original procedure, so the program is
eventually ended.

In earlier versions of P.D.Q. it was possible, albeit difficult, to write an
assembler routine that hooks itself into the exit chain.  Although QuickBASIC
has supported this concept for some time using a routine called _ONEXIT, only
with QuickBASIC 4 was this feature documented (and then renamed to B_ONEXIT).
Seeing how useful this would be for P.D.Q., Dave Cleary (who wrote PDQComm)
created this version for us.  In Dave's case, he wanted to be able to close
the Com ports automatically (and thus restore the hooked interrupts), even if
the programmer forgot to do that.

This implementation of B_ONEXIT differs slightly from the one provided by
Microsoft in that only ten routines may be "registered" and called upon exit.
Also, this version does not return DX:AX with zero to indicate that no more
routines may be stored, or the segment and address of the registered routine
if the routine was registered successfully.  Instead, it is up to the caller
to check the public variable Number, and ensure it is currently 10 or less.
(In practice, it is unlikely that ten routines will actually call B_OnExit.)

The original _ONEXIT is also supported here, for compatibility with Stay-Res.

Here's a program skeleton showing how B_OnExit is set up and called:

    .Model Medium, Basic
        Extrn B_OnExit:Proc     ;both of these Externs are in B_ONEXIT.ASM
    .Data
        Extrn Number:Word
    .Code
        Cmp  Number,10          ;is there room for us in the address table?
        Ja   Fail               ;no, issue an error or fail in some manner
        Mov  AX,Seg TermProc    ;yes, pass the segment to be called (if this
        Push AX                 ;  is in the same file simply push CS instead)
        Mov  AX,Offset TermProc ;pass the address within that segment to call
        Push AX
        Call B_OnExit           ;tell B_OnExit to call TermProc automatically
        .                       ;  when the program ends
        .
        
    Fail:                       ;arrive here if we couldn't call B_OnExit
        .
        .

End Comment !


.Model Medium,Basic
    Public Number           ;so other routines can see if Number is maxed out

.Data?
    Address DD 11 Dup(?)    ;Data space for ten routines + existing P$ExitAdr
   
.Data
    Extrn   P$ExitAdr:Word  ;this is in PDQDATA.ASM, holds "On Exit" address
    Number  DW 1            ;Number of routines currently registered
                            ;(start with 1 for the current P$ExitAdr)
    Installed DB 0          ;flags if we've been here before
.Code

B_OnExit Proc               ;this is the entry point for B_OnExit
    Xor  CX,CX              ;clear CX to show this is B_OnExit, not _OnExit
    Db   3Dh                ;this fakes Mov CX,SP below to a bogus compare
B_OnExit Endp


_OnExit Proc                ;this is the entry point for _OnExit
    Mov  CX,SP              ;force CX to non-zero (SP can't possibly be zero)
_OnExit Endp                ;in either case, fall into the code below


P_OnExit Proc, RAddr:DWord          ;This handles both _OnExit and B_OnExit

    Cmp   Installed,0               ;is CleanUp already installed?
    Jne   Hooked                    ;yes, skip ahead

    Les   AX,DWord Ptr P$ExitAdr    ;get the current exit address and segment
    Mov   Word Ptr [Address],AX     ;and save them in table entry zero
    Mov   Word Ptr [Address+2],ES
    Dec   Installed                 ;flag that we've already done this
    
    Mov   P$ExitAdr,Offset P$Cleanup ;now tell PDQ.ASM to call the clean-up
    Mov   P$ExitAdr+2,CS            ;  procedure when the program terminates

Hooked:
    Mov   BX,Number                 ;see who's next up to be registered
    Cmp   BX,10                     ;Split if there's already ten routines
    Ja    Done                      ;  in the queue
    Shl   BX,1                      ;Multiply by 4 since each table entry
    Shl   BX,1                      ;  is four bytes long
   
    Les   AX,RAddr                  ;Load far pointer of termination routine
    Mov   Word Ptr Address[BX],AX   ;Store it in the local "array"
    Mov   Word Ptr Address[BX+2],ES
    Inc   Number                    ;Increment number of registered routines

Done:
    Jcxz Exit                       ;they called B_OnExit, return normally
    Pop  BP                         ;they called _OnExit, pop BP manually
    Retf 0                          ;and DO NOT fix the stack on return

Exit:
    Ret                             ;Return to caller
   
P_OnExit Endp



P$CleanUp Proc

    Mov   CX,Number                 ;Get the number of registered routines
   
CleanLoop:
    Mov   BX,CX                     ;Put into BX
    Dec   BX                        ;Adjust for zero based
    Shl   BX,1                      ;Multiply by 4
    Shl   BX,1
    
    Push  CX                        ;Save CX in case the routine trashes it
    Call  DWord Ptr[Address+BX]     ;Call termination routine
    Pop   CX                        ;Restore CX
   
    Loop CleanLoop                  ;Continue until all have been called
    Ret                             ;All done
   
P$CleanUp Endp
End
