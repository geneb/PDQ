;********* STRING$$.ASM - PDQ replacement for BASIC's B$STRS routine

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


;This is the STRING$ function, when the second argument is a string.


.Model Medium, Basic
    Extrn P$FixStr:Proc      ;this is in FIXSTR.ASM
    Extrn B$STRI:Proc     ;this is in STRING$.ASM
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM

.Code

B$STRS Proc, NumChars:Word, CharStr:Word

    Push CharStr          ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  CharStr,AX       ;

    Push NumChars         ;pass the incoming number of characters to B$STRI
    Mov  BX,CharStr       ;get the address for Char$ descriptor
    Mov  BX,[BX+02]       ;get the address of the first character in Char$
    Mov  AL,[BX]          ;get the first character
    Push AX               ;and pass on its ASCII value to B$STRI
    Call B$STRI           ;why duplicate effort, let B$STRI do the work

    Push CharStr          ;delete the string if necessary
    Call P$FreeTemp
    Ret

B$STRS Endp
End
