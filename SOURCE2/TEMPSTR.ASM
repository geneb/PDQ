;********** TEMPSTR.ASM - PDQ routine to claim temporary memory from the pool

;Copyright (c) 1989 Ethan Winer

;P$TempStr claims memory in the string pool, which the caller can use either
;as permanent or temporary memory.  Enter with CX = bytes needed, exits with
;ES:DI pointing to the start of the block, and the direction flag cleared
;(forward).  If there is not enough available memory for the current request,
;P$TempStr calls the garbage collection routine to compact the string pool.
;If there still isn't enough room, P$TempStr adjusts CX downward so the
;caller won't write past the end, and it also sets the StringShort function
;to show many additional bytes were needed but not available.
;
;Added 2-3-90: If the number of bytes requested in CX is 65535, then we know
;that Rob's READ routine was the caller and P$BytesShort is to be left alone.


.Model Medium, Basic
    Extrn P$Compact:Proc    ;this is in COMPACT.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Data?
    Extrn P$StrPool:Byte    ;this is in STR#####.ASM

.Data
    Extrn P$BytesFree:Word  ;these are also in STR#####.ASM
    Extrn P$BytesUsed:Word
    Extrn P$BytesShort:Word
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM

.Code

P$TempStr Proc Uses AX

    Cld                   ;clear the direction flag
    Push DS               ;copy DS into ES
    Pop  ES

    Cmp  CX,P$BytesFree   ;is there enough string memory?
    Jbe  EnoughMem        ;yes, skip ahead
    Call P$Compact        ;no, but try a garbage collection before giving up
    Cmp  CX,P$BytesFree   ;is there enough string memory now?
    Jbe  EnoughMem        ;yes, skip ahead

    Cmp  CX,0FFFFh        ;no, but was the request from Rob's READ routine?
    Pushf                 ;(save the result of this comparison)
    Mov  AX,CX            ;save the number of bytes they want in AX
    Mov  CX,P$BytesFree   ;clip CX to how much memory is actually available
    Popf                  ;(now see if Rob was the caller)
    Je   EnoughMem        ;yes, so leave CX adjusted but leave P$BytesShort
    Sub  AX,CX            ;now AX holds the difference between what they want
                          ;  and what is actually available

    Cmp  AX,P$BytesShort  ;is it more than the current value of P$BytesShort?
    Jbe  LessShort        ;no, so leave P$BytesShort where it is
    Mov  P$BytesShort,AX  ;yes, assign a new value to P$BytesShort

LessShort:
    Mov  Byte Ptr P$PDQErr,14   ;create an "Out of string space" error
    Call P$DoError              ;and see if ON ERROR is in effect

EnoughMem:
    Mov  DI,Offset P$StrPool    ;point DI to the start of string memory
    Add  DI,P$BytesUsed         ;now DI points to the start of what's free
    Ret                         ;return to caller

P$TempStr Endp
End
