;********** NUM2HNDL.ASM - converts a file to the appropriate DOS handle

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Extrn P$HandleTbl:Word  ;this is in FHANDLES.ASM

.Code

P$Num2Handle Proc           ;enters and exits with the information in BX
                            ;returns BX = -1 if the file number was invalid
    Mov  SS:P$PDQErr,0      ;assume no errors (but don't assume DS is valid!)
    Or   BX,BX              ;is the handle zero?
    Jz   BadExit            ;yes, get out now

    Cmp  BX,255             ;is it the "reserved" handle of 255 for STDERR?
    Jne  Not255             ;no, keep checking
    Mov  BL,2               ;yes, substitute DOS' STDERR handle (BH is clear)
    Ret                     ;and return to caller

Not255:
    Cmp  BX,15              ;is it greater than 15?
    Ja   BadExit            ;yes, and that's illegal too!
    Dec  BX                 ;no, adjust 1-15 to 0-14 for indexing the table
    Shl  BX,1               ;and adjust to number of words
    
    Mov  BX,SS:P$HandleTbl[BX]  ;get the appropriate handle from the table
    Or   BX,BX                  ;is this handle currently open?
    Jz   BadExit                ;no, exit
    Ret                         ;yes, return to caller

BadExit:
    Mov  BX,-1                  ;force an illegal handle so DOS will report it
    Mov  Byte Ptr SS:P$PDQErr,6 ;also assign the error directly (for FILEATTR)
    Ret                         ;return to caller

P$Num2Handle Endp
End 
