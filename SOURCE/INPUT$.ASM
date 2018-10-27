;********** INPUT$.ASM - PDQ replacement for BASIC's B$FINP routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$Num2Handle:Proc ;this is in NUM2HNDL.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM
    Extrn B$SPAC:Proc       ;this is in SPACE$
    Extrn B$LEFT:Proc       ;this is in LEFT$

.Data?
    Extrn P$Cooked:Byte     ;these are in PRINTDAT.ASM
    Extrn P$Handle:Word

.Code

B$FINP Proc Uses DI, NumChars:Word, FileNum:Word

    Mov  CX,NumChars        ;see how many characters they want to read
    Push CX                 ;pass that on to SPACE$
    Call B$SPAC             ;now we have a buffer for DOS to fill
    Mov  DI,AX              ;save the returned descriptor address for later
    Push AX                 ;and push it in anticipation of calling LEFT$

    Mov  BX,FileNum         ;see which file number is being specified
    Cmp  BX,7FFFh           ;do they want the console?
    Jne  FileNumber         ;no, they gave us a file number
    Xor  BX,BX              ;yes, specify STDIN
    Jmp  Short DoRead       ;and do the read

FileNumber:
    Call P$Num2Handle       ;translate the file number to a valid DOS handle

DoRead:
    Mov  P$Handle,BX        ;save the DOS handle for later
    Mov  AX,4400h           ;get the device data for this handle
    Int  21h                ;through DOS
    Mov  P$Cooked,DL        ;save it so we can restore it later if needed
    Test DL,10000000b       ;see if we're reading the keyboard or a file
    Jz   ReadFile           ;it's a file, so we don't need to mess with this
    
    Or   DL,100000b         ;force "raw" data mode (don't expand Tabs, etc.)
    Xor  DH,DH              ;DOS requires that we clear DH
    Mov  AX,4401h           ;set the raw/cooked status service
    Int  21h                ;through DOS
    Jc   Error              ;it must have been an invalid file number

ReadDevice:
    Mov  CX,[DI]            ;how many bytes to read
    Mov  DI,[DI+02]         ;and where to put them
    Jcxz Zero               ;if they asked for zero bytes, give 'em zero!

Do:
    Push CX                 ;save CX before we trash it below
    Mov  CX,1               ;we must read the console one character at a time
    Mov  DX,DI              ;DOS expects the address in DX
    Mov  AH,3Fh             ;read from file/device service
    Int  21h                ;call DOS to do it
    Pop  CX                 ;retrieve the number of characters to input
    Jc   Error              ;if the carry flag is set there was an error
    Inc  DI                 ;point to the next address in the string
    Loop Do                 ;loop until done
    Jmp  Short NoTrim       ;go assign the output without using LEFT$

ReadFile:
    Mov  CX,[DI]            ;show DOS how many bytes to read
    Mov  DX,[DI+02]         ;and where to put them
    Mov  AH,3Fh             ;read from file/device service
    Int  21h                ;call DOS to do it
    Jnc  AssignIt           ;no carry, no error

Error:
    Call P$DoError          ;let P$DoError handle this

Zero:
    Xor  AX,AX              ;tell LEFT$ to return zero characters

AssignIt:
    Push AX                 ;tell LEFT$ how many characters to return
    Call B$LEFT             ;keep only as many bytes as we actually read
    Push AX                 ;save the descriptor address LEFT$ returned

NoTrim:
    Mov  DL,P$Cooked        ;retrieve the Raw/Cooked status
    Test DL,10000000b       ;do we need to reset it?
    Jz   Exit               ;if bit 7 is clear we read a disk file, skip over

    Xor  DH,DH              ;clear DH (DOS likes it that way)
    Mov  BX,P$Handle        ;use the handle saved earlier
    Mov  AX,4401h           ;put the mode back the way it was
    Int  21h                ;through DOS

Exit:
    Pop  AX                 ;retrieve the descriptor address
    Ret                     ;and return to BASIC

B$FINP Endp
End
