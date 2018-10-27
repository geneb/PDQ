;********** DIR$.ASM - P.D.Q. replacement for BASIC 7's DIR$ function

;Copyright (c) 1990 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


.Model Medium, Basic
    Extrn P$FixStr:Proc      ;this is in FIXSTR.ASM
    Extrn P$ZeroFile:Proc   ;this is in ZEROFILE.ASM

.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Extrn P$NullDesc:Word   ;this is in PRINTDAT.ASM

.Data?
    Full$ DW  2 Dup (?)     ;this is the output descriptor
    DTA   DB 44 Dup (?)     ;this is where DOS saves the info for subsequent
                            ;  calls to DIR$
.Code

B$FDR0 Proc                 ;this is called when DIR$ has no argument or ""

    Mov  AX,Offset P$NullDesc   ;show B$FDR1 where the null string is
    Push AX
    Call Far Ptr B$FDR1         ;let this guy do the work
    Ret

B$FDR0 Endp


B$FDR1 Proc Uses SI, Spec$:Word

    Local Buffer[80]:Byte   ;copy the file name here to add a CHR$(0)

    Push Spec$            ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Spec$,AX         ;

    Lea  DX,DTA             ;assign DS:DX for the DOS set DTA service
    Mov  SI,DX              ;copy it to SI too for later
    Add  SI,30              ;advance SI to the file name portion of the DTA
    Mov  [Full$+2],SI       ;assign the address portion of the output string
    Mov  AH,1Ah             ;set DTA service
    Int  21h                ;through DOS

    Mov  AX,Spec$           ;get the address for the file name
    Lea  DX,Buffer          ;and the address for the start of the buffer
    Call P$ZeroFile         ;add a CHR$(0) to the end of the name for DOS
    Mov  P$PDQErr,CX        ;assume no errors (P$ZeroFile leaves CX set to 0)

    Mov  AH,4Eh             ;assume we're searching for the first time
    Mov  BX,DX              ;we need to address the buffer
    Cmp  [BX],CL            ;is this a null string?  (CL is still 0)
    Jne  FindFirst          ;no, so they want to initiate a new search
    Inc  AH                 ;yes, set AH to "Find Next"

FindFirst:
    Mov  CL,00100111b       ;this matches all files (hidden, read-only, etc.)
    Int  21h                ;ask DOS to find the file name that matches
    Mov  CX,0               ;set CX to create a zero-length output string
    Jnc  CountLoop          ;no error, so go count how long the name is
    Jmp  Short Done         ;and then get out

CountLoop:
    Lodsb                   ;get a character
    Or   AL,AL              ;is it the zero that marks the end?
    Jz   Done               ;yes, so we're almost done
    Inc  CX                 ;no, show that we got another one
    Jmp  Short CountLoop    ;and keep counting

Done:
    Mov  Full$,CX           ;assign the length portion of the output string
    Mov  AX,Offset Full$    ;show BASIC where the output descriptor is
    Ret                     ;return to BASIC

B$FDR1 Endp
End
