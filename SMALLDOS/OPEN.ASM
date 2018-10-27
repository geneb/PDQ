;********** OPEN.ASM - SMALLDOS version of BASIC's B$OPEN routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$ZeroFile:Proc   ;this is in ZEROFILE.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Extrn P$HandleTbl:Word  ;this is in FHANDLES.ASM

.Code

B$OPEN Proc, File:Word, FileNum:Word, Junk:Word, OpenType:Word

    Local Buffer[80]:Byte ;copy the file name here to add a CHR$(0)

    Mov  AX,File          ;get the address for the file name
    Mov  DX,SP            ;and the address for the start of the buffer
    Call P$ZeroFile       ;this adds a CHR$(0) to the end of the name for DOS
    Mov  P$PDQErr,CX      ;assume no errors (and CX is conveniently zero)

;-- Check the incoming handle, and see if it's valid.
;
    Mov  BX,FileNum       ;get the file number they specified
    Mov  AX,6             ;assume a "Bad file number" error
    Or   BX,BX            ;is it zero?
    Jz   ErrExit          ;yes, go report the error
    Cmp  BX,15            ;no, but is it greater than 15?
    Ja   ErrExit          ;yes, and that's no good either

;-- See what OPEN mode they want.
;
    Mov  AX,OpenType      ;see if they want for INPUT, OUTPUT, or BINARY
    Cmp  AL,1             ;try INPUT first
    Je   DoInput          ;yup, go open for input
    Cmp  AL,20h           ;nope, so let's try BINARY next
    Je   DoBinary         ;that's the ticket, go get 'em
    Cmp  AL,2             ;no, but make sure it's for OUTPUT
    Je   DoOutput         ;okay
    Mov  AX,1             ;no such file mode, make an appropriate error
    Jmp  Short ErrExit    ;and get out

DoOutput:
    Mov  AH,3Ch           ;create/truncate the file
    Mov  CX,100000b       ;create it as an "archive" file
    Int  21h              ;call DOS to do it
    Jc   ErrExit          ;if DOS says there's an error, who am I to argue?

SaveHandle:
    Dec  BX               ;adjust 1-15 to 0-14 for indexing the handle table
    Shl  BX,1               ;adjust to number of words
    Mov  P$HandleTbl[BX],AX ;save the handle DOS returned in the table
    Jmp  Short Exit         ;that's all she wrote

DoInput:
    Mov  AX,3D00h         ;open file for input only service
    Int  21h              ;let DOS handle the dirty stuff
    Jnc  SaveHandle       ;no error, go remember the handle DOS returned
    Jmp  Short ErrExit    ;an error, perhaps the file wasn't there?

DoBinary:
    Mov  AX,3D02h         ;specify open file for read/write access
    Int  21h              ;let DOS handle the dirty stuff
    Jnc  SaveHandle       ;no error, go remember the handle DOS returned

    Cmp  P$PDQErr,0       ;did we arrive here via a critical error?
    Jne  ErrExit          ;yes, so AX is invalid and P$PDQErr is already set
    Cmp  AX,2             ;there was an error, but was it "File not found"?
    Je   DoOutput         ;yes, so go open the file for OUTPUT

ErrExit:
    Call P$DoError        ;handle the error as needed

Exit:
    Ret                   ;return to BASIC

B$OPEN Endp
End
