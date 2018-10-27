;********** RESET.ASM - SMALLDOS replacement for BASIC's B$REST routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM
    
.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Extrn P$HandleTbl:Word  ;this is in FHANDLES.ASM

.Code

B$REST Proc Uses SI

    Xor  DX,DX              ;make a zero for repeated use below
    Mov  P$PDQErr,DX        ;assume no errors
    Mov  SI,14 * 2          ;do this 15 times (including table entry zero)

More:
    Mov  CX,P$HandleTbl[SI] ;get this DOS handle from the table
    Jcxz Next               ;if it's zero, then it was never opened
    Mov  P$HandleTbl[SI],DX ;it was open, zero out this entry in the table
    Mov  BX,CX              ;copy the file handle to BX for service 3Eh below
    Mov  AH,3Eh             ;close file service
    Int  21h                ;call DOS to actually do it
    Jnc  Next               ;no carry means no error
    Call P$DoError          ;handle the error as needed
    Ret                     ;and bag out ASAP like QuickBASIC does

Next:
    Dec  SI                 ;go to the preceding table entry
    Dec  SI
    Jns  More               ;loop until done
    Ret                     ;return to BASIC

B$REST Endp
End
