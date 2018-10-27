;******** MKX$.ASM - PDQ replacement for BASIC's B$FMKD, I, L, and S routines

;Copyright (c) 1991 Ethan Winer


.Model Medium, Basic
    Extrn P$MakeTemp:Proc    ;in MAKETEMP.ASM

.Code

B$FMKC Proc                 ;this is the entry point for MKC$
B$FMKC Endp                 ;fall into B$FMKD which the same thing

B$FMKD Proc                 ;this is the entry point for MKD$
    Mov  CL,8               ;MKD$ returns an 8-byte string
    Db   3Dh                ;fake the Mov CL,2 below to a bogus compare
B$FMKD Endp

B$FMKI Proc                 ;this is the entry point for MKI$
    Mov  CL,2               ;MKI$ returns a 2-byte string
    Db   3Dh                ;fake the Mov CL,4 below to a bogus compare
B$FMKI Endp

B$FMKL Proc                 ;this is the entry point for MKL$ and MKS$
B$FMKL Endp

B$FMKS Proc
    Mov  CL,4               ;MKL$ and MKS$ each return a 4-byte string
B$FMKS Endp                 ;all fall into the code below to do the real work

P$FMKx Proc                 ;accepts a varying number of parameter words

    Mov  CH,0                   ;clear CH so we can use all of CX
    Mov  Word Ptr CS:Patch,CX   ;self-modify the Ret to the correct value
    Jmp  Short @F               ;flush the CPU pre-fetch queue

@@:
    Push SI                 ;save the registers we're using manually
    Push DI

    Call P$MakeTemp         ;claim pool memory and return w/descriptor in BX

    Mov  SI,SP              ;point SI to the input value on the stack
    Add  SI,8               ;bump past saved SI and DI and caller's address
    Rep  Movsb              ;copy from the stack to the string pool

    Mov  AX,BX              ;show BASIC where the descriptor is located

Exit:
    Pop  DI                 ;restore registers manually
    Pop  SI
    Retf 2                  ;return to BASIC, force to be far with a value
    Patch Equ $-2           ;this lets us self-modify the code

P$FMKx Endp
End
