;********** SKIPEOF.ASM - EOF support for OPEN.ASM

;Copyright (c) 1991 Ethan Winer
;With thanks to Bill Hileman for the initial code and idea.

;This routine is called by OPEN.ASM when a file is being opened for APPEND,
;and it checks the last byte in the file to see if it's a CHR$(26) EOF byte.
;If so, it seeks back a byte in the file so the EOF character is overwritten.
;It also checks for multiple EOF characters, and backs up over all of them.


.Model Medium, Basic
.Data?
    ItsyByte DB 1 Dup (?)   ;this receives the last byte in the file

.Code

P$SkipEof Proc

Redo:
    Or   DX,AX              ;is the file empty or are we at the beginning?
    Jz   Exit               ;yes, so we're done

    Mov  CX,-1              ;tell DOS to seek back one byte in the file
    Mov  DX,CX              ;by assigning CX:DX to -1
    Push CX                 ;save the -1 to avoid reloading it again later
    Mov  AX,4201h           ;the DOS "Seek relative to where we are" service
    Int  21h                ;let DOS do it

    Mov  AH,3Fh             ;this is the DOS "Read from a file" service
    Mov  DX,Offset ItsyByte ;show where to place what is read
    Mov  CX,1               ;the number of bytes to read (1)
    Int  21h                ;do it

    Pop  CX                 ;retrieve the -1 (2 bytes vs. 3 to reload it)
    Cmp  ItsyByte,26        ;did we just read an EOF character?
    Jne  Exit               ;no, we're done and DOS is at the end of the file

    Mov  DX,CX              ;seek back one byte, and then do it all again
    Mov  AX,4201h           ;  (this approach detects multiple EOF bytes)
    Int  21h                ;now, the next write will overwrite the EOF byte
    Jmp  Short Redo         ;go see if the previous byte is an EOF too

Exit:
    Ret                     ;return to B$OPEN

P$SkipEof Endp
End
