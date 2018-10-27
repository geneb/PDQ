;********* BUFIN.ASM - performs very fast buffered sequential file input

;Copyright (c) 1990 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support

;DECLARE FUNCTION BufIn$ (FileName$, Done)
;DO
;  This$ = BufIn$(FileName$, Done)      'read the file
;  PRINT This$
;LOOP UNTIL Done                        'until Done
;
;Or use this for less compiler-generated code:
;
;DECLARE FUNCTION BufIn% (FileName$, Done)
;DECLARE SUB Assign ALIAS "B$SASS" (BYVAL SourceAddress%, Destination$)
;DO
;  Assign BufIn%(FileName$, Done), This$
;  PRINT This$
;LOOP UNTIL Done
;
;To close a file and terminate reading prematurely, call BufIn again with a
;null string for FileName$.
;
;To aid understanding how this works, the original BASIC source code from
;PDQSUBS.BAS is included as comments.


.Model Medium, Basic
    BufMax = 4096               ;maximum buffer size, MUST be multiple of 16!

    Extrn P$FixStr:Proc         ;this is in FIXSTR.ASM
    Extrn B$CPI4:Proc           ;this is in COMPARE4.ASM
    Extrn B$STRI:Proc           ;this is in STRING$.ASM

    Extrn P$DoError:Proc        ;this is in DOERROR.ASM
    Extrn P$MakeTemp:Proc       ;this is in MAKETEMP.ASM
    Extrn P$ZeroFile:Proc       ;this is in ZEROFILE.ASM

.Data?
    BufPos    DW 1 Dup (?)      ;this tracks where we are in the buffer
    BufSeg    DW 1 Dup (?)      ;this remembers the buffer segment
    BufSize   DW 1 Dup (?)      ;this tracks the current buffer size
    Handle    DW 1 Dup (?)      ;saves the DOS file handle
    Remaining DW 2 Dup (?)      ;tracks what remains to be read, long integer
    Remain2   DW 2 Dup (?)      ;ditto, but used differently

.Data
    Extrn     P$PDQErr:Word     ;this is in ERRDATA.ASM
    SaveCR    DW 1 Dup (?)      ;saves where prior carriage return was found
    Reading   DB 0              ;tracks if we're currently reading
    CR        DB 0              ;remembers if we found a carriage return

.Code

BufIn Proc Uses DI, FileName:Word, Done:Word

    Local NameBuffer[80]:Byte   ;copy file name here to add a CHR$(0)

;IF LEN(FileName$) = 0 GOTO ExitFn
    Push FileName         ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  FileName,AX      ;

    Mov  BX,FileName            ;see if they want to close the file
    Cmp  Word Ptr [BX],0        ;do they?
    Jnz  @F                     ;no, continue
    Jmp  ExitFn                 ;yes, go close the file and free up memory

@@:
;IF Reading GOTO Process
    Cmp  Reading,0              ;are we reading?
    Jz   @F                     ;no, open the file
    Jmp  Process                ;yes, jump into the processing loop below

@@:
;Reading = -1
    Mov  Reading,-1             ;show that we are now reading the file

;Done = 0                       ;also copy the file name to local storage
    Mov  AX,FileName            ;get the address for the file name
    Lea  DX,NameBuffer          ;get the address for the start of the buffer

    Call P$ZeroFile             ;this copies and adds a CHR$(0) for DOS
    Mov  P$PDQErr,CX            ;assume no errors (and CX is known zero)
    Mov  BX,Done                ;clear the Done flag while a zero is handy
    Mov  [BX],CX

;CR$ = CHR$(13)                 ;not needed in this assembly implementation

;FileNum = FREEFILE
;OPEN FileName$ FOR BINARY AS #FileNum
    Lea  DX,NameBuffer          ;show DOS where the ASCIIZ file name is
    Mov  AX,3D00h               ;specify opening for read-only access
    Int  21h                    ;ask DOS to open the file
    Jnc  @F                     ;no carry no error
    Call P$DoError              ;there was an error, register it with ERR
    Jmp  ErrExit                ;clear the flags and exit

@@:
    Mov  Handle,AX              ;save the file handle DOS issued
    Mov  AL,2                   ;seek to the end to see how long the file is
    Call DoSeek

;Remaining& = LOF(FileNum)
    Mov  Remaining,AX           ;save the returned length
    Mov  Remaining+2,DX
    Mov  Remain2,AX             ;save another copy too
    Mov  Remain2+2,DX
    Mov  AL,0                   ;now seek back to the beginning of the file
    Call DoSeek

;IF Remaining& = 0 GOTO ExitFn
    Mov  AX,Remaining           ;see if Remaining is zero
    Or   AX,Remaining+2
    Jnz  @F                     ;no, skip ahead
    Jmp  ExitFn                 ;yes, close the file, clear the flags, exit

@@:
;BufSize = 4096
    Mov  BufSize,BufMax         ;assume a full BufSize bytes

;Buffer$ = SPACE$(BufSize)
    Mov  BX,BufMax / 16         ;request BufMax / 16 paragraphs of DOS memory
    Mov  AH,48h                 ;DOS allocate memory service
    Int  21h                    ;call DOS to do the hard stuff
    Jnc  @F                     ;no carry, no error
    Mov  Byte Ptr P$PDQErr,7    ;assign an "Out of memory" error
    Call P$DoError              ;let P$DoError see if ON ERROR is in effect
    Jmp  ExitFn                 ;and then go away

@@:
    Mov  BufSeg,AX              ;save the returned segment locally

;DO
OuterDo:
  ;IF Remaining& < BufSize THEN
    Cmp  Remaining+2,0          ;anything in the high word?
    Jne  GetIt                  ;yes, so Remaining& can't be less
    Mov  AX,Remaining           ;get the low word
    Cmp  AX,BufSize             ;now compare the low word
    Jae  GetIt                  ;Remaining is not less

     ;BufSize = Remaining&
    Mov  BufSize,AX

     ;IF BufSize < 1 GOTO ExitFn (happens only if there's an EOF mark)
    Cmp  BufSize,1
    Jae  GetIt
    Jmp  ExitFn

     ;Buffer$ = SPACE$(BufSize) ;this is not needed in this assembler version
  ;END IF

GetIt:
  ;GET #FileNum, , Buffer$
    Mov  AH,3Fh                 ;specify the DOS read file service
    Mov  BX,Handle              ;get the DOS file handle to read from
    Mov  CX,BufSize             ;specify reading BufSize bytes
    Xor  DX,DX                  ;DOS segments always start at address 0
    Push DS                     ;save DS for a moment
    Mov  DS,BufSeg              ;DOS reads the data into DS:DX
    Int  21h                    ;do it
    Pop  DS                     ;restore DS

    Sub  Remain2,AX             ;show we read AX bytes from the file
    Sbb  Remain2+2,0

  ;BufPos = 1
    Xor  AX,AX                  ;begin scanning at the start of the buffer
    Mov  BufPos,AX              ;in assembly language zero-based makes sense

  ;DO
InnerDo:
    ;CR = INSTR(BufPos, Buffer$, CR$)
    Mov  CX,BufSize             ;calculate the number of bytes left to search
    Sub  CX,BufPos              ;by subtracting where we were last
    Mov  CR,0                   ;assume no carriage return will be found
    Jcxz NoCR                   ;CX was zero so Repne never executed!

    Mov  BX,CX                  ;save the number of bytes to scan in BX too
    Mov  DI,BufPos              ;point DI to the start of the string
    Mov  ES,BufSeg              ;Scas uses ES:DI to show where the string is
    Mov  AL,13                  ;we're searching for a CHR$(13)
    Repne Scasb                 ;search for the character

    ;IF CR THEN
    Jne  NoCR                   ;there is no carriage return
    Jcxz NoCR                   ;it was found, but at the last byte!
    Mov  CR,-1                  ;a carriage return was found, remember that

       ;SaveCR = CR
    Dec  DI                     ;show where it lies in the buffer
    Mov  SaveCR,DI              ;and save that for later

       ;BufIn$ = MID$(Buffer$, BufPos, CR - BufPos)
    Sub  BX,CX                  ;set BX to the length of this string
    Mov  CX,BX                  ;we need the length in CX for P$MakeTemp
    Dec  CX                     ;don't include the carriage return itself!
    Call MakeString             ;claim pool memory and copy the buffer there

       ;BufPos = CR + 2
    Mov  BX,SaveCR
    Inc  BX
    Inc  BX
    Mov  BufPos,BX

       ;EXIT FUNCTION
Bye:
    Ret                         ;return to BASIC

    ;ELSE
NoCR:
       ;IF SEEK(FileNum) >= LOF(FileNum) THEN      'if at the end with no CR
    Mov  AX,Remain2
    Or   AX,Remain2+2
    Jnz  NotEOF
          ;Output$ = MID$(Buffer$, SaveCR + 2)     'return only what remains
    Mov  CX,BufSize             ;calculate the length of the string to return
    Sub  CX,BufPos
    Jz   Null

          ;IF RIGHT$(Output$, 1) = CHR$(26) THEN   'trap a trailing CHR$(26)
             ;Output$ = LEFT$(Output$, LEN(Output$) - 1)
    Mov  BX,CX                  ;save a copy of CX
    Mov  AL,26                  ;see if there's a CHR$(26) hanging around
    Mov  DI,BufPos              ;reload DI with the current buffer address
    Repne Scasb
    Jne  @F                     ;no 26 here, continue
    Sub  BX,CX                  ;yes, set BX to the revised length

@@:
    Mov  CX,BX                  ;copy the length to CX for P$MakeTemp
    Dec  CX                     ;don't include the carriage return
Null:
    Call MakeString             ;claim pool memory and copy the buffer there
          ;END IF
          ;BufIn$ = Output$
          ;GOTO ExitFn
    Jmp  Short Bye
       ;END IF

NotEOF:
       ;Slop = BufSize - SaveCR - 1
    Mov  DX,BufSize             ;use DX to hold Slop%
    Sub  DX,SaveCR
    Dec  DX
    Dec  DX                     ;the extra Dec is because this is zero-based
    Jz   Process                ;the CRLF was at the end of the buffer!

@@:
       ;Remaining& = Remaining& + Slop
    Xor  AX,AX
    Add  Remaining,DX
    Adc  Remaining+2,AX
    Add  Remain2,DX
    Adc  Remain2+2,AX

       ;SEEK #FileNum, SEEK(FileNum) - Slop
    Mov  CX,-1                  ;DOS expects -Slop in CX:DX
    Neg  DX
    Mov  AL,1                   ;seek relative to the current location
    Call DoSeek2

    ;END IF

Process:
  ;LOOP WHILE CR                ;while there's still a CR in the buffer
    Cmp  CR,0
    Je   @F
    Jmp  InnerDo

@@:
  ;Remaining& = Remaining& - BufSize
    Mov  AX,BufSize
    Sub  Remaining,AX
    Sbb  Remaining+2,0

;LOOP WHILE Remaining&          ;while there's more to read in the file
    Mov  AX,Remaining
    Or   AX,Remaining+2
    Jz   @F
    Jmp  OuterDo

@@:
ExitFn:
;CLOSE #FileNum                 ;final clean-up
    Cmp  Reading,0              ;be sure we really are reading in case they
    Jne  @F                     ;  are calling originally with FileName$ = ""
    Mov  Handle,-1              ;force a bad handle to create an error below

@@:
    Mov  BX,Handle              ;close the file
    Mov  AH,3Eh
    Int  21h

    Mov  ES,BufSeg              ;put the segment to release into ES for DOS
    Mov  AH,49h                 ;release memory service
    Int  21h

ErrExit:
;Reading = 0
    Mov  Reading,0

;Done = -1
    Mov  BX,Done
    Mov  Word Ptr [BX],-1
    Sub  CX,CX                  ;create a zero-length final string
    Call MakeString
    Jmp  Bye                    ;and we're all done

;END FUNCTION

;---- subroutines

MakeString:
    Call P$MakeTemp             ;P$MakeTemp claims memory in the string pool
    Push DS                     ;save DS for a moment
    Mov  SI,BufPos              ;copy from the current buffer start position
    Mov  DS,BufSeg              ;copy from the buffer segment
    Rep  Movsb                  ;copy the string from the buffer to the pool
    Pop  DS                     ;restore DS
    Mov  AX,BX                  ;copy the descriptor address to AX for BASIC
    Retn                        ;return to local caller


DoSeek:                         ;enter with AL holding desired SEEK method
    Xor  CX,CX                  ;zero bytes from the beginning/end in CX:DX
    Mov  DX,CX
DoSeek2:                        ;enter here with other SEEK offsets
    Mov  BX,Handle              ;get the file handle again
    Mov  AH,42h                 ;seek service
    Int  21h                    ;let DOS do the dirty work
    Retn                        ;return to caller

BufIn Endp
End
