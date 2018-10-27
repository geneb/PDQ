;********* FIELD2.ASM - releases a FIELD buffer and clears fielded strings

;Copyright (c) 1991 Ethan Winer

;This routine is called by CLOSE.ASM and RESET.ASM with BX set to the BASIC
;file number being closed.  Those routines require that BX, CX, DX, and SI
;be saved.  However, this routine does not use DX.  Also see the comments in
;FIELD.ASM for information on how FIELD is implemented in P.D.Q.


.Model Medium, Basic
    Extrn B$STDL:Proc       ;this is in STRDELET.ASM

    MaxDesc Equ 320         ;the maximum descriptors for each FIELD buffer
                            ;note that MaxDesc is also defined in FIELD.ASM
                            ;MaxDesc must be evenly divisible by 16
.Data
    Public P$FldDesc        ;so code in FIELD.ASM can get at them
    Public P$FldSegs        ;these are also accessed by GET/PUTFLD[SK].ASM
    P$FldDesc DW 30 Dup (0) ;a descriptor for each of 15 field buffers
    P$FldSegs DW 15 Dup (0) ;table of 15 far memory segments for pointers

.Code

P$CloseField Proc Uses BX CX SI

    Dec  BX                 ;convert to zero-based to address the tables
    Shl  BX,1               ;point to the appropriate segment and descriptor

    Xor  AX,AX              ;make a zero to clear out the segment entry
    Xchg AX,P$FldSegs[BX]   ;get the far memory segment from the table
    Or   AX,AX              ;is this a currently opened and fielded file?
    Je   Exit               ;no, skip over

    Shl  BX,1               ;times 2 again because each descriptor is 4 bytes
    Add  BX,Offset P$FldDesc;now BX holds address of this buffer's descriptor
    Push BX                 ;pass it in anticipation of calling B$STDL later

    Mov  ES,AX              ;address that segment
    Xor  SI,SI              ;starting at address zero
    Mov  CX,MaxDesc         ;examine as many as MaxDesc descriptor addresses

Do:
    Sub  BX,BX              ;make a zero quickly
    Xchg BX,ES:[SI]         ;get and clear the current descriptor address
    Or   BX,BX              ;is this a null entry meaning we hit the end?
    Jz   Done               ;yes, all done with this phase
    Mov  Word Ptr [BX],0    ;no, manually force the string to a length of 0
    Inc  SI                 ;point to the next entry in the descriptor table
    Inc  SI                 ;(two Inc's is better than Add SI,2)
    Loop Do                 ;loop until done

Done:
    Mov  AH,49h             ;service 49h does the trick
    Int  21h                ;have DOS free the memory segment now held in ES

    Call B$STDL             ;finally, delete the FIELD buffer string
                            ;  (note that the address was pushed earlier)
Exit:
    Ret

P$CloseField Endp
End
