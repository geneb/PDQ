;********** CLOSE.ASM - PDQ replacement for BASIC's B$CLOS routine

;Copyright (c) 1989 Ethan Winer


;This routine is called from BASIC with a varying number of parameters
;using the following pseudo-code method:
;
;CALL B$CLOS(BYVAL File1, BYVAL File2, ... BYVAL NumFilesPreceding)
;
;CLOSE results in PUSH 0: CALL B$CLOS
;CLOSE #3 results in PUSH 3: PUSH 1: CALL B$CLOS
;CLOSE #4, #6 results in PUSH 4: PUSH 6: PUSH 2: CALL B$CLOS


.Model Medium, Basic
    Extrn B$REST: Proc        ;this is in RESET.ASM
    Extrn P$CloseField:Proc   ;this is in FIELD2.ASM
    Extrn P$DoError: Proc     ;this is in DOERROR.ASM
    Extrn P$Num2Handle: Proc  ;this is in NUM2HNDL.ASM

.Data
    Extrn P$HandleTbl:Word    ;this is in FHANDLES.ASM
    Extrn P$RecordTbl:Word    ;this is in FHANDLES.ASM

.Code

B$CLOS Proc, NumFiles

    Xor  DX,DX            ;make a zero for repeated use below
    Mov  CX,NumFiles      ;see how many files are to be closed
    Jcxz GoReset          ;all of them
    Add  BP,6             ;one or more, skip the number of files parameter

    Mov  BX,CX            ;copy the parameter for self-modifying the code
    Inc  BX               ;the Ret value is one more than the number of files
    Shl  BX,1                   ;we really need two bytes per parameter
    Mov  Word Ptr CS:Patch,BX   ;patch the code as needed

MainLoop:
    Add  BP,2             ;point BP to the next higher parameter on the stack
    Mov  BX,[BP]          ;get the file number

    Shl  BX,1             ;convert to a word for access to the handle table
    Cmp  Word Ptr P$HandleTbl[BX-2],0   ;is the file open? (-2 cuz zero-based)
    Je   Skip                           ;no, so don't try to close it
    Shr  BX,1                           ;convert BX back to a byte
    
    Call P$CloseField     ;close down any active FIELD statements
    Call P$Num2Handle     ;translate to a DOS handle, returns -1 if invalid

    Mov  AH,3Eh           ;close file service
    Int  21h              ;call DOS to actually do it
    Jnc  ClearEntry       ;no error, skip ahead and clear the handle entry
    Call P$DoError        ;handle the error as needed
    Jmp  Short Exit       ;and get out

ClearEntry:
    Mov  BX,[BP]          ;get the file number again
    Dec  BX               ;adjust 1-15 to 0-14 for indexing the handle table
    Shl  BX,1             ;convert bytes to words
    Mov  Word Ptr P$HandleTbl[BX],DX ;show this handle being no longer in use
    Mov  Word Ptr P$RecordTbl[BX],DX ;clear the record length indicator too
Skip:
    Loop MainLoop                    ;continue until all files are closed

Exit:
    Pop  BP               ;we have to do this manually folks
    Db   0CAh             ;this is the opcode for Ret n, modified as needed
Patch DW 4                ;assume 2 arguments (Ret 4)

GoReset:
    Call B$REST           ;they want to close everything, so let RESET do it
    Ret  2                ;return to BASIC

B$CLOS Endp
End
