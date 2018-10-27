;********* FIXSTR.ASM - translates far string literal to near var. as needed

;Copyright (c) 1992 Thomas G. Hanlin III


COMMENT |

The P$FixStr routine in this file is called by all the internal routines in
the PDQVBDOS.LIB library that accept string arguments.  P$FixStr determines
if the incoming string is a far constant in far memory or a string variable
in near memory.  If the string is a constant it is copied to a temporary
variable, and the address of the copy is returned in AX.  Otherwise, no copy
is made and the original descriptor address is returned.  The routines that
accept string arguments have been modified to call P$FixStr, as shown in this
code fragment from the ASC.ASM file:

    B$FASC Proc, Work:Word

        Push Work       ;if it's a far string literal, copy to a near string
        Call P$FixStr   ;
        Mov  Work,AX    ;

The string is passed to P$FixStr, and the address returned is assigned back
to the stack.  (Here, the name Work is replaced by [BP+06] by MASM.)  If the
string was a constant the new address is assigned to Work.  Otherwise, the
original address is used.  The logic used to determine if the string is near
or far works as follows:

    1. See if the lower word in the string descriptor is zero.  If it is, the
       string is a near null string, and the original descriptor address is
       returned in AX.

    2. The descriptor address is compared to the lower word in the string
       descriptor.  If the word holds a higher address it may be a far string
       and further checking is performed.  Otherwise, P$FixStr knows that the
       string is near and it returns the original descriptor address.

    3. One final test is needed to accommodate dynamic string arrays, whose
       elements may appear to be a far string constant.  This is handled by
       checking for a valid back pointer.
|


.Model Medium, Basic
    Extrn P$MakeTemp:Proc   ;this is in MAKETEMP.ASM

.Data
    Extrn P$NullDesc:Word   ;this is in PRINTDAT.ASM

.Code

P$FixStr Proc, Work:Word

    Push SI
    Mov  SI,Work             ;get the address for Work$ descriptor
    Mov  AX,[SI+2]
    Or   AX,AX               ;is it a null near string?
    Jz   NearStr             ;yes, go handle it as a near string
    Cmp  SI,AX               ;does it appear to be a far string literal?
    Ja   FarStr              ;yes, go check it further

NearStr:
    Xchg AX,SI               ;return string descriptor as-is

Exit:
    Pop  SI
    Ret

FarStr:
    Push BX
    Mov  BX,[SI+2]        ;check for a near string in sheep's clothing:
    Cmp  SI,[BX-2]        ;is there a valid back-pointer?
    Pop  BX
    Je   NearStr          ;yep, must be a $DYNAMIC string array-- treat as near

    Push BX
    Push CX
    Push ES

    Mov  BX,[SI+2]        ;far string literal...
    Mov  ES,[BX]
    Mov  SI,[SI]
    Mov  SI,ES:[SI]
    Mov  CX,ES:[SI]
    Jcxz MakeNull         ;if all we need is a null descriptor, skip this mess

    Inc  SI
    Inc  SI               ;at this point, LEN=cx, PTR=es:si
    Push DI
    Push DS
    Push ES
    Call P$MakeTemp       ;claim space in the string pool
    Pop  DS
    Rep  Movsb            ;copy the far string literal there
    Pop  DS
    Pop  DI
    Xchg AX,BX            ;return the output descriptor address in AX

FarExit:
    Pop  ES
    Pop  CX
    Pop  BX
    Jmp  Exit

MakeNull:
    Mov  AX,Offset P$NullDesc ;get the address of the dummy null descriptor
    Jmp  FarExit

P$FixStr Endp
End
