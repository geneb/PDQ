;********* MAKETEMP.ASM - finds a free temporary descriptor, allocates memory

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$TempStr:Proc    ;this is in TEMPSTR.ASM
    Extrn P$GetTemp:Proc    ;this is in GETTEMP.ASM

.Data
    Extrn P$BytesFree:Word  ;this is in STR#####.ASM
    Extrn P$BytesUsed:Word  ;this is in STR#####.ASM

.Code

;Call P$MakeTemp with CX set to the number of bytes needed.  It returns with
;BX holding the address of a "temporary" string descriptor, and DI pointing
;to the next available address in the string pool.  The descriptor is also
;assigned to the correct length and address.  If there is insufficient string
;memory for the request, CX will be adjusted downward accordingly.  If there
;is *no* available string memory at all, CX will be returned as 0.

P$MakeTemp Proc Uses AX

    Call P$GetTemp        ;get the next available temporary descriptor
    Jcxz Exit             ;nothing requested, bag out now and avoid the rush
    Inc  CX               ;add 2 to include the back pointer
    Inc  CX               ;(2 Inc's is more efficient than Add CX,2)

    Call P$TempStr        ;let P$TempStr do the memory and error handling
    Cmp  CX,3             ;is there enough for a back pointer and 1 byte?
    Jae  NufMem           ;yes, continue
    Sub  CX,CX            ;no, zero out CX to show the error
    Ret                   ;and exit now

NufMem:
    Mov  AX,BX            ;copy the descriptor address to AX
    Stosw                 ;create the back pointer and increment DI
    Sub  P$BytesFree,CX   ;show that much less available in the string pool
    Add  P$BytesUsed,CX   ;and that much more in use

    Dec  CX               ;the string length doesn't include the back pointer
    Dec  CX
    Mov  [BX],CX          ;assign the length portion of the descriptor
    Mov  [BX+02],DI       ;and the address portion too

Exit:
    Ret                   ;return to caller

P$MakeTemp Endp
End
