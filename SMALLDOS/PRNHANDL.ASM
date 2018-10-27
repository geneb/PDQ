;********* PRNHANDL.ASM - PDQ SMALLDOS replacement for BASIC's B$CHOU routine

;Copyright (c) 1989 Ethan Winer


;This routine handles BASIC's PRINT #n, statement.  It simply assigns the
;BASIC print "handle" to the specified file number for the next time any of
;the PRINT routines are called.

.Model Medium, Basic
    Extrn P$Num2Handle:Proc      ;this is in NUM2HNDL.ASM
    
.Data
    Extrn P$PrintHandle:Word     ;this is in PHANDLE.ASM

.Code

B$DSKI Proc                      ;B$DSKI does the same thing as B$CHOU in 
B$DSKI Endp                      ;  this SMALLDOS version of P.D.Q.

B$CHOU Proc, FileNum:Word        ;directs the next PRINT to a specific handle

    Mov  BX,FileNum              ;get the file number they passed us
    Call P$Num2Handle            ;translate it to a DOS handle
    Mov  P$PrintHandle,BX        ;and assign it where B$PSSD can find it
    Ret                          ;return to BASIC

B$CHOU Endp
End
