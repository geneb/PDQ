;********** CURSORSR.ASM - save/restore the current cursor state

;Copyright (c) 1990 Crescent Software
;written by Paul Passarelli

;Syntax:
;   SaveInfo& = CursorSave&     'save the current row, col, and size
;   CALL CursorRest(SaveInfo&)  'restore the saved cursor conditions

.Model Medium, BASIC
.Code

CursorSave Proc

    Mov  AH,15          ;select get current video page service
    Int  10h            ;use the BIOS video service
    Mov  AH,3           ;service to read cursor position and scan line info
    Int  10h           
    Mov  AX,CX          ;return as a long integer (DX is already set)
    Ret
    
CursorSave Endp


CursorRest Proc Info:Word

    Mov  BX,Info        ;retrieve the pointer
    Mov  CX,[BX]        ;the low word holds the scan line info
    Mov  DX,[BX+02]     ;and the high word holds the row and column

    Mov  AH,15          ;select get current video mode sub service
    Int  10h            ;use the video service
    Mov  AH,2           ;set the row and column first
    Int  10h
    Mov  AH,1           ;and then the scan line height
    Int  10h
    Ret                 ;back to BASIC
    
CursorRest Endp
End
