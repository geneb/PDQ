;***** FLUSH.ASM - flushes a file's buffer to disk without having to close it

;Copyright (c) 1990 Ethan Winer


;This program works by asking DOS to create a duplicate file handle, and
;then closing that duplicate handle.
;
;Flush is designed as a C subroutine (although I hated having to do that!) so
;it may be called with a varying number of arguments.  That's why there is a
;leading underscore on the name.  Notice that Flush can determine how many
;parameters were passed by examining the code it will be returning to, and
;then reading the "n" portion of ADD SP,n statement that QuickBASIC creates
;immediately after the call to Flush.

.Model Medium, Basic
    Extrn P$Num2Handle:Proc ;this is in NUM2HNDL.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Extrn P$HandleTbl:Word  ;this is in FHANDLES.ASM
    
.Code

_Flush Proc                 ;the underscore is for CDECL compatibility

    Xor  AX,AX              ;assume no errors
    Mov  P$PDQErr,AX        ;this is faster/less code than Mov P$PDQErr,0

    Push BP                 ;we must do this manually since MASM's simplified
    Mov  BP,SP              ;  method doesn't accommodate varying parameters
    Push SI                 ;save this manually too
    
    Les  BX,[BP+02]         ;load ES:BX with the address to return to
    Mov  AX,ES:[BX]         ;load the next instruction that will be executed
    Cmp  AX,0C483h          ;is it the opcode for ADD SP,n ?
    Jne  FlushAll           ;no, Flush was called with no arguments, do all
    
    Mov  CL,ES:[BX+02]      ;read the "n" portion of the ADD SP,n statement
    Shr  CL,1               ;convert bytes to arguments (ADD SP,4 = 2 args.)
    Xor  CH,CH              ;make a word so we can use all of CX

FlushLoop:
    Mov  BX,[BP+06]         ;get the address for the LAST file number passed
    Mov  BX,[BX]            ;put the file number into BX
    Call P$Num2Handle       ;convert that to a DOS handle

    Call FlushIt            ;flush this file
    Add  BP,2               ;point to the previous parameter on the stack
    Loop FlushLoop          ;loop until done
    Jmp  Short Exit         ;we're done

Error:
    Call P$DoError          ;handle the error as necessary

Exit:
    Pop  SI                 ;we must pop these manually
    Pop  BP
    Ret                     ;return to BASIC


;-- We arrive here if Flush was called with no arguments.  Walk through all
;   possible files (15), and flush any that are now open.
FlushAll:
    Mov  CX,15                  ;flush all possible files (15)
    Mov  SI,Offset P$HandleTbl  ;point to the first entry in the handle table

FlushAllLoop:
    Mov  BX,[SI]            ;load the current DOS handle
    Or   BX,BX              ;is the file open?
    Jz   Next               ;no, go on to the next file
    Call FlushIt            ;yes, go get 'em
    
Next:
    Inc  SI                 ;go on to the next entry
    Inc  SI                 ;two Inc's is faster and less code than Add SI,2
    Loop FlushAllLoop       ;until all open files have been flushed
    Jmp  Short Exit         ;bye
    

;-- This is the code that actually flushes the files.  It is set up as a
;   subroutine so it can be called from two places.
FlushIt:
    Mov  AH,45h             ;service to duplicate a file handle
    Int  21h                ;call DOS to do it
    Jc   FError             ;DOS says an error occurred

    Mov  BX,AX              ;put the new handle into BX
    Mov  AH,3Eh             ;and close the "alias" file
    Int  21h                ;call DOS to do it
    Jc   FError             ;if the carry flag is set, there was an error
    Retn                    ;Retn forces a near return from this procedure

FError:
    Pop  DX                 ;clear the caller's return address from the stack
    Jmp  Short Error        ;jump cleanly to the error handler

_Flush Endp
End
