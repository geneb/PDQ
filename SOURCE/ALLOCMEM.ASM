;******* ALLOCMEM.ASM - allocates DOS memory for arrays or whatever

;Copyright (c) 1989 Crescent Software

;Syntax - Segment% = AllocMem%(NumBytes%)
;
;Where NumBytes% is the number of bytes requested, and Segment% receives the
;starting segment of the returned block of memory.  If Segment% is returned
;as zero, then you asked for more memory than is available, or DOS was unable
;to allocate the memory for some other reason.
;
;It is up to you to remember the segment returned by AllocMem, so you can
;release it later.  However, the memory will be released anyway when your
;program ends, unless it is a TSR.

.Model Medium, Basic
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM
    
.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM

.Code

AllocMem Proc, NumBytes:Word

    Xor  AX,AX              ;assume no errors
    Mov  P$PDQErr,AX        ;this is less code/faster than Mov P$PDQErr,0
    
    Mov  BX,NumBytes        ;get the address for NumBytes%
    Mov  BX,[BX]            ;put it into BX for DOS
    Mov  CL,4               ;divide by 16 to get the number of segments
    Shr  BX,CL              ;do the divide
    Inc  BX                 ;round up

    Mov  AH,48h             ;allocate memory service
    Int  21h                ;call DOS to do the hard stuff
    Jnc  Exit               ;no carry, no error
    Mov  Byte Ptr P$PDQErr,7    ;assign an "Out of memory" error
    Call P$DoError              ;let P$DoError see if ON ERROR is in effect
    Xor  AX,AX                  ;and return 0 for the segment

Exit:
    Ret                     ;return to BASIC

AllocMem Endp
End
