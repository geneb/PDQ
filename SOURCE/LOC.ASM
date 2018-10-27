;********* LOC.ASM - PDQ replacement for BASIC's B$FLOC and B$FSEK routines

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$Num2Handle:Proc ;this is in NUM2HNDL.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Data
    Extrn P$RecordTbl:Word  ;this is in FHANDLES.ASM
    LocType DW 0            ;this is 1 if called as SEEK, 0 if called as LOC
                            ;  (it fudges the output value as needed)
.Code

B$FSEK Proc                 ;this is called when the SEEK function is used
    Inc  LocType            ;show that we're doing a SEEK rather than a LOC
B$FSEK Endp                 


B$FLOC Proc, FileNum:Word   ;this is called when the LOC function is used

    Mov  BX,FileNum         ;get the file number
    Call P$Num2Handle       ;translate it to a DOS handle

    Xor  CX,CX              ;set the file pointer 0 bytes from where it is now
    Mov  DX,CX              ;CX holds the high word, DX holds the low word
    
    Mov  AX,4201h           ;Move File Pointer service relative to current LOC
    Int  21h                ;call DOS
    Jnc  Done               ;no carry, no problem

    Call P$DoError          ;handle the error as needed
    Xor  AX,AX              ;return zero for the function output
    Cwd                     ;as a long integer
    Jmp  Short Exit         ;and exit

Done:
    Mov  BX,FileNum         ;get the file number again
    Dec  BX                 ;convert to zero-based to access P$RecordTbl
    Shl  BX,1               ;address P$RecordTbl as words instead of bytes
    Mov  CX,P$RecordTbl[BX] ;get the record length (non-zero only if random)
    Jcxz FudgeIt            ;it's not a random file, so we're nearly done
    Div  CX                 ;it is a random file, compute the record number
    Cwd                     ;convert to a double word

FudgeIt:
    Add  AX,LocType         ;convert DOS' 0-based method to BASIC's 1-based
    Adc  DX,0               ;  if we were called via the SEEK function

Exit:
    Mov  LocType,0          ;clear this for next time
    Ret                     ;return to BASIC

B$FLOC Endp
End
