;********* BUFOUT.ASM - buffered output routine, complements BufIn$

;Copyright (c) 1991 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


;Syntax:
;
;  CALL BufOut(FileName$, Text$, Terminator$)
;
;Where:
;
;  FileName$ is the file name, or a null string to close the file when done.
;
;  Text$ is the text to be written to the file.
;
;  Terminator$ is a string used to end the current line, and is typically
;  set to CHR$(13) + CHR$(10).
;
;Note:
;
;  No single line of text may exceed 4096 characters in length.  If a single
;  line exceeds 4096 bytes the excess will be truncated.  This maximum length
;  does not include the optional terminator, which is handled separately.
;
;See BufOut in PDQSUBS.BAS for a clearer overview of how this program works.


.Model Medium, Basic
    BufSize = 4096          ;sets the buffer size, -must- be a multiple of 16

    Extrn P$FixStr:Proc         ;this is in FIXSTR.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM
    Extrn P$ZeroFile:Proc   ;this is in ZEROFILE.ASM

.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Handle  DW 0            ;this remembers the DOS file handle

.Data?
    BufSeg  DW 1 Dup (?)    ;this remembers the buffer's data segment
    Pointer DW 1 Dup (?)    ;this tracks where we are in the buffer

.Code

BufOut Proc Uses SI DI, FileName$:Word, Text$:Word, Term$:Word

    Local FileZ[80]:Byte    ;copy the file name here to add a CHR$(0)

    Push FileName$        ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  FileName$,AX     ;

    Push Text$            ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Text$,AX         ;

    Push Term$            ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Term$,AX         ;

    Sub  AX,AX              ;make a zero as efficiently as possible
    Mov  P$PDQErr,AX        ;assume no errors

    Mov  BX,FileName$       ;get the address of the descriptor for FileName$

    Cmp  Handle,AX          ;is the file currently active?
    Je   OpenFile           ;no, go open the file

    Cmp  [BX],AX            ;do they want to close the file?
    Jne  PutIt              ;no, continue and put the data into the buffer

    Call FlushIt            ;yes, flush the current buffer contents to disk
    Mov  BX,Handle          ;then get the file handle
    Mov  AH,3Eh             ;DOS close file service
    Int  21h                ;close the file
    Jc   ErrorExit          ;bomb if we can't close the file!

    Mov  Handle,0           ;clear the file handle which also acts as a flag

    Mov  ES,BufSeg          ;show DOS where the buffer is located
    Mov  AH,49h             ;DOS release memory service
    Int  21h                ;release the memory
    Jmp  Short ExitSub      ;and exit

PutIt:                      ;put the text into the output buffer
    Mov  BX,Text$           ;get the descriptor address for Text$
    Call AddIt              ;and add it into the output buffer
    Mov  BX,Term$           ;then get the address for the terminator string
    Call AddIt              ;and add that into the buffer as well

ExitSub:
    Ret                     ;all done, return to BASIC

OpenFile:
    Mov  AX,BX              ;put address of FileName$ where ZeroFile needs it
    Lea  DX,FileZ           ;load the address of the local file name buffer
    Call P$ZeroFile         ;this copies and adds a CHR$(0) for DOS

    Mov  AH,3Ch             ;DOS create/truncate file service
    Mov  CL,32              ;create it with an Archive attribute (CH = zero)
    Int  21h                ;ask DOS to open the file for output mode
    Jnc  @F                 ;no carry, no error

ErrorExit:
    Call P$DoError          ;there was an error, register it with ERR
    Jmp  Short ExitSub      ;then exit

@@:
    Mov  Handle,AX          ;save the file handle returned after creation

    Mov  BX,BufSize / 16    ;allocate BufSize 16-byte paragraphs of memory
    Mov  AH,48h             ;DOS allocate memory service
    Int  21h                ;call DOS to do the hard stuff
    Jnc  @F                 ;no carry, no error

    Mov  Byte Ptr P$PDQErr,7    ;assign an "Out of memory" error manually
    Jmp  Short ErrorExit    ;call P$DoError and exit

@@:
    Mov  BufSeg,AX          ;save the buffer segment DOS just allocated
    Mov  Pointer,1          ;initialize the buffer pointer
    Jmp  Short PutIt        ;jump into the buffer assignment

BufOut Endp



AddIt Proc Near             ;adds string whose descriptor is in BX to buffer

    Mov  CX,[BX]            ;load the length of this string
    Jcxz ExitAdd            ;a null string, skip all this nonsense

    Mov  AX,BufSize         ;see if Length > BufSize - Pointer + 1
    Sub  AX,Pointer
    Inc  AX

    Cmp  CX,AX              ;will this string fit in the buffer?
    Jbe  @F                 ;it will fit, continue
    Call FlushIt            ;it will not fit, flush we have now

@@:                         ;copy the current text into the buffer
    Mov  ES,BufSeg          ;load the buffer segment
    Mov  DI,Pointer         ;and the next available address within the buffer
    Dec  DI                 ;less 1 because Pointer is 1-based

    Mov  SI,[BX+02]         ;load the starting address of the text into SI
    Cmp  CX,BufSize         ;is the string longer than BufSize?
    Jbe  @F                 ;no, continue
    Mov  CX,BufSize         ;yes, throw away the excess (we warned you!)

@@:
    Add  Pointer,CX         ;update the pointer before losing CX
    Cld                     ;ensure that string copying is forward
    Rep  Movsb              ;copy the text into the buffer

ExitAdd:
    Ret                     ;return to caller

AddIt Endp



FlushIt Proc Near Uses BX CX    ;flushes the current buffer contents to disk

    Mov  BX,Handle          ;load the DOS file handle
    Mov  CX,Pointer         ;show DOS how many bytes to write to disk
    Dec  CX                 ;less one because Pointer is 1-based
    Sub  DX,DX              ;the buffer starts at address zero

    Push DS                 ;save DS for a moment
    Mov  DS,BufSeg          ;show DOS the segment we're writing from
    Mov  AH,40h             ;DOS write file service
    Int  21h                ;write the data at DS:DX to disk
    Pop  DS                 ;restore DS
    Jnc  @F                 ;no error, no problem

    Call P$DoError          ;register the error with ON ERROR if appropriate
    Ret                     ;and leave Pointer where it is in case they
                            ;  want to try again a second time
@@:
    Mov  Pointer,1          ;reset Pointer to the start of the buffer
    Ret                     ;return to caller

FlushIt Endp
End
