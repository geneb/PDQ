;********* RELENV.ASM - releases a TSR program's environment

;Written by Michael H. Shacter


.Model Medium, Basic
.Data
    Extrn P$PSPSeg:Word     ;this is in PDQDATA.ASM

.Code

ReleaseEnv Proc

    Mov  ES,P$PSPSeg        ;get the PSP segment that was saved at startup
    Mov  ES,ES:[2Ch]        ;get the address of the environment segment
    Mov  AH,49h             ;DOS release memory service
    Int  21h                ;call DOS to do it
    Ret                     ;return to BASIC

ReleaseEnv Endp
End
