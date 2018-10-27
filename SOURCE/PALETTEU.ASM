;********** PALETTEU.ASM - PDQ replacement for BASIC's B$PALU routine

;PALETTEU.ASM  Copyright (c) 1992  Thomas G. Hanlin III


.Model Medium, Basic

.Code

B$PALU Proc Uses SI, DSeg:Word, DOfs:Word, ArrayDesc:Word

    Mov   AH,0Fh          ;get video mode in AL
    Int   10h             ;

    Mov   ES,DSeg         ;segment
    Mov   SI,DOfs         ;offset
    Mov   BX,ArrayDesc    ;ptr to array descriptor
    Mov   DX,[BX+12]      ;bytes per array element
    Xor   BX,BX           ;

    Mov   CX,4            ;assume 4 attributes
    Cmp   AL,0Fh          ;EGA mono graphics?
    Je    SetEGA          ;  yep, go to it
    Mov   CX,16           ;assume 16 attributes
    Cmp   AL,0Dh          ;EGA or graphics mode?
    Jb    Done            ;  no, exit
    Cmp   AL,10h          ;EGA graphics mode?
    Jbe   SetEga          ;  yep, go to it
    Cmp   DX,4            ;LONG integer array?
    Jne   Done            ;  no, exit

    Cmp   AL,12h          ;VGA medium-color graphics mode?
    Je    SetVGA          ;  yep, go to it
    Mov   CX,2            ;assume 2 attributes
    Cmp   AL,11h          ;VGA low-color graphics mode?
    Je    SetVGA          ;  yep, go to it
    Mov   CX,256          ;assume 256 attributes
    Cmp   AL,13h          ;VGA high-color graphics mode?
    Jne   Done            ;  no, exit

SetVGA:
    Push  DS              ;
    Push  ES              ;
    Pop   DS              ;

SetVGA1:
    Push  BX              ;
    Push  CX              ;
    Lodsw                 ;
    Xchg  AX,CX           ;CH = green, CL = red
    Lodsw                 ;
    Cmp   AX,-1           ;set it?
    Je    SetVGA0         ;  no, skip
    Mov   DH,AL           ;DH = blue
    Xchg  CL,DH           ;now CL = blue, DH = red
    Mov   AX,1010h        ;set VGA palette register
    Int   10h             ;

SetVGA0:
    Pop   CX              ;
    Pop   BX              ;
    Inc   BX              ;
    Loop  SetVGA1         ;
    Pop   DS              ;

Done:
    Ret                   ;return to caller

SetEGA:
    Push  BX              ;
    Mov   AX,ES:[SI]      ;BH = color
    Cmp   AX,-1           ;set it?
    Je    SetEGA0         ;  no, skip
    Mov   BH,AL           ;
    Mov   AX,1000h        ;set EGA palette register
    Int   10h             ;

SetEGA0:
    Pop   BX              ;
    Add   SI,DX           ;
    Inc   BX              ;
    Loop  SetEGA          ;
    Jmp   Done            ;

B$PALU Endp
End
