;********* FRE.ASM - PDQ replacement for BASIC's B$FRI2 routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data?
    Extrn PDQ_Stack_Foot:Byte  ;this is in PDQ.ASM

.Data
    Extrn P$BytesFree:Word     ;this is in STR####.ASM

.Code

B$FRI2 Proc, Action:Word

    Xor  DX,DX            ;FRE returns a long integer output result, clear DX
    Mov  AX,P$BytesFree   ;assume they want the amount of free string space
    Cmp  Action,DX        ;do they?
    Jge  Exit             ;yes, so we're all done

    Inc  Action           ;if this results in 0, then they wanted FRE(-1)
    Jnz  DoStack          ;it wasn't -1, so go do FRE(-2)
    Mov  AH,48h           ;it was -1, ask DOS for that value
    Mov  BX,-1            ;by requesting an illegally large block
    Int  21h              ;call DOS
    Mov  AX,BX            ;transfer the number of free paragraphs into AX
    Mov  CX,16            ;multiply that times 16 to get the number of bytes
    Mul  CX               ;now DX:AX holds the available bytes in far memory
    Jmp  Short Exit       ;all done

DoStack:
    Mov  AX,SP            ;calculate the free stack space
    Sub  AX,Offset PDQ_Stack_Foot

Exit:
    Ret                   ;return to caller

B$FRI2 Endp
End
