;******** OPEN.ASM - P.D.Q. replacement for BASIC's OPEN statement

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$ZeroFile:Proc   ;this is in ZEROFILE.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM
    Extrn P$SkipEof:Proc    ;this is in SKIPEOF.ASM

.Data?
    TempLen DW 1 Dup (?)    ;this remembers the random access record length

.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Extrn P$HandleTbl:Word  ;this is in FHANDLES.ASM
    Extrn P$RecordTbl:Word  ;this is in FHANDLES.ASM
    Extrn P$TabTable:Byte   ;this is in FHANDLES.ASM
    Extrn P$DOSVer:Word     ;this is in PDQDATA.ASM

.Code

B$OPEN Proc, File:Word, FileNum:Word, RecLength:Word, OpenType:Word

    Local Buffer[80]:Byte   ;copy the file name here to add a CHR$(0)

    Mov  AX,File            ;get the address for the file name
    Mov  DX,SP              ;and the address for the start of the buffer
    Call P$ZeroFile         ;add a CHR$(0) to the end of the name for DOS

    Mov  P$PDQErr,CX        ;assume no errors (P$ZeroFile leaves CX set to 0)
    Mov  TempLen,CX         ;clear this too while we're at it

;-- Check the incoming BASIC file number, and see if it's valid.
;
    Mov  AX,6               ;assume a "Bad file number" error
    Mov  BX,FileNum         ;get the file number they specified
    Or   BX,BX              ;is it zero?
    Jz   ErrExit            ;yes, go report the error
    Cmp  BX,15              ;no, but is it greater than 15?
    Ja   ErrExit            ;yes, and that's no good either

;-- See if this file number is already in use.
;
    Mov  AX,55              ;assume a "File already open" error
    Dec  BX                 ;adjust 1-15 to 0-14 to access the handle table
    Shl  BX,1               ;times two because the table is words
    Cmp  P$HandleTbl[BX],CX ;is this file already open?  (CX is still zero)
    Jne  ErrExit            ;yes, go tell 'em about it

;-- Get and save the ACCESS and LOCK parameters if they were given
;
GetAccess:
    Mov  AX,OpenType        ;get the access code from the upper byte
    Mov  AL,AH              ;copy to AL where we ultimately need it
    
    And  AH,01110000b       ;isolate the LOCK method, allow inheritance
    And  AL,00000111b       ;isolate the ACCESS mode
    Jz   NoAccess           ;no access was given, skip ahead
    Dec  AL                 ;decrement to what DOS requires (why doesn't
                            ;  BC simply pass the correct value?!!)
NoAccess:
    Or   AL,AH              ;combine the ACCESS and LOCK bits into AL
    Test AL,11111000b       ;were any sharing options specified?
    Jz   DOSVerOkay         ;no, so we don't have to test the DOS version
    
    Cmp  Byte Ptr P$DOSVer,3    ;are we running on DOS 3.00 or higher?
    Jae  DOSVerOkay             ;yes, continue
    Mov  AX,1               ;no, set a "Bad file mode" error
    Jmp  Short ErrExit      ;and exit

;-- See what OPEN mode they want (INPUT, BINARY, OUTPUT, RANDOM, or APPEND).
;
DOSVerOkay:
    Mov  AH,Byte Ptr OpenType   ;load the open type into AH
    Cmp  AH,1                   ;try INPUT first
    Je   DoInput            ;yup, go open for input
    Cmp  AH,20h             ;nope, so let's try BINARY next
    Je   DoBinary           ;that's the ticket, go get 'em
    Cmp  AH,2               ;no, test if it's OUTPUT
    Je   DoOutput           ;okay
    Cmp  AH,4               ;is it RANDOM?
    Je   DoRandom           ;yes
    Cmp  AH,8               ;make sure it's APPEND
    Je   DoBinary           ;and let open for BINARY handle it

BadFileMode:
    Mov  AX,1               ;no such file mode, make an appropriate error
                            ;and drop through (this should never happen)
ErrExit:
    Call P$DoError          ;handle the error as needed
    Jmp  Exit               ;and exit now

DoOutput:
    Cmp  Byte Ptr OpenType,1    ;are they opening for input?
    Je   ErrExit                ;yes, we arrived here via AX = 2 at DoOpen
                                ;return "File not found" and don't create it!
    
    Mov  AX,3C00h           ;create/truncate the file
    Mov  CX,100000b         ;create it as an "archive" file
    Int  21h                ;call DOS to do it
    Jc   ErrExit            ;if DOS says there's an error, who am I to argue?

    Push BX                 ;save the now-zero-based BASIC file number
    Mov  BX,AX              ;copy the handle in AX to BX to close the file
    Mov  AH,3Eh             ;specify the DOS Close file service
    Int  21h                ;close the file
    Pop  BX                     ;retrieve the BASIC file number

    Cmp  Byte Ptr OpenType,2    ;are they opening for output?
    Jne  GetAccess              ;no, so leave the access as it is
    Mov  Byte Ptr OpenType,20h  ;force the open method on the stack to BINARY
    Jmp  Short GetAccess        ;and go through this once again to open the
                                ;  file using the appropriate access method
SaveHandle:
    Mov  P$HandleTbl[BX],AX ;save the handle DOS returned in the table
    Push BX                 ;save the BASIC file number for a moment
    Mov  BX,AX              ;we need BX to address the Tab column table
    Mov  P$TabTable[BX],0   ;reset the Tab column count for this file
    Pop  BX                 ;get the BASIC file number back again
    
    Cmp  TempLen,0          ;was the file just opened for random access?
    Je   Done               ;no, so we're almost finished
    Mov  AX,TempLen         ;yes, get the length back from temporary storage
    Mov  P$RecordTbl[BX],AX ;then save it in the table
    Jmp  Short Exit         ;that's all she wrote

DoInput:
    And  AL,11111000b       ;ensure read-only access
    Jmp  Short DoOpen       ;skip over the Binary access stuff

DoBinary:
    Test Byte Ptr OpenType+1,0111b  ;was an access method given?
    Jnz  DoOpen                     ;yes, go open it using that method
    And  AL,11111110b       ;no, give the program read/write privileges
    Or   AL,00000010b       ;by forcing the lower nybble to 0010b
    
DoOpen:
    Mov  AH,3Dh             ;specify the DOS Open File service
    Int  21h                ;let DOS handle the dirty stuff
    Jnc  SaveHandle         ;no error, go remember the handle DOS returned

    Cmp  P$PDQErr,0         ;did we arrive here via a critical error? 
    Jne  ErrExit            ;yes, so AX is invalid and P$PDQErr is now set
    Cmp  AX,2               ;no, but was the error "File not found"?
    Je   DoOutput           ;yes, so go open the file for OUTPUT
    Jmp  Short ErrExit      ;no, report the error and exit

DoRandom:
    Mov  CX,RecLength       ;get the random access record length
    Jcxz BadFileMode        ;the length was zero, set a "Bad file mode" error
    
    Cmp  CX,-1              ;was a length given? (QB sends -1 if none given)
    Jne  GotLength          ;yes, use the length that was passed
    Mov  CX,128             ;no, so use the default of 128 bytes

GotLength:
    Mov  TempLen,CX         ;save the length until we're sure the file opened
    Jmp  Short DoBinary     ;and let the BINARY code do the actual open

Done:
    Cmp  Byte Ptr OpenType,8    ;see if they want to open for APPEND
    Jne  Exit                   ;no, so we're finished
    
    Mov  BX,AX              ;yes, copy the DOS handle back into BX again
    Xor  CX,CX              ;specify seeking to the end
    Mov  DX,CX              ;using a double-word
    Mov  AX,4202h           ;DOS seek service (relative to the end of file)
    Int  21h                ;let DOS do it

    Call P$SkipEOF          ;call the routine that skips an EOF (or its stub)

Exit:
    Ret                     ;return to BASIC

B$OPEN Endp
End
