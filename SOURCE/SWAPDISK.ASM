;======================================================================
; SWAPDISK.ASM
;  Copyright (c) 1991-1994 Crescent Software
;  Copyright (c) 1991-1994 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 9/20/91   .000    Original.
; 9/21/91   .001    Flesh in code search and file size.
; 9/23/91   .002    Patch ENDTSR. Change labels.
; 9/23/91   .003    Add R$DISKIN.
; 9/24/91   .004    Add R$PDQIVTIN.
; 9/24/91   .005    Add R$DISKOUT.
; 10/1/91   .006    R$PDQIVTIN & R$PDQIVTOUT => R$SWAPIVT
;           .007    Make in/out routines symmetric.
; 10/2/91   .008    Compress common code. Core=1874 bytes
; 10/3/91   .009    Add initial disk write & memory fudge.
; 10/8/91   .010    Add PSP swapper. Fix IVT swapper.
;           .011    Add error code.
;           .012    Split R$SWAPIVT.
; 10/10/91  .013    Int AAh support.
; 10/11/91  .014    R$SWAPFLAG; modify to save filename in file.
;           .015    R$DISKOUT deletes file.
; 10/12/91  .016    Don't remove if unsuccessful unhook.
;           .017    Flesh out EMM stuff.
;           .018    Generalize R$IDISKOUT to R$ISWAPOUT.
; 10/13/91  .019    Generalize R$DISKIN
;           .020    Generalize R$DISKOUT, rename diskin/out to swapin/out
;           .021    Rename/update RD$SWAPBLKS
;           .022    Split.
;           .023    Remove some data.
; 10/14/91  .024    Add R$UNHOOKAA patch.
; 10/16/91  .025    Add final error handling.
; 11/15/91  .026    Use buffer size equates.
; 11/15/91  .027    Make R$SWAPLEN memory, fix comments.
; 7/3/94    .028    Force direction flag.
;======================================================================
PUBLIC  SWAP2DISK   ;(PDQ)

;======================================================================
; Externals without a segment association.
;----------------------------------------------------------------------
EXTRN   P$DOERROR:FAR   ;In DOERROR.ASM

EXTRN   P$PDQERR:WORD   ;In ERRDATA.ASM
EXTRN   P$DOSVER:WORD   ;In PDQDATA.ASM

;======================================================================
; Externals.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EXTRN   R$IVBUF:BYTE        ;In R$IVBUF.ASM
EXTRN   R$SWAPLEN:WORD      ;In R$IVBUF.ASM
EXTRN   R$PROGID:WORD       ;In R$SWAP.ASM
EXTRN   R$UNHOOKAA:NEAR     ;In R$AA.ASM
EXTRN   R$MCB_TABLE:WORD    ;In R$BUILD.ASM
EXTRN   pDOSCRIT:WORD       ;In R$CORE.ASM
EXTRN   R$SWAP$1:BYTE       ;In R$CORE.ASM
EXTRN   R$SWAPFLAG:BYTE     ;In R$CORE.ASM
EXTRN   R$SWAPIN:FAR        ;In R$SWAP.ASM
EXTRN   R$SWAPOUT:FAR       ;In R$SWAP.ASM
EXTRN   R$SWAP_HANDLE:WORD  ;In R$SWAP.ASM
EXTRN   R$WRITE:WORD        ;In R$SWAP.ASM
EXTRN   R$SEEKABS:WORD      ;In R$SWAP.ASM
EXTRN   R$READ:WORD         ;In R$SWAP.ASM
EXTRN   R$PROLOGUE:WORD     ;In R$SWAP.ASM
EXTRN   R$REMOVE:WORD       ;In R$SWAP.ASM
EXTRN   R$EPILOGUE:WORD     ;In R$SWAP.ASM
EXTRN   R$SWAPBLKS:WORD     ;In R$SWAP.ASM
EXTRN   R$MCB_LEN:WORD      ;In R$SWAP.ASM
EXTRN   R$MCB_SEG:WORD      ;In R$SWAP.ASM
EXTRN   R$UNHOOKAA$1:WORD   ;In R$UNHOOK.ASM

RLHSEG      ENDS

;======================================================================
; This segment defines the end of RLHSEG.
;----------------------------------------------------------------------
RHSEG       SEGMENT PARA    PUBLIC  'RH_CODE'
RHSEG       ENDS

;======================================================================
; Externals.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'

EXTRN   R$POPUPHERE$1:BYTE  ;In POPUP.ASM
EXTRN   R$HOOKAA:NEAR       ;In R$AA.ASM
EXTRN   R$BUILD_MCB:NEAR    ;In R$BUILD.ASM
EXTRN   R$ENDTSR$1:WORD     ;In R$ENDTSR.ASM
EXTRN   R$ISWAPOUT:NEAR     ;In R$SWAP.ASM

CSEG        ENDS

;======================================================================
; A convenient alias for 0 when playing with the interrupt table.
;----------------------------------------------------------------------
LOMEM       SEGMENT AT  0000H
LOMEM       ENDS

;======================================================================
; The infamous DGROUP.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
    INCLUDE R$PDQ.EQU               ;Standard includes

DSEG            ENDS

;======================================================================
; This portion of the code is linked in with the other CSEG routines
; and gets swapped out.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; SWAP2DISK (PDQ)
;   Copyright (c) 1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
;1. Called from PDQ, this routine creates the swap file for the TSR.
;2. It patches the ENDTSR routine in ENDTSR.ASM to call R$ISWAPOUT which
;   adjusts the resident memory requirement of the program before the
;   call to DOS to terminate and stay resident.
;3. It patches the R$SWAP routine in R$CORE.ASM to call the R$SWAPIN
;   routine instead of R$POPUP. R$SWAPIN swaps the code into memory,
;   then calls R$POPUP. Note that when R$SWAPIN calls R$POPUP, it sets
;   the stack so PopDown returns to R$SWAPOUT.
;----------------------------------------------------------------------
; Usage:
;       Result%=Swap2Disk%(FileSpec$, ProgramID%)
; where:
;       FileSpec$ - Name passed to DOS verbatim
;       ProgramID% - Unique number for back door access
; Returns:
;       0 if could not allocate disk space
;      -1 if successful
;----------------------------------------------------------------------
; CHANGES: AX BX CX DX ES
;----------------------------------------------------------------------
SWAP2DISK   PROC    FAR
    ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

	CLD				;Strings moves forward

        PUSH    BP
        MOV     BP,SP           ;Create stack frame

        PUSH    SI              ;Save used registers
        PUSH    DI
;----------------------------------------------------------------------
; Initialize the error variable. Address as byte per Ethan.
;----------------------------------------------------------------------
        MOV     BYTE PTR [P$PDQERR],0
;----------------------------------------------------------------------
; Save the program ID used for remote pop-up of swapping TSRs.
;----------------------------------------------------------------------
        MOV     AX,RLHSEG       ;Address core module
        MOV     ES,AX           ; for override
    ASSUME  ES:RLHSEG

        MOV     BX,WORD PTR [BP+6]
        MOV     BX,WORD PTR [BX]
        MOV     WORD PTR ES:[R$PROGID],BX
;----------------------------------------------------------------------
; Copy the file name to the buffer and make it ASCIIZ.
;----------------------------------------------------------------------
        MOV     BX,WORD PTR [BP+8]          ;Filespec descriptor
        MOV     CX,WORD PTR [BX]            ;Length of string
        MOV     SI,WORD PTR [BX+2]          ;Offset of string

        MOV     DI,OFFSET RLHSEG:R$IVBUF    ;Start of buffer
        MOV     DX,DI                       ;Save for later write

        REP     MOVSB
        SUB     AL,AL                       ;Add final 0 byte
        STOSB
;----------------------------------------------------------------------
; Open the swap file. If it exists, this procedure will
; truncate it and destroy its current contents.
; If DOS call fails, DOS error code in AX is returned.
;----------------------------------------------------------------------
        PUSH    ES
        POP     DS              ;DX:DX -> filename
    ASSUME  DS:RLHSEG

        MOV     AH,3CH          ;Open file (AX=hndl)
        SUB     CX,CX           ;Normal attributes
        INT     21H             ; thru DOS
        JNC     S2D_0C
S2D_0A:
        PUSH    SS
        POP     DS
    ASSUME  DS:DGROUP
S2D_0B:
        CALL    P$DOERROR
        JMP     S2D_EXIT
S2D_0C:
    ASSUME  DS:RLHSEG
;----------------------------------------------------------------------
; DS =  RLHSEG
; DX -> BUFFER
;
; Save the original handle (now in AX) in the core module data.
;----------------------------------------------------------------------
        MOV     WORD PTR [R$SWAP_HANDLE],AX
;----------------------------------------------------------------------
; Write the filename to the file so we can use it later to deinstall.
;----------------------------------------------------------------------
        MOV     BX,AX           ;Handle in BX
        MOV     AH,40H          ;Write to file
        MOV     CX,100H
        INT     21H
        JC      S2D_0A

        PUSH    SS
        POP     DS
    ASSUME  DS:DGROUP

        CMP     AX,CX
        JE      S2D_1B
S2D_1A:
        MOV     AL,RE$DISKFULL
        JMP     S2D_FAIL
S2D_1B:
;----------------------------------------------------------------------
; Build and save the MCB chain of our blocks.
; Return CX:DX = memory occupied by program in preparation for move file
;   file pointer function call.
;----------------------------------------------------------------------
        CALL    R$BUILD_MCB     ;In CSEG
;----------------------------------------------------------------------
; Adjust the file size by moving the pointer to the signed offset
; from the beginning as specified in CX:DX.  This function must complete
; without error.  The pointer must be where we told it to go.
;----------------------------------------------------------------------
        MOV     SI,DX           ;Save DX value

        MOV     AX,4200H        ;Set pointer from start
        INT     21H
        JC      S2D_0B          ;Call P$DOERROR
;----------------------------------------------------------------------
; Write 1 byte to cement the size.  The file will be 1 byte larger than
; required, but its not worth the code to eliminate it.
;----------------------------------------------------------------------
        MOV     AH,40H          ;Write to file
                                ;BX=handle
        MOV     CX,1            ;1 byte
        INT     21H             ; thru DOS
        JC      S2D_0B

        CMP     AX,CX
        JNE     S2D_1A
;----------------------------------------------------------------------
; Get a duplicate handle for the file referenced by BX and return in AX.
; Close the duplicate handle to commit the current file length.
;----------------------------------------------------------------------
        MOV     AH,45H          ;Return dupe handle in AX
                                ;BX=handle to dupe
        INT     21H
        JC      S2D_0B

        MOV     BX,AX           ;Close dup handle
        MOV     AH,3EH
        INT     21H
        JC      S2D_0B
;----------------------------------------------------------------------
; Patch ENDTSR to invoke the initial save to disk when called from PDQ.
; The current CALL is a NEAR CALL to the next instruction.
;----------------------------------------------------------------------
        MOV     AX,OFFSET CSEG:R$ISWAPOUT
        MOV     BX,OFFSET CSEG:R$ENDTSR$1
        SUB     AX,BX
        MOV     WORD PTR CS:[BX-2],AX
;----------------------------------------------------------------------
; Load the correct routines for disk access when resident.
;----------------------------------------------------------------------
        PUSH    ES
        POP     DS
    ASSUME  DS:RLHSEG

        MOV     WORD PTR [R$SEEKABS],OFFSET RLHSEG:RD$SEEKABS
        MOV     WORD PTR [R$WRITE],OFFSET RLHSEG:RD$WRITE

        MOV     WORD PTR [R$READ],OFFSET RLHSEG:RD$READ
        MOV     WORD PTR [R$PROLOGUE],OFFSET RLHSEG:RD$PROLOGUE
        MOV     WORD PTR [R$REMOVE],OFFSET RLHSEG:RD$REMOVE
        MOV     WORD PTR [R$EPILOGUE],OFFSET RLHSEG:RD$EPILOGUE
        MOV     WORD PTR [R$SWAPBLKS],OFFSET RLHSEG:RD$SWAPBLKS

;----------------------------------------------------------------------
; Patch the R$SWAP procedure in R$CORE.ASM.
; Currently, it contains a FAR JMP to R$POPUP.  Patch it to execute
; a FAR JMP to the R$SWAPIN proc.
;----------------------------------------------------------------------
        MOV     WORD PTR [R$SWAP$1+1],OFFSET RLHSEG:R$SWAPIN
        MOV     WORD PTR [R$SWAP$1+3],DS
;----------------------------------------------------------------------
; Patch the R$PID procedure if using DOS 2.0 or later to set critical
; flag before call.
;----------------------------------------------------------------------
        CMP     BYTE PTR SS:[P$DOSVER],2
        JA      S2D_3

        MOV     AX,9090H
        MOV     WORD PTR [R$PID$1],AX
        MOV     BYTE PTR [R$PID$2],AL
S2D_3:
;----------------------------------------------------------------------
; Indicate that disk swapping is being used.
;----------------------------------------------------------------------
        MOV     BYTE PTR [R$SWAPFLAG],1
;----------------------------------------------------------------------
; Patch the PopupHere procedure to hook Interrupt 0AAh additionally.
;----------------------------------------------------------------------
        MOV     AX,OFFSET CSEG:R$HOOKAA
        MOV     BX,OFFSET CSEG:R$POPUPHERE$1
        SUB     AX,BX
        MOV     BYTE PTR CS:[BX-3],0E8H ;CALL NEAR opcode
        MOV     WORD PTR CS:[BX-2],AX   ;Relative offset
;----------------------------------------------------------------------
; Patch R$UNHOOK.ASM to unhook Interrupt 0AAh additionally.
;----------------------------------------------------------------------
        MOV     WORD PTR [R$UNHOOKAA$1],OFFSET RLHSEG:R$UNHOOKAA

        PUSH    SS
        POP     DS
    ASSUME  DS:DGROUP
;----------------------------------------------------------------------
; End successfullly.
;----------------------------------------------------------------------
        MOV     AX,TRUE         ;PDQ success
        JMP     SHORT S2D_EXIT
;----------------------------------------------------------------------
; End with an error code in AX.
;----------------------------------------------------------------------
S2D_FAIL:
        MOV     WORD PTR [P$PDQERR],AX
        SUB     AX,AX
;----------------------------------------------------------------------
; Common exit.
;----------------------------------------------------------------------
S2D_EXIT:
        POP     DI
        POP     SI
        POP     BP
        RET     2*2         ;Return to PDQ

SWAP2DISK       ENDP

CSEG            ENDS

;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;//////////////////////////////////////////////////////////////////////
;                       Unzip Here

;======================================================================
; The combination of name and class force this code segment to be the
; first segment in memory when the program is linked with the correct
; stub file.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'
    ASSUME  CS:RLHSEG

;----------------------------------------------------------------------
; Data that is physically present in the core and is not necessary
; if not swapping.
;----------------------------------------------------------------------
R$FG_PSP    DW  -1

;======================================================================
; RD$SEEKABS
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Positions the file pointer to the specified spot.
;----------------------------------------------------------------------
; Entry:
;   CX:DX = absolute file position
; Exit:
;   If NC
;     DX:AX = resultant file position
;   If CY
;     AX = error code
;----------------------------------------------------------------------
; Changes: AX BX DX
;----------------------------------------------------------------------
RD$SEEKABS  PROC    FAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        MOV     AX,4200H        ;Move file pointer CX:DX
        MOV     BX,WORD PTR CS:[R$SWAP_HANDLE]
        INT     21H             ;Thru DOS
        RET

RD$SEEKABS  ENDP

;======================================================================
; RD$WRITE
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Copies CX bytes from memory pointed to by DS:DX to the current
;    file position.
;----------------------------------------------------------------------
; Entry:
;   DS:DX = memory address to copy FROM
;   CX = number of bytes to copy
; Exit:
;   IF NC
;     AX = number of bytes written
;   IF CY
;     AX = error code
;----------------------------------------------------------------------
; Changes: AX BX
;----------------------------------------------------------------------
RD$WRITE    PROC    FAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        MOV     AH,40H          ;Write to file
        MOV     BX,WORD PTR CS:[R$SWAP_HANDLE]
        INT     21H
        RET

RD$WRITE    ENDP

;======================================================================
; RD$READ
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Copies CX bytes from the current file position to memory pointed
;    to by DS:DX.
;----------------------------------------------------------------------
; Entry:
;   DS:DX = memory address to copy TO
;   CX = number of bytes to copy
; Exit:
;   IF NC
;     AX = Bytes read
;   If CY
;     AX = error code
;----------------------------------------------------------------------
; Changes: AX BX
;----------------------------------------------------------------------
RD$READ     PROC    NEAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        MOV     AH,3FH          ;Write to file
        MOV     BX,WORD PTR CS:[R$SWAP_HANDLE]
        INT     21H
        RET

RD$READ     ENDP

;======================================================================
; RD$PROLOGUE
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; If disk swapping is being performed, we must make this process the
; active PSP. If EM swapping, we must save the current EMM state.
;----------------------------------------------------------------------
; Changes: AX BX DS
;----------------------------------------------------------------------
RD$PROLOGUE PROC    NEAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        MOV     AH,51H          ;Get active PSP
        CALL    R$PID
    ASSUME  DS:NOTHING

        MOV     WORD PTR CS:[R$FG_PSP],BX

        MOV     AH,50H          ;Make PSP in BX active
        MOV     BX,WORD PTR CS:[R$MCB_TABLE][-2] ;PSP
        CALL    R$PID
    ASSUME  DS:NOTHING
        RET

RD$PROLOGUE ENDP

;======================================================================
; RD$EPILOGUE
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Changes: AX BX
;----------------------------------------------------------------------
RD$EPILOGUE PROC    NEAR
    ASSUME  CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:NOTHING
        MOV     AH,50H
        MOV     BX,WORD PTR [R$FG_PSP]
        CALL    R$PID
        RET
RD$EPILOGUE ENDP

;======================================================================
; R$PID (Internal)
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;   AH = 50h, make PSP in BX active
;   BX = PSP to make active
;   or
;   AH = 51h, return current PSP in BX
;----------------------------------------------------------------------
; CHANGES: BX DS
;----------------------------------------------------------------------
R$PID       PROC    NEAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING
;----------------------------------------------------------------------
; If DOS 3.0+ is being used, calls can pass directly throught.
; If version 2.x is being used, the following 3 bytes are patched
; to NOPs to allow the code to fall through to the patch routine.
;----------------------------------------------------------------------
R$PID$1     LABEL   WORD
        INT 21H

R$PID$2     LABEL   BYTE
        RET
;----------------------------------------------------------------------
; This code is executed only when running under DOS 2.x. It forces
; DOS to use the critical error stack for this call.
;----------------------------------------------------------------------
        PUSH    BX                  ;Save possible value
        LDS     BX,DWORD PTR CS:[pDOSCRIT]
        
    ASSUME  DS:NOTHING
        INC     BYTE PTR [BX]       ;Critical error on
        POP     BX                  ;Retrieve value
        INT     21H                 ;Invoke DOS

        PUSH    BX                  ;Save possible return
        LDS     BX,DWORD PTR CS:[pDOSCRIT]
        
    ASSUME  DS:NOTHING
        DEC     BYTE PTR [BX]
        POP     BX                  ;Restore possible return

        RET

R$PID       ENDP

;======================================================================
; RD$SWAPBLKS (Internal)
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Assumes R$IVBUF is empty.
;----------------------------------------------------------------------
; Entry: None
; Exit : CF = error status
;----------------------------------------------------------------------
; Changes: AX BX CX DX SI DI DS ES
;----------------------------------------------------------------------
RD$SWAPBLKS PROC    NEAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

	CLD				;String moves forward
        PUSH    CS
        POP     DS
    ASSUME  DS:RLHSEG

        MOV     BX,WORD PTR [R$SWAP_HANDLE]
;----------------------------------------------------------------------
; Position the file pointer past the IVT area.
;----------------------------------------------------------------------
        MOV     AX,4200H        ;Move file pointer
        SUB     CX,CX           ; to CX:DX
        MOV     DX,R$IVBUFLEN + 100H
        INT     21H             ;Thru DOS
        JC      RSDB_EXIT
;----------------------------------------------------------------------
; 1. Init the pointer to the MCB_TABLE entries.
;----------------------------------------------------------------------
        MOV     SI,OFFSET RLHSEG:R$MCB_TABLE
;----------------------------------------------------------------------
; 2. Get the address and length of a memory block.
;    A value of -1 indicates no more entries in the table.
;----------------------------------------------------------------------
RSDB_2A:
        LODSW                   ;Fetch address DS:SI
        CMP     AX,-1           ;-1 = empty entry
        JNE     RSDB_2B
;----------------------------------------------------------------------
; Return to caller.
;----------------------------------------------------------------------
RSDB_EXIT:
        RET
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
RSDB_2B:
        MOV     WORD PTR [R$MCB_SEG],AX ;Save paragraph adrress
        LODSW                           ;Fetch block length
        MOV     WORD PTR [R$MCB_LEN],AX ;Length in paragraphs
;----------------------------------------------------------------------
; AX = Total paragraphs in block
; BX = file handle
; DS = RLHSEG
;
; Determine how many bytes to move in this iteration.
; If the total exceeds the buffer size, just transfer a buffer's worth.
;----------------------------------------------------------------------
    ASSUME  CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:NOTHING
RSDB_3A:
        MOV     DI,WORD PTR [R$MCB_SEG] ;Destination offset
        MOV     AX,WORD PTR [R$MCB_LEN] ;Length in paragraphs!

        CMP     AX,WORD PTR [R$SWAPLEN] ;Cannot exceed buffer size
        JBE     RSDB_3B

        MOV     AX,WORD PTR [R$SWAPLEN] ;Set to maximum length
RSDB_3B:
        ADD     WORD PTR [R$MCB_SEG],AX ;Advance pointer
        SUB     WORD PTR [R$MCB_LEN],AX ;Dec count

        MOV     CL,4
        SHL     AX,CL                   ;Convert to bytes
        MOV     CX,AX                   ;Count in CX
;----------------------------------------------------------------------
; BX = file handle
; CX = bytes to read from file
; DI = RAM seg
; DS = RLHSEG
;
; Copy (read) CX bytes from the file to the buffer (RLHSEG:R$IVBUF).
;----------------------------------------------------------------------
        MOV     AH,3FH                      ;Read
        MOV     DX,OFFSET RLHSEG:R$IVBUF    ;Dest = DS:DX
        INT     21H
        JC      RSDB_EXIT
;----------------------------------------------------------------------
; BX = file handle
; CX = + bytes to back up
; DI = RAM seg
; DS = RLHSEG
;
; Back up the file pointer to the original spot.
;----------------------------------------------------------------------
        PUSH    CX

        MOV     AX,4201H        ;Signed offset from current
        NEG     CX
        MOV     DX,CX
        MOV     CX,-1           ;CX:DX = signed offset
        INT     21H

        POP     CX
        JC      RSDB_EXIT
;----------------------------------------------------------------------
; BX = file handle
; CX = bytes to write to file
; DI = RAM seg
; DS = RLHSEG
;
; Copy directly from RAM to the file to replace the block we just read in.
;----------------------------------------------------------------------
        MOV     AH,40H          ;Write to file
        MOV     DS,DI           ;From RAM seg
    ASSUME  DS:NOTHING
        SUB     DX,DX           ;and offset
        INT     21H
        JC      RSDB_EXIT
;----------------------------------------------------------------------
; BX = file handle
; CX = bytes to write to file
; DI = RAM seg
; DS = RAM seg
;
; Copy from the buffer to RAM.
;----------------------------------------------------------------------
        MOV     ES,DI           ;Set ES to RAM seg
    ASSUME  ES:NOTHING

        PUSH    CS
        POP     DS              ;Set DS to RLHSEG
    ASSUME  DS:RLHSEG

        PUSH    SI              ;Save table pointer

        MOV     SI,OFFSET RLHSEG:R$IVBUF ;From...
        SUB     DI,DI           ;To...
        SHR     CX,1            ;Words
        REP     MOVSW           ;Move 'em

        POP     SI              ;Restore table pointer
;----------------------------------------------------------------------
; BX = file handle
; DS = RLHSEG
;
; If there are more bytes in this segment to copy, re-execute inner loop.
;----------------------------------------------------------------------
        CMP     WORD PTR [R$MCB_LEN],0  ;Paragraphs!
        JNE     RSDB_3A
;----------------------------------------------------------------------
; The block was completed. Move to the next MCB.
;----------------------------------------------------------------------
        JMP     RSDB_2A

RD$SWAPBLKS ENDP

;======================================================================
; RD$REMOVE
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;   DS=RLHSEG
; Exit:
;   CF = NC, success or unrecoverable failure
;        CY, failed, recoverable
;----------------------------------------------------------------------
; Changes: AX CX DX
;----------------------------------------------------------------------
RD$REMOVE   PROC    NEAR
    ASSUME  CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:NOTHING
;----------------------------------------------------------------------
; 1. Read the filename from disk into the buffer.
;----------------------------------------------------------------------
        SUB     CX,CX                       ;Rewind file
        MOV     DX,CX
        CALL    RD$SEEKABS
        JC      RDR_EXIT

        MOV     CX,100H                     ;Bytes
        MOV     DX,OFFSET RLHSEG:R$IVBUF    ;dest = DS:DX
        CALL    RD$READ                     ;Leaves BX=handle
        JC      RDR_EXIT
;----------------------------------------------------------------------
; 2. Close the file handle.
;----------------------------------------------------------------------
        MOV     AH,3EH          ;Close handle
                                ;BX = handle
        INT     21H             ; Thru DOS
        JC      RDR_EXIT
;----------------------------------------------------------------------
; 3. Delete the file named at DS:DX.
;----------------------------------------------------------------------
        MOV     AH,41H          ;Delete file
        INT     21H             ; Thru DOS
        CLC
RDR_EXIT:
        RET

RD$REMOVE   ENDP

RLHSEG      ENDS
            END
