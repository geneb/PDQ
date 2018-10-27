;********** _NOVAL.ASM - "stub file" for INT39.ASM in the main P.D.Q. library

;Copyright (c) 1990 Ethan Winer


;See the comments in the main INT39.ASM routine.


.Model Medium, Basic
.Code

P$HookFP Proc               ;this does absolutely nothing but satisfy PDQ.ASM
P$HookFP Endp               ;fall into the code below


P$UnhookFP Proc
    Ret                     ;return to BASIC
P$UnHookFP Endp
End
