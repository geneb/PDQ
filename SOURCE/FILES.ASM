;********** FILES.ASM - PDQ replacement for BASIC's B$FILS routine

;Copyright (c) 1989 Ethan Winer


;Note the use of the FirstTime flag below.  Regardless of whether a complete
;file name was given or just a partial file spec, if at least one file can be
;found that matches, then a "File not found" error should not be generated.
;However, if no file matches the FILES argument, ERR is set to the error.

.Model Medium, Basic
    Extrn P$ZeroFile:Proc    ;this is in ZEROFILE.ASM
    Extrn B$PESD:Proc        ;this is in PRINT.ASM
    Extrn B$PSSD:Proc        ;this is in PRINT.ASM
    Extrn P$DoError:Proc     ;this is in DOERROR.ASM

.Data?
    FirstTime DB 1 Dup(?)    ;flags the first find attempt

.Data
    Extrn P$PDQErr:Word      ;this is in ERRDATA.ASM
    Extrn P$NullDesc:Word    ;this is in PRINTDAT.ASM
    Descr DW 3, Offset FSpec ;this descriptor points to the default file spec
    FSpec DB "*.*"           ;use this if they don't specify anything else
    FNLen DW 16              ;this descriptor is used to print the file name
    FNAdr DW 0               ;we'll fill in this address later

.Code

B$FILS Proc Uses DI, FileName:Word

    Local Buffer[80]:Byte    ;copy the file name here to add a CHR$(0)
    Local DTA[43+5]:Byte     ;this is the DTA area (plus some name padding)

    Call P$PrintNull         ;first print a blank line (and clear P$PDQErr)
    Cmp  Byte Ptr P$PDQErr,0 ;an error here is pretty unlikely, but ...
    Jne  Exit                ;just in case we're redirected to a full disk

    Mov  AH,1Ah           ;DOS set DTA service
    Lea  DX,DTA           ;show where the new DTA is to be placed
    Int  21h              ;call DOS to do it

    Mov  AX,FileName      ;get the address for the file name
    Mov  BX,AX            ;copy to BX for accessing the string length
    Cmp  Word Ptr [BX],0  ;did they pass us a null string?
    Jne  @F               ;no, so use the file spec they gave
    Mov  AX,Offset Descr  ;yes, use our own local "*.*" specification instead

@@:
    Lea  DX,Buffer        ;get the address for the start of the buffer
    Call P$ZeroFile       ;this copies the spec and adds a CHR$(0) to the end
                          ;it also sets ES=DS and clears the direction
    Mov  FirstTime,-1     ;show that this is the first time through the loop
    Mov  AH,4Eh           ;find first matching file name service

FindNext:
    Mov  CL,00100111b     ;match on any attribute
    Int  21h              ;call DOS
    Jnc  PrintIt          ;no carry means the file was there, go print it
    Cmp  FirstTime,-1     ;it wasn't there, but is the first time through?
    Je   Error            ;yes, so set a "File not found" error
    Call P$PrintNull      ;no, print the follow-up blank line
    Jmp  Short Exit       ;and then exit

PrintIt:
    Mov  FirstTime,0      ;flag that we did at least one file successfully
    Lea  DI,DTA+30        ;point to the start of the file name in the DTA
    Mov  FNAdr,DI         ;assign that to the "name printing" descriptor
    Mov  CX,16            ;search/clear 13 characters

@@:
    Mov  AL,[DI]          ;load a character
    Inc  DI               ;and point to the next one for later
    Or   AL,AL            ;is it the zero byte that marks the end?
    Loopnz @B             ;no, keep searching (and adjusting CX)
    Rep  Stosb            ;yes, clear the remainder of the string to nulls
    
    Mov  AX,Offset FNLen  ;then show where the file name descriptor is
    Push AX               ;pass that on to the print routine
    Call B$PSSD           ;print the name, and advance to the next position

    Mov  AH,4Fh           ;find the next matching file name service
    Jmp  Short FindNext   ;go get 'em

Error:
    Call P$DoError        ;load the error

Exit:
    Ret                   ;return to caller

B$FILS Endp



P$PrintNull Proc Near

    Mov  AX,Offset P$NullDesc  ;issue a CRLF by printing an empty string
    Push AX                    ;show PRINT where the null half-descriptor is
    Call B$PESD                ;print nothing
    Ret

P$PrintNull Endp
End
