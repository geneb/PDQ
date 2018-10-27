;********* INPUTNUM.ASM - PDQ SMALLDOS replacement for BASIC's B$RDSD routine

;Copyright (c) 1989 Ethan Winer


;This routine handles BASIC's INPUT #n, statement.

.Model Medium, Basic
    Extrn B$SASS:Proc           ;this is in ASSIGN$.ASM
    
    BufSize = 128               ;this is how big to make the file buffer
                                ;it should be an even number to keep SP even
.Data?
    DescrLen DW 1 Dup (?)       ;this is the output descriptor
    DescrAdr DW 1 Dup (?)
    LocalErr DW 1 Dup (?)       ;remembers if there was an error, because 
                                ;  B$SASS clears any errors saved in P$PDQErr
.Data
    Extrn P$PDQErr:Word         ;this is in ERRDATA.ASM
    Extrn P$PrintHandle:Word    ;B$DSKI sets this handle, B$RDSD then uses it
                                ;PrintHandle is in PHANDLE.ASM
.Code

B$RDSD Proc Uses DI, DummySeg:Word, Work:Word, DummyFlag:Word

    Local Buffer[BufSize] ;v¢ila - a file buffer

    Mov  LocalErr,0       ;assume no errors
    Cld                   ;ensure forward direction for Stosb and Scasb below
    Push DS               ;and assign ES = DS for the same purpose
    Pop  ES

    Lea  DX,Buffer        ;show DOS where the file buffer is located
    Mov  DescrAdr,DX      ;assign the output address while we've got it
    Mov  AH,3Fh           ;specify Read service
    Mov  BX,P$PrintHandle ;get the current DOS file handle
    Mov  CX,BufSize       ;read BufSize bytes

    Int  21h              ;call DOS
    Jnc  ReadGood         ;no error, continue
    Mov  LocalErr,AX      ;remember the error
    Jmp  Short Done       ;and finish up

ReadGood:
    Or   AX,AX            ;were we already at the end of the file?
    Jnz  PartRead         ;no, so we read at least part of what we asked for
    Mov  Byte Ptr LocalErr,62 ;yes, make an "Input past end" error
    Mov  DescrLen,AX          ;create a "null" source string (AX is now zero)
    Jmp  Short Done           ;and assign the destination string from that

PartRead:
    Cmp  AX,CX            ;did we read the specified number of bytes?
    Je   FullRead         ;yes, skip ahead
    Sub  CX,AX            ;no, calculate the excess bytes that were read
    Mov  CX,AX            ;search only as many bytes as were read

FullRead:
    Mov  DescrLen,CX      ;assume this is the entire output length
    Mov  DI,DX            ;put the buffer address into DI for Scasb below
    Push CX               ;save the number of bytes to scan

    Mov  AL,13            ;search for a CHR$(13)
    Repne Scasb           ;do the search
    Pop  AX               ;get it back as AX to preserve CX if 13 was found
    Je   Found            ;we found one, go remember where
    Mov  CX,AX            ;not found, so reset CX to search the entire string

    Mov  AL,26            ;now search for a CHR$(26) "end of file" marker
    Mov  DI,DX            ;starting at the beginning of the buffer
    Repne Scasb           ;search
    Je   Found            ;we found it, continue
    Mov  Byte Ptr LocalErr,83 ;we didn't get the entire string, show that
    Jmp  Short Done           ;and finish up returning what we did get

Found:
    Inc  CX               ;swallow the CHR$(10) that always follows a CHR$(13)
    Sub  DescrLen,CX      ;show the string being that much shorter
    Dec  CX               ;skip the CHR$(13) and the CHR$(10) in the file
    Dec  CX
    Neg  CX               ;to seek back in the file we need a negative value
    Mov  AX,CX            ;put it into AX so we can use Cwd below
    Cwd                   ;now DX:AX holds the amount to seek backwards

    Mov  CX,DX            ;DOS expects the seek location in CX:DX
    Mov  DX,AX            ;(shoot the clown who decided that!)
    Mov  AX,4201h         ;DOS Seek service, relative to the current location
    Int  21h              ;call DOS to do it
    Jnc  Done             ;an error here is very unlikely
    Mov  LocalErr,AX      ;but this costs us only 5 bytes, so what the hey

Done:
    Mov  AX,Offset DescrLen  ;show B$SASS where the source descriptor is
    Push AX
    Mov  AX,Work          ;and where the destination descriptor is
    Push AX
    Call B$SASS           ;assign Work$ from the file buffer
    
    Mov  AX,LocalErr      ;retrieve the error condition if there was one
    Mov  P$PDQErr,AX      ;and assign it to P$PDQErr
    Ret                   ;return to BASIC

B$RDSD Endp
End
