;********** PALETTE2.ASM - PDQ replacement for BASIC's B$PAL2 routine

;PALETTE2.ASM  Copyright (c) 1992  Thomas G. Hanlin III


.Model Medium

.Code

B$PAL2 Proc

    Push BP               ;establish BASIC variable access
    Mov  BP,SP            ;

    Mov  AH,0Fh           ;get video mode in AL
    Int  10h              ;
    Mov  BX,[BP+10]       ;get palette register
    Cmp  AL,0Dh           ;EGA or VGA graphics mode?
    Jb   Done             ;  no, ignore 'em
    Cmp  AL,10h           ;EGA graphics mode?
    Jbe  SetEGA           ;  yep, set it

    Mov  CX,[BP+6]        ;CH = green, CL = red
    Mov  DH,[BP+8]        ;DH = blue
    Xchg CL,DH            ;now CL = blue, DH = red
    Mov  AX,1010h         ;set VGA palette register

Done0:                    ;
    Int  10h              ;

Done:
    Pop  BP               ;
    Ret  6                ;return to caller

SetEGA:
    Mov  BH,6[BP]         ;get color
    Mov  AX,1000h         ;set EGA palette register
    Jmp  Done0            ;

B$PAL2 Endp
End
