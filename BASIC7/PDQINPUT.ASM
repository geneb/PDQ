;********* PDQINPUT.ASM - PDQ replacement for BASIC's INPUT routine

;Copyright (c) 1989 Ethan Winer
;BC7 conversion  3/90 J.Munro

.Model Medium, Basic
    Extrn B$PESD:Proc       ;to issue an empty PRINT when done, in PRINT.ASM
    Extrn B$SAS1:Proc       ;this is in ASSIGN$.ASM
    Extrn StringAssign:Proc ;this is an internal BASIC 7 routine

    MaxLen = 127            ;the length of the longest line allowed, and it
                            ;  must be odd to keep SP even (1 is added below)
.Data
    DescrLen DW 0           ;this is the output descriptor
    DescrAdr DW 0
    NullSpace DW 0

.Code

PDQInput Proc, Work:Word

    Local Buffer[MaxLen+1]:Byte  ;work area for DOS, (the +1 is for a CR)
    Local StrLength:Word         ;the max and returned length of the string

    Mov  StrLength,MaxLen + 1    ;show DOS the maximum allowable length
    Mov  DX,SP                   ;and where the buffer is (faster than LEA)
    Mov  AH,0Ah                  ;buffered input service
    Int  21h                     ;call DOS to do it

    Push ES
    Push DS
    Mov  AX,Offset NullSpace
    Push AX
    Xor  BX,BX
    Push BX
    Push DS
    Mov  AX,Offset DescrLen
    Push AX
    Push BX
    Call StringAssign

    Pop  ES
    Mov  AX,Offset DescrLen      ;this lets PDQInput mimic BASIC's INPUT
    Push AX                      ;show B$PESD where the null descriptor is
    Call B$PESD                  ;issue an empty PRINT just like QuickBASIC

    Push ES
    Mov  AX,StrLength            ;get the actual length of the new string
    Xor  AL,AL                   ;clear low byte
    Xchg AL,AH                   ;put length into lo byte
    Push SS                      ;push segment for string assign
    Lea  BX,Buffer               ;get address of buffer
    Push BX                      ;push that
    Push AX                      ;push actual length of string
    Push DS
    Mov  AX,Offset DescrLen
    Push AX
    Xor  AX,AX
    Push AX
    Call StringAssign
    Pop  ES

    Mov  AX,Offset DescrLen      ;show B$SASS where the source descriptor is
    Push AX
    Mov  AX,Work                 ;and where the destination descriptor is
    Push AX

    Call B$SAS1                  ;assign Work$ from the file buffer

    Ret                          ;return to caller

PDQInput Endp
End
