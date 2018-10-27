;********* ERR.ASM - PDQ replacement for BASIC's B$FERR routine

;Copyright (c) 1989 Ethan Winer

;See the discussion about the error values in the ERRDATA.ASM file.


.Model Medium, Basic
.Data
    Extrn P$PDQErr:Word     ;these are in ERRDATA.ASM
    Extrn P$ErrorTbl:Byte

.Code

B$FERR Proc

    Mov  BX,P$PDQErr        ;get the error value
    Or   BX,BX              ;is it a special error with a negative value?
    Jns  NormalErr          ;no, handle it normally
    Dec  BX                 ;yes, bump *backwards* over the P$PDQErr variable
    
NormalErr:
    Cmp  BL,15              ;but it might be DOS' "Device unavailable error"
    Jne  NotDevice          ;it's not, continue
    Mov  BL,68              ;it is, substitute BASIC's number for that error

NotDevice:
    Cmp  BL,6               ;is it a native DOS error?
    Jg   Done               ;no, so it's already correct

    Dec  BX                 ;adjust to zero-based
    Mov  BL,P$ErrorTbl[BX]  ;get it from the table

Done:
    Mov  AL,BL              ;return the error in AX for the function output
    Cbw                     ;using a full word
    Ret                     ;return to BASIC

B$FERR Endp
End
