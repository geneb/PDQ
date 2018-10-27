;********* CURSOR.ASM - PDQ alternates for BASIC's B$LOCT routines

;Copyright (c) 1989 Ethan Winer


;This file contains an assortment of cursor handling routines.


.Model Medium, Basic
.Data?
    TopLine DB 1 Dup(?)   ;interprocess communications area
    BotLine DB 1 Dup(?)

.Code

CursorOn Proc

    Call _GetSize         ;let this guy do all the work
    And  TopLine,11111b   ;force a legal value
    Call _SetSize         ;and set it to that value
    Ret                   ;return to caller

CursorOn Endp



CursorOff Proc

    Call _GetSize         ;let this guy do all the work
    Or   TopLine,100000b  ;force an illegal value to turn it off
    Call _SetSize         ;and set it to that value
    Ret                   ;return to caller

CursorOff Endp



CursorSize Proc Uses BX, Start:Word, Stop:Word

    Mov  BX,Start         ;get the address for the top line
    Mov  BX,[BX]          ;put it into BX
    Mov  TopLine,BL       ;and then into local storage
    Mov  BX,Stop          ;ditto for the bottom line
    Mov  BX,[BX]
    Mov  BotLine,BL
    Call _SetSize         ;set the new size
    Ret                   ;return to caller

CursorSize Endp



_GetSize Proc Near Uses AX BX CX DX BP ;get the current cursor size

    Mov  AH,0Fh           ;get the current video page
    Int  10h              ;through the BIOS
    Mov  AH,3             ;get cursor information service
    Int  10h              ;call the BIOS (BP is saved because of old BIOS's)
    Mov  TopLine,CH       ;set the local variables
    Mov  BotLine,CL
    Ret                   ;return to caller

_GetSize Endp



_SetSize Proc Near Uses AX CX BP ;set the cursor size

    Mov  AH,0Fh           ;get the current video page
    Int  10h              ;through the BIOS
    Mov  CH,TopLine       ;get the "passed" parameters
    Mov  CL,BotLine
    Mov  AH,1             ;set cursor size service
    Int  10h              ;call the BIOS
    Ret                   ;return to caller

_SetSize Endp
End
