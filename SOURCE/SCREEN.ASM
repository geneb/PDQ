;********* SCREEN.ASM - PDQ replacement for BASIC's B$FSCN routine

;Copyright (c) 1989 Ethan Winer


;This routine serves as the function form of the SCREEN statement.


.Model Medium, Basic
    Extrn CursorSave:Proc   ;this is in CURSORSR.ASM
    Extrn CursorRest:Proc   ;this is in CURSORSR.ASM

.Data?
    SaveSize DW 1 Dup(?)    ;save the cursor size here before changing it
    SaveLoc  DW 1 Dup (?)   ;and save the location here

.Code

B$FSCN Proc, Row:Word, Column:Word, Action:Word

    Call CursorSave         ;first save the current cursor location and size
    Mov  SaveSize,AX
    Mov  SaveLoc,DX
    
    Mov  DL,Byte Ptr Column ;put the column into DX (DL really)
    Dec  DL                 ;adjust 1-80 to 0-79
    Mov  DH,Byte Ptr Row    ;now get the incoming row
    Dec  DH                 ;adjust 1-25 to 0-24
    
    Mov  AH,2               ;move the cursor there
    Push BP                 ;some old PC BIOS's trash BP during Int 10h
    Int  10h

    Mov  AH,8               ;now read the character and color at the cursor
    Int  10h                ;BIOS returns the character in AL, color in AH
    Pop  BP                 ;get BP back again
    
    Cmp  Byte Ptr Action,0  ;see if they want the character or the color
    Jz   Character          ;if it's zero, they want the character
    Mov  AL,AH              ;put the color into AL

Character:
    Mov  AH,0               ;clear AH so we can return all of AX

SetCursor:
    Push AX                 ;save the function result for a moment
    Mov  AX,Offset SaveSize ;show CursorRest where the saved information is
    Push AX
    Call CursorRest         ;restore the original cursor location and size
    Pop  AX                 ;get the result back
    Ret                     ;return to caller

B$FSCN Endp
End
