;********** CHDRIVE.ASM - P.D.Q. replacement for BASIC 7's CHDRIVE statement

;Copyright (c) 1990 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support

.Model Medium, Basic
    Extrn P$FixStr:Proc      ;this is in FIXSTR.ASM

.Code

B$CHDR Proc                 ;, Drive:Word

    Mov  BX,SP              ;address the stack manually
    Push [BX+04]            ;if it's a far string literal, make it a near
    Call P$FixStr           ;  string
    Mov  [BX+04],AX         ;

    Mov  BX,[BX+04]         ;get the address for the Drive$ descriptor
    Mov  CX,[BX]            ;get length of Drive$
    Jcxz Exit               ;if the string is null, ignore them and exit
    Mov  BX,[BX+02]         ;get the address of the first character in BX
    Mov  DL,[BX]            ;put ASC(Drive$) into DL

    Cmp  DL,"a"             ;is it below "a"?
    Jb   Continue           ;yes, skip
    Sub  DL,32              ;no, convert to upper case

Continue:
    Sub  DL,65              ;"A" now equals 0, "B" = 1, etc.
    Mov  AH,0Eh             ;set drive service
    Int  21h                ;call DOS

Exit:
    Retf 2

B$CHDR Endp
End
