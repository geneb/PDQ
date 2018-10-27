;********* COMMAND$.ASM - PDQ replacement for BASIC's B$FCMD routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$MakeTemp:Proc    ;this is in MAKETEMP.ASM
    
.Data
    Extrn P$PSPSeg:Word      ;this is in PDQDATA.ASM

.Code

B$FCMD Proc Uses SI DI DS

    Mov  ES,P$PSPSeg         ;get the PSP segment that was saved at startup
    Mov  CL,ES:[80h]         ;get the length of the command line arguments
    Xor  CH,CH               ;clear CH so we can use all of CX
    Mov  SI,81h              ;point SI to the beginning of the command tail

EatLoop:                     ;eat any leading "white space"
    Mov  AL,ES:[SI]          ;get the current character in the command tail
    Cmp  AL," "              ;is it a blank space?
    Je   EatIt               ;yes, go eat it up
    Cmp  AL,9                ;no, but is it a tab character?
    Jne  EatDone             ;no, so we're done eating the white space

EatIt:
    Inc  SI                  ;point one byte farther into the string
    Loop EatLoop             ;show the tail being one shorter and continue
                             ;(do both in one operation just to be slick)
EatDone:
    Push ES                  ;save ES because P$MakeTemp assigns it from DS
    Call P$MakeTemp          ;allocate temporary string memory
    Pop  ES                  ;get ES back again
    Jcxz Exit                ;there's no COMMAND$, or insufficient memory

    Push ES                  ;exchange ES and DS for Movsb below
    Mov  AX,DS
    Mov  ES,AX
    Pop  DS
    Rep  Movsb               ;copy COMMAND$ into the string pool

Exit:
    Mov  AX,BX               ;show BASIC where the output descriptor is
    Ret                      ;return to caller

B$FCMD Endp
End
