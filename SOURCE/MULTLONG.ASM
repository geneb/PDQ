;********** MULTLONG.ASM - PDQ replacement for BASIC's B$MUI4 routine

;Copyright (c) 1989 Crescent Software
;Copyright (c) 1989 Schaefer Software, by Robert L. Hummel


;This routine multiplies two long integers.


.Model Medium, Basic
.Code

B$MUI4  PROC    USES DI SI, YHI:WORD, YLO:WORD, XHI:WORD, XLO:WORD

        MOV     AX,[YLO]
        MOV     BX,[XHI]
        MOV     CX,[XLO]
        MOV     DX,[YHI]

        MOV     SI,DX
        MOV     DI,BX
        OR      DI,SI
        JNZ     L1

        MUL     CX
        JMP     SHORT L2
L1:
        MOV     DI,AX
        MUL     BX

        XCHG    AX,SI
        MUL     CX

        ADD     SI,AX
        MOV     AX,DI
        MUL     CX

        ADD     DX,SI
L2:
        RET                          ;return to BASIC holding result in DX:AX

B$MUI4  ENDP
        END
