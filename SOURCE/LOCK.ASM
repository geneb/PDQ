;*********** LOCK.ASM - PDQ replacement for BASIC's B$LOCK routine

;Copyright (c) 1990 Ethan Winer


;This routine services both the LOCK and UNLOCK statements


.Model Medium, Basic
    Extrn B$MUI4: Proc          ;this is in MULTLONG.ASM
    Extrn P$Num2Handle: Proc    ;this is in NUM2HNDL.ASM
    Extrn P$DoError: Proc       ;this is in DOERROR.ASM

.Data?
    RecLength DW 1 Dup (?)      ;this saves the record length (0 = non-random)
    DOSHandle DW 1 Dup (?)      ;this saves the DOS file handle
    
.Data
    Extrn P$PDQErr: Word        ;this is in ERRDATA.ASM
    Extrn P$RecordTbl: Word     ;this is in FHANDLES.ASM
    Extrn P$DOSVer: Word        ;this is in PDQDATA.ASM

.Code

B$LOCK Proc Uses SI DI, FileNum:Word, First:DWord, Last:DWord, Action:Word

    Xor  AX,AX                  ;assume no errors (these two lines actually
    Mov  P$PDQErr,AX            ;  create less code than Mov P$PDQErr,0)

    Sub  Word Ptr First,1       ;decrement the starting offset so locking one
    Sbb  Word Ptr First+2,AX    ;  record locks the correct number of bytes

    Mov  BX,FileNum             ;get the BASIC file number
    Call P$Num2Handle           ;translate it to a DOS handle
    Mov  DOSHandle,BX           ;save the handle for later

    Or   BX,BX                  ;if the handle is invalid it'll be -1
    Mov  AX,6                   ;it was invalid, set a "Bad file number"
    Js   ErrExit2               ;and exit early

    Cmp  Byte Ptr P$DOSVer,3    ;are they running at least DOS 3.0?
    Jb   ErrExit                ;no, set a "Bad file mode" error

    Test Byte Ptr Action,0010b  ;are we locking the entire file?
    Jnz  LockRange              ;no, go lock just the specified range

    Mov  SI,-1                  ;yes, assign SI:DI to -1 (it's okay to tell
    Mov  DI,SI                  ;  DOS to lock past the end of the file)
    Xor  CX,CX                  ;set CX:DX to 0000:0000 to start at the
    Mov  DX,CX                  ;  beginning of the file
    Jmp  Short DoLock           ;go lock it

LockRange:
    Mov  BX,FileNum             ;get the BASIC file number
    Dec  BX                     ;adjust to zero-based
    Shl  BX,1                   ;these are words, not bytes
    Mov  AX,P$RecordTbl[BX]     ;get the record length if appropriate

    Or   AX,AX                  ;is the length zero meaning non-random?
    Jnz  Random                 ;no, go ahead and save it locally
    Inc  AX                     ;yes, convert it to 1 for multiplying below

Random:
    Mov  RecLength,AX           ;save the length for later
    Cwd                         ;convert it to a long integer
    Push DX                     ;pass that on to B$MUI4
    Push AX
    Push Word Ptr Last+2        ;pass the ending offset on too
    Push Word Ptr Last
    Call B$MUI4                 ;this returns the byte offset in DX:AX

    Push DX                     ;save the ending offset for a moment
    Push AX

    Mov  AX,RecLength           ;now calculate the ending offset
    Cwd                         ;convert the record length to a long integer
    Push DX                     ;pass that on to B$MUI4
    Push AX
    Push Word Ptr First+2       ;pass the starting offset
    Push Word Ptr First
    Call B$MUI4                 ;as above

    Pop  DI                     ;retrieve the ending offset, low-byte first
    Pop  SI                     ;then the high-byte
    Sub  DI,AX                  ;convert that to a byte length
    Sbb  SI,DX

    Mov  CX,DX                  ;finally, place the starting offset in CX:DX
    Mov  DX,AX                  ;which is where DOS needs it
    
DoLock:
    Mov  BX,DOSHandle           ;get the DOS file handle
    Mov  AL,Byte Ptr Action     ;see if they're locking or unlocking
    And  AL,1                   ;clear all but the lowest bit
    Mov  AH,5Ch                 ;specify the DOS lock/unlock service
    Int  21h                    ;call DOS to lock the file
    Jnc  Exit                   ;no error, skip over and exit

ErrExit:
    Mov  AX,1                   ;translate the error to "Bad File Mode"
ErrExit2:
    Call P$DoError              ;handle the error as needed

Exit:
    Ret                         ;return to BASIC

B$LOCK Endp
End
