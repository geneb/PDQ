;******* REDIMABS.ASM - redimensions a Dyanmic array to any absolute segment

;Copyright (c) 1991 Ethan Winer


;Syntax:
;
; CALL RedimAbsolute(Array(), BYVAL LoBound%, BYVAL UpBound%, BYVAL Segment%)
;
;It is up to the caller to have first defined the array with REDIM, and with
;a single element.  For example: REDIM Array(1 TO 1).

.Model Medium, Basic
.Code

RedimAbsolute Proc, Array:Word, LBound:Word, UBound:Word, NewSeg:Word

    Mov  BX,Array           ;get the array descriptor address
    Test Byte Ptr [BX+09],1 ;is it a static array?
    Jz   Exit               ;yes, bag out now

    Mov  Byte Ptr [BX+08],1 ;force the array to have one dimension
    Mov  CX,LBound          ;get the new LBOUND value
    Mov  [BX+16],CX         ;assign it to the array descriptor
    Mov  AX,UBound          ;get the new UBOUND value
    Sub  AX,CX              ;convert to number of elements
    Inc  AX                 ;there goes that pesky fudge again
    Mov  [BX+14],AX         ;assign the number of elements

    Mov  AX,NewSeg          ;get the new absolute segment
    Mov  [BX+02],AX         ;and assign that as well

    Mov  AX,[BX+12]         ;get the length of each element
    Mul  CX                 ;length * LBOUND = offset adjustment
    Neg  AX                 ;convert to a negative value
    Mov  [BX+10],AX         ;this is the new adjusted offset value

Exit:
    Ret

RedimAbsolute Endp
End
