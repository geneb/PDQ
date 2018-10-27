;********** KILL.ASM - PDQ replacement for BASIC's B$KILL routine

;Copyright (c) 1989 Ethan Winer


;Note the use of the FirstTime flag below.  Regardless of whether a complete
;file name was given or just a partial file spec, if at least one file can be
;found that matches, then a "File not found" error will not be generated.
;However, if no file matches the KILL argument, then ERR is set to show that.


.Model Medium, Basic
    Extrn P$ZeroFile:Proc ;this is in ZEROFILE.ASM
    Extrn P$DoError:Proc  ;this is in DOERROR.ASM

.Data?
    FirstTime DB 1 Dup(?) ;flags the first find attempt
    PathEnd   DW 1 Dup(?) ;points to the end of the drive/path if applicable

.Data
    Extrn P$PDQErr:Word   ;this is in ERRDATA.ASM

.Code

B$KILL Proc Uses SI DI, FileName:Word

    Local Buffer[80]:Byte ;copy the file name here to add a CHR$(0)
    Local DTA[44]:Byte    ;this is the DTA junk area

    Mov  AH,1Ah           ;DOS set DTA service
    Lea  DX,DTA           ;show where the new DTA is to be placed
    Int  21h              ;call DOS to do it

    Mov  AX,FileName      ;get the address for the file name
    Mov  BX,AX            ;copy the descriptor to BX so we can get the length
    Mov  CX,[BX]          ;now CX holds the string length
    Push CX               ;save CX because P$ZeroFile trashes it
    
    Lea  DX,Buffer        ;get the address for the start of the buffer
    Mov  SI,DX            ;copy that to SI to scan for the path/drive below
    Call P$ZeroFile       ;this adds a CHR$(0) to the end for DOS
    Mov  P$PDQErr,CX      ;assume no errors (and CX is conveniently zero)
    Pop  CX               ;retrieve the string length
    Jcxz DoIt             ;it's a null string, skip this mess
    
    Add  SI,CX            ;now SI points to the zero byte at the end
    Dec  SI               ;and now it points at the last character
    Std                   ;scan backwards for "\" or ":"

Parse:
    Lodsb                 ;get the current character
    Cmp  AL,"\"           ;did we find a back-slash?
    Je   DoIt             ;yes, so we're all done
    Cmp  AL,":"           ;no, but is it a colon?
    Je   DoIt             ;yes, continue
    Loop Parse            ;no, keep parsing
    Jmp  Short NoBump     ;there was no path or drive, so don't bump up SI
    
DoIt:
    Inc  SI               ;bump to the end of the path (Lodsb went too far)

NoBump:
    Inc  SI               ;plus one more to skip past the "\" or ":"
    Cld                   ;all subsequent string ops are forward
    Mov  PathEnd,SI       ;remember where the drive/path ends if applicable
    Mov  FirstTime,-1     ;show that this is the first time through the loop
    Mov  AH,4Eh           ;find first matching file name service

FindNext:
    Mov  CL,00100111b     ;match on any attribute
    Int  21h              ;call DOS
    Jnc  KillIt           ;no carry means the file was there, go nuke it
    Cmp  FirstTime,-1     ;it wasn't there, but is the first time through?
    Mov  AX,2             ;assume it was and create a "File not found" error
    Je   Error            ;yes, set the error
    Jmp  Short Exit       ;no, so simply exit

KillIt:
    Mov  FirstTime,0      ;flag that we did at least one file successfully
    Lea  SI,DTA+30        ;point to the file name area in the DTA
    Mov  DI,PathEnd       ;and to the end of the drive/path name
    Mov  CX,13            ;copy 13 characters (longest possible name + zero)
    Rep  Movsb            ;concatenate the file name to the drive/path
    Mov  AH,41h           ;delete file service (DS:DX still points to name)
    Int  21h              ;call DOS
    Mov  AH,4Fh           ;assume no error, and that we'll continue on
    Jnc  FindNext         ;no error, go find the next one

Error:
    Call P$DoError        ;let P$DoError see if critical error handling is on

Exit:
    Ret                   ;return to caller

B$KILL Endp
End
