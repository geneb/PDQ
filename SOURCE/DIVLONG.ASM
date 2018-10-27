;********** DIVLONG.ASM - PDQ replacement for BASIC's B$DVI4 routine

;Copyright (c) 1989 Crescent Software
;Copyright (c) 1989 Schaefer Software, by Robert L. Hummel


;This routine divides two long integers.


.Model Medium, Basic
.Code

B$DVI4  PROC    USES DI SI, YHI:WORD,YLO:WORD,XHI:WORD,XLO:WORD

                XOR     DI,DI                   ;Init sign change counter
                MOV     AX,[XHI]
                OR      AX,AX
                JGE     L1                      ;Jump if X is non-neg

                INC     DI                      ;One sign change
                MOV     DX,[XLO]                ;Change X to positive number
                NEG     AX
                NEG     DX
                SBB     AX,0

                MOV     [XHI],AX                ;Save altered number
                MOV     [XLO],DX
L1:
                MOV     AX,[YHI]                ;Test Y for sign
                OR      AX,AX
                JGE     L2                      ;Jump if non-negative

                INC     DI                      ;Another sign change
                MOV     DX,[YLO]
                NEG     AX
                NEG     DX
                SBB     AX,0

                MOV     [YHI],AX                ;Save altered number
                MOV     [YLO],DX
L2:
                OR      AX,AX                   ;Long div needed?
                JNZ     L3

                MOV     CX,[YLO]                ;Divide long by short
                MOV     AX,[XHI]
                XOR     DX,DX
                DIV     CX

                MOV     BX,AX
                MOV     AX,[XLO]
                DIV     CX

                MOV     DX,BX
                JMP     SHORT L7



L3:
                MOV     BX,AX                   ;Set up for long divide
                MOV     CX,[YLO]
                MOV     DX,[XHI]
                MOV     AX,[XLO]
L4:
                SHR     BX,1                    ;Loop to get significant
                RCR     CX,1                    ; portions to divide
                SHR     DX,1
                RCR     AX,1
                OR      BX,BX
                JNZ     L4

                DIV     CX                      ;Do the division in parts
                MOV     SI,AX
                MUL     WORD PTR [YHI]

                MOV     CX,AX
                MOV     AX,[YLO]
                MUL     SI

                ADD     DX,CX
                JB      L5

                CMP     DX,[XHI]
                JA      L5
                JB      L6

                CMP     AX,[XLO]
                JBE     L6
L5:
                DEC     SI
L6:
                XOR     DX,DX
                XCHG    AX,SI
L7:
                DEC     DI           ;If 2 sign changes, done
                JNZ     L8

                NEG     DX           ;Change sign
                NEG     AX
                SBB     DX,0
L8:
                RET                  ;return to BASIC holding MOD in DX:AX

B$DVI4          ENDP
                END
