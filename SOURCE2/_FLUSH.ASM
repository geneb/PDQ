;********* _FLUSH.ASM - limited version of Flush, flushes all open files only

;Copyright (c) 1990 Ethan Winer

;See the comments in FLUSH.ASM.


.Model Medium, Basic
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM
    
.Data
    Extrn P$HandleTbl:Word  ;this is in FHANDLES.ASM
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    
.Code

_Flush Proc Uses SI         ;the underscore is for CDECL compatibility

    Mov  P$PDQErr,0         ;assume no errors
    
    Mov  CX,15                  ;flush all possible files (15)
    Mov  SI,Offset P$HandleTbl  ;point to the first entry in the handle table

FlushLoop:
    Mov  BX,[SI]            ;load the current DOS handle
    Or   BX,BX              ;is the file open?
    Jz   Next               ;no, go on to the next file

    Mov  AH,45h             ;service to duplicate a file handle
    Int  21h                ;call DOS to do it
    Jc   Error              ;DOS says an error occurred

    Mov  BX,AX              ;put the new handle into BX
    Mov  AH,3Eh             ;and close the "alias" file
    Int  21h                ;call DOS to do it
    Jc   Error              ;if the carry flag is set, there was an error

Next:
    Inc  SI                 ;go on to the next entry
    Inc  SI                 ;two Inc's is faster and less code than Add SI,2
    Loop FlushLoop          ;until all open files have been flushed
    Jmp  Short Exit         ;bye

Error:
    Call P$DoError          ;handle the error as necessary

Exit:
    Ret                     ;return to BASIC


_Flush Endp
End
