;********* EXITSFUN.ASM - this exits a dynamic string FUNCTION

;EXITSFUN.ASM  Copyright (c) 1992  Thomas G. Hanlin III


.Model Medium, Basic
    Extrn B$STDL: Far       ;this is in STRDELET.ASM
    Extrn P$MakeTemp: Far   ;this is in MAKETEMP.ASM

.Code

B$SCPF Proc Uses SI DI, Str:Word

    Mov  BX,Str             ;get pointer to returned string
    Mov  CX,[BX]
    Mov  SI,[BX+2]
    Mov  BX,CX
    Call P$MakeTemp         ;allocate temporary string
    Rep  Movsb              ;copy result to temporary string
    Push BX
    Push Str                ;delete original string
    Call B$STDL
    Pop  AX                 ;return pointer to temporary string (was BX)
    Ret                     ;return to caller
    
B$SCPF Endp
End
