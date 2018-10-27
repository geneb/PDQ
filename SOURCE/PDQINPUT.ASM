;********* PDQINPUT.ASM - PDQ replacement for BASIC's INPUT routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn B$PESD:Proc       ;to issue an empty PRINT when done, in PRINT.ASM
    Extrn B$SASS:Proc       ;this is in ASSIGN$.ASM

    MaxLen = 127            ;the length of the longest line allowed, and it
                            ;  must be odd to keep SP even (1 is added below)
.Data
    DescrLen DW 0           ;this is the output descriptor
    DescrAdr DW 0

.Code

PDQInput Proc, Work:Word

    Local Buffer[MaxLen+1]:Byte  ;work area for DOS, (the +1 is for a CR)
    Local StrLength:Word         ;the max and returned length of the string

    Mov  StrLength,MaxLen + 1    ;show DOS the maximum allowable length
    Mov  DX,SP                   ;and where the buffer is (faster than LEA)
    Mov  AH,0Ah                  ;buffered input service
    Int  21h                     ;call DOS to do it

    Mov  Byte Ptr DescrLen,0     ;create a null string 
    Mov  AX,Offset DescrLen      ;this lets PDQInput mimic BASIC's INPUT
    Push AX                      ;this Push is for the assignment below
    Push AX                      ;show B$PESD where the null descriptor is
    Call B$PESD                  ;issue an empty PRINT just like QuickBASIC

    Mov  AX,StrLength            ;get the actual length of the new string
    Mov  Byte Ptr DescrLen,AH    ;assign it to the output descriptor
    Lea  AX,Buffer               ;get the buffer address
    Mov  DescrAdr,AX             ;assign the output descriptor address

;   Mov  AX,Offset DescrLen      ;show B$SASS where the source descriptor is
;   Push AX                      ;(already done above, this is for clarity)
    Mov  AX,Work                 ;and where the destination descriptor is
    Push AX
    Call B$SASS                  ;assign Work$ from the file buffer

    Ret                          ;return to caller

PDQInput Endp
End
