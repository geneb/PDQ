;********** PRNHANDL.ASM - PDQ replacement for BASIC's B$CHOU routine

;Copyright (c) 1989 Ethan Winer

;This routine handles BASIC's PRINT #n, statement.  It simply assigns the
;BASIC print "handle" to the specified file number for the next time any of
;the PRINT routines are called.

;----------------------------------------------------------------------
; 1/3/90    .001    Split out B$DSKI (rlh)
;----------------------------------------------------------------------

.Model Medium, Basic
    Extrn P$Num2Handle:Proc      ;this is in NUM2HNDL.ASM
    
.Data
    Extrn P$PrintHandle:Word     ;this is in PHANDLE.ASM

.Code

B$CHOU Proc, FileNum:Word        ;directs the next PRINT to a specific handle

    Mov  BX,FileNum              ;get the file number they passed us
    Call P$Num2Handle            ;translate it to a DOS handle
    Mov  P$PrintHandle,BX        ;and assign it where B$PSSD can find it
    Ret                          ;return to BASIC

B$CHOU Endp
End
