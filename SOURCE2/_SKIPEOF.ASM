;********* _SKIPEOF.ASM - stub file removes EOF checking with OPEN FOR APPEND

;Copyright (c) 1991 Ethan Winer

.Model Medium, Basic
.Code

P$SkipEof Proc

    Ret                     ;return to OPEN without doing anything

P$SkipEof Endp
End
