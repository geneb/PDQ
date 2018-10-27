;======================================================================
; SWAPEMS.ASM
;  Copyright (c) 1991 Crescent Software
;  Copyright (c) 1991 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 10/13/91  .000    Split from SWAPDISK.021.
;           .001    Flesh out routines.
;           .002    Add EMMINT.
;           .003    Debugging.
; 10/14/91  .004    Add R$UNHOOKAA patch.
; 10/16/91  .005    Add error handling.
; 11/2/91   .006    Fix multi-page swapping.
; 11/5/91   .007    Fix RE$BACKUP, RE$READ.
; 11/15/91  .008    Use buffer size equates.
; 11/15/91  .009    Make R$SWAPLEN memory.
;======================================================================
PUBLIC  SWAP2EMS    ;(PDQ)

;======================================================================
; Externals with no segment association.
;----------------------------------------------------------------------
EXTRN   P$PDQERR:WORD       ;In ERRDATA.ASM
EXTRN   P$PSPseg:WORD       ;In PDQDATA.ASM
EXTRN   P$DOSVER:WORD       ;In PDQDATA.ASM

;======================================================================
; Externals.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EXTRN   R$IVBUF:BYTE        ;In R$IVBUF.ASM
EXTRN   R$SWAPLEN:WORD      ;In R$IVBUF.ASM
EXTRN   R$PROGID:WORD       ;In R$SWAP.ASM
EXTRN   R$UNHOOKAA:NEAR     ;In R$AA.ASM
EXTRN   R$MCB_TABLE:WORD    ;In R$BUILD.ASM
EXTRN   R$SWAP$1:BYTE       ;In R$CORE.ASM
EXTRN   R$SWAPFLAG:BYTE     ;In R$CORE.ASM
EXTRN   R$REMOVEFLAG:BYTE   ;In R$CORE.ASM
EXTRN   R$SWAPIVT:NEAR      ;In R$IVT.ASM
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
EXTRN   R$UNHOOKIVT:FAR     ;In R$UNHOOK.ASM
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
EXTRN   R$ISWAPOUT:NEAR     ;In R$SWAP

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

R$PAGESIZE  EQU 4000H   ;16kb

EMSNAME     DB  "EMMXXXX0"
EMSNAMELEN  EQU $-OFFSET EMSNAME

DSEG            ENDS

;======================================================================
; This portion of the code is linked in with the other CSEG routines
; and gets swapped out.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; SWAP2EMS (PDQ)
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
;1. Called from PDQ, this routine allocates the expanded memory needed
;   to swap the TSR.
;2. It patches the ENDTSR routine in ENDTSR.ASM to call R$ISWAPOUT which
;   adjusts the resident memory requirement of the program before the
;   call to DOS to terminate and stay resident.
;3. It patches the R$SWAP routine in R$CORE.ASM to call the R$SWAPIN
;   routine instead of R$POPUP. R$SWAPIN swaps the code into memory,
;   then calls R$POPUP. Note that when R$SWAPIN calls R$POPUP, it sets
;   the stack so PopDown returns to R$SWAPOUT.
;----------------------------------------------------------------------
; Usage:
;       Result%=Swap2EMS%(ProgramID%)
; where:
;       ProgramID% - Unique number for back door access
; Returns:
;       0% if could not allocate disk space
;      -1% if successful
;----------------------------------------------------------------------
; CHANGES: AX BX CX DX
;----------------------------------------------------------------------
SWAP2EMS    PROC    FAR
    ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

        PUSH    BP
        MOV     BP,SP           ;Create stack frame
        PUSH    SI
        PUSH    DI
;----------------------------------------------------------------------
; Initialize error.
;----------------------------------------------------------------------
        SUB     AX,AX           ;Do not change
        MOV     BYTE PTR [P$PDQERR],AL
;----------------------------------------------------------------------
; Determine if EMM is present by examining the device driver directly.
;----------------------------------------------------------------------
        MOV     ES,AX           ;AX previously 0
    ASSUME  ES:LOMEM

        MOV     SI,OFFSET DGROUP:EMSNAME
        MOV     CX,EMSNAMELEN

        MOV     DI,0AH
        MOV     ES,WORD PTR ES:[67H*4+2]
    ASSUME  ES:NOTHING

        REPE    CMPSB
        MOV     AX,RE$FEATUNAV      ;No EMM installed
        JE      S2E_0
        JMP     S2E_FAIL
S2E_0:
;----------------------------------------------------------------------
; Build and save the MCB chain of our blocks.
; Return CX:DX = memory (in bytes) required by program.
;----------------------------------------------------------------------
        CALL    R$BUILD_MCB     ;In CSEG
;----------------------------------------------------------------------
; Determine how many 16k (4000h bytes) pages are required.
; Round up to next whole page.
;----------------------------------------------------------------------
        MOV     AX,DX           ;Put into DX:AX
        MOV     DX,CX
        MOV     CX,R$PAGESIZE
        DIV     CX              ;Pages in AX

        OR      DX,DX
        JZ      S2E_1

        INC     AX              ;Round up
S2E_1:
;----------------------------------------------------------------------
; When RLHSEG is conveniently available, save the program id.
;----------------------------------------------------------------------
        MOV     BX,WORD PTR [BP+6]
        MOV     BX,WORD PTR [BX]

        MOV     DX,RLHSEG
        MOV     DS,DX
    ASSUME  DS:RLHSEG

        MOV     WORD PTR [R$PROGID],BX
;----------------------------------------------------------------------
; Attempt to allocate the required number of pages.
; If successful, save the EMM handle.
;----------------------------------------------------------------------
        MOV     BX,AX           ;Number of pages
        MOV     AH,43H          ;Allocate pages fn
        CALL    C$EMMINT
        MOV     AL,RE$OUTOFMEM
        JC      S2E_FAIL

        MOV     WORD PTR [R$SWAP_HANDLE],DX
;----------------------------------------------------------------------
; Get the base address of the EM page frame.
;----------------------------------------------------------------------
        MOV     AH,41H
        CALL    C$EMMINT
        MOV     AL,-1
        JC      S2E_FAIL

        MOV     WORD PTR [R$EMBASE],BX
;----------------------------------------------------------------------
; Patch ENDTSR to invoke the initial save when called from PDQ.
; The current code is a NEAR CALL to the next instruction. Calculate
; the new relative offset.
;----------------------------------------------------------------------
        MOV     AX,OFFSET CSEG:R$ISWAPOUT
        MOV     BX,OFFSET CSEG:R$ENDTSR$1
        SUB     AX,BX
        MOV     WORD PTR CS:[BX-2],AX
;----------------------------------------------------------------------
; Load the correct routines for EM access when resident.
;----------------------------------------------------------------------
        MOV     WORD PTR [R$SEEKABS],OFFSET RLHSEG:RE$SEEKABS
        MOV     WORD PTR [R$WRITE],OFFSET RLHSEG:RE$WRITE

        MOV     WORD PTR [R$READ],OFFSET RLHSEG:RE$READ
        MOV     WORD PTR [R$PROLOGUE],OFFSET RLHSEG:RE$PROLOGUE
        MOV     WORD PTR [R$REMOVE],OFFSET RLHSEG:RE$REMOVE
        MOV     WORD PTR [R$EPILOGUE],OFFSET RLHSEG:RE$EPILOGUE
        MOV     WORD PTR [R$SWAPBLKS],OFFSET RLHSEG:RE$SWAPBLKS
;----------------------------------------------------------------------
; Patch the R$SWAP procedure in R$CORE.ASM.
; Currently, it contains a FAR JMP to R$POPUP. Patch it to execute
; a FAR JMP to the R$SWAPIN proc.
;----------------------------------------------------------------------
        MOV     WORD PTR [R$SWAP$1+1],OFFSET RLHSEG:R$SWAPIN
        MOV     WORD PTR [R$SWAP$1+3],RLHSEG
;----------------------------------------------------------------------
; Indicate that EM swapping is in effect.
;----------------------------------------------------------------------
        MOV     BYTE PTR [R$SWAPFLAG],2 ;EM swapping
;----------------------------------------------------------------------
; Patch the PopupHere procedure to hook Int AA additionally.
;----------------------------------------------------------------------
        MOV     AX,OFFSET CSEG:R$HOOKAA
        MOV     BX,OFFSET CSEG:R$POPUPHERE$1
        SUB     AX,BX
        MOV     BYTE PTR CS:[BX-3],0E8H ;CALL NEAR opcode
        MOV     WORD PTR CS:[BX-2],AX   ;Relative offset
;----------------------------------------------------------------------
; Patch R$UNHOOK.ASM to unhook Int AA additionally.
;----------------------------------------------------------------------
        MOV     WORD PTR [R$UNHOOKAA$1],OFFSET RLHSEG:R$UNHOOKAA
;----------------------------------------------------------------------
; End successfullly.
;----------------------------------------------------------------------
        MOV     AX,-1           ;PDQ success
        JMP     SHORT S2E_EXIT
;----------------------------------------------------------------------
; End with an error code in AX.
;----------------------------------------------------------------------
S2E_FAIL:
        MOV     BYTE PTR SS:[P$PDQERR],AL
        SUB     AX,AX           ;Function return
;----------------------------------------------------------------------
; Common exit.
;----------------------------------------------------------------------
S2E_EXIT:
        PUSH    SS
        POP     DS
    ASSUME  DS:DGROUP

        POP     DI
        POP     SI
        POP     BP
        RET     1*2         ;Return to PDQ

SWAP2EMS    ENDP

;======================================================================
; C$EMMINT
;----------------------------------------------------------------------
C$EMMINT    PROC    NEAR
    ASSUME  CS:CSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        INT     67H
        OR      AH,AH
        JZ      CEE_1
        STC
CEE_1:
        RET

C$EMMINT    ENDP

CSEG        ENDS

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
R$EMBASE    DW  -1

R$EMPAGE    DW  0       ;Current logical page
R$EMOFF     DW  0       ;"File" pointer

;======================================================================
; RE$SEEKABS
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Ensures that the specified byte of EM is available.
;----------------------------------------------------------------------
; Entry:
;   CX:DX = desired byte
; Exit:
;   CF set to indicate result
;----------------------------------------------------------------------
; Changes: AX BX DX
;----------------------------------------------------------------------
RE$SEEKABS  PROC    FAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        PUSH    DX
        PUSH    CX
;----------------------------------------------------------------------
; Put CX:DX in DX:AX, then divide by CX.
; Page number (0-based) is left in AX. Byte offset in AX.
;----------------------------------------------------------------------
        MOV     AX,DX
        MOV     DX,CX
        MOV     CX,R$PAGESIZE
        DIV     CX
        MOV     WORD PTR CS:[R$EMOFF],DX
        MOV     WORD PTR CS:[R$EMPAGE],AX
;----------------------------------------------------------------------
; Swap the correct page into the page frame.
;----------------------------------------------------------------------
        MOV     BX,AX
        MOV     AX,4400H
        MOV     DX,WORD PTR CS:[R$SWAP_HANDLE]
        CALL    R$EMMINT        ;Sets CF if fail
        JC      RES_1

        POP     DX
        POP     AX
RES_EXIT:
        RET
RES_1:
        ADD     SP,4            ;Discard pushes
        JMP     SHORT RES_EXIT

RE$SEEKABS  ENDP

;======================================================================
; RE$WRITE
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Copies CX bytes from the memory pointed to by DS:DX to the current
;    EM pointer position.
; 2. If write crosses a page boundary, subsequent pages will be swapped
;    in.
;----------------------------------------------------------------------
; Entry:
;   DS:DX = memory address to copy FROM
;   CX = number of bytes to copy
; Exit:
;   AX = number of bytes written
;   CF set to indicate result
;----------------------------------------------------------------------
; Changes: AX BX
;----------------------------------------------------------------------
RE$WRITE    PROC    FAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        PUSH    CX
        PUSH    DX
        PUSH    SI          ;Save used registers
        PUSH    DI
        PUSH    ES
;----------------------------------------------------------------------
; Calculate the number of free bytes on this page.
;----------------------------------------------------------------------
REW_0:
        MOV     AX,R$PAGESIZE               ;Maximum bytes
        MOV     DI,WORD PTR CS:[R$EMOFF]    ;Number used
        SUB     AX,DI                       ;Number free
;----------------------------------------------------------------------
; If not enough free bytes remain, a new page will have to be loaded
; when appropriate.
;----------------------------------------------------------------------
        PUSH    CX              ;Save original count

        CMP     CX,AX           ;Unsigned compare
        JBE     REW_1

        MOV     CX,AX           ;Move maximum number
REW_1:
;----------------------------------------------------------------------
; Copy CX bytes from DS:DX to [EMBASE]:[EMOFF]
;----------------------------------------------------------------------
        MOV     BX,CX

        ADD     WORD PTR CS:[R$EMOFF],CX    ;Update pointer

        MOV     ES,WORD PTR CS:[R$EMBASE]
    ASSUME  ES:NOTHING

        MOV     SI,DX
        REP     MOVSB
;----------------------------------------------------------------------
; Get back the original count. Subtract the number of bytes transferred.
; If 0, we're done. If not 0, load the next page and continue.
;----------------------------------------------------------------------
        POP     CX
        SUB     CX,BX
        JZ      REW_2
;----------------------------------------------------------------------
; Load the next page.
;----------------------------------------------------------------------
        MOV     WORD PTR CS:[R$EMOFF],0
        MOV     AX,4400H                ;Load to phys page 0
        INC     WORD PTR CS:[R$EMPAGE]  ;Next logical page
        MOV     BX,WORD PTR CS:[R$EMPAGE]
        MOV     DX,WORD PTR CS:[R$SWAP_HANDLE]
        CALL    R$EMMINT                ;Sets CF if fail
        JC      REW_2

;----------------------------------------------------------------------
; Reenter routine.
; DS:DX = memory address to copy from, CX = number of bytes to copy.
;----------------------------------------------------------------------
        MOV     DX,SI
        JMP     REW_0
;----------------------------------------------------------------------
; Restore registers and exit.
;----------------------------------------------------------------------
REW_2:
        POP     ES
    ASSUME  ES:NOTHING
        POP     DI
        POP     SI
        POP     DX
        POP     CX

        MOV     AX,CX
        RET

RE$WRITE    ENDP

;======================================================================
; RE$READ
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;   DS:DX = memory address to copy TO
;   CX = number of bytes to copy
; Exit:
;   AX = Bytes read
;   CF set to indicate result
;----------------------------------------------------------------------
; Changes: AX BX
;----------------------------------------------------------------------
RE$READ     PROC    NEAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        PUSH    CX
        PUSH    DX
        PUSH    SI          ;Save used registers
        PUSH    DI
        PUSH    DS
        PUSH    ES
;----------------------------------------------------------------------
; Calculate the number of bytes on this page.
;----------------------------------------------------------------------
RER_0:
        MOV     AX,R$PAGESIZE               ;Maximum bytes
        MOV     SI,WORD PTR CS:[R$EMOFF]    ;Number used
        SUB     AX,SI                       ;Number free
;----------------------------------------------------------------------
; If not enough bytes remain, a new page will have to be loaded
; when appropriate.
;----------------------------------------------------------------------
        PUSH    CX              ;Save original count

        CMP     CX,AX           ;Unsigned compare
        JBE     RER_1

        MOV     CX,AX           ;Move maximum number
RER_1:
;----------------------------------------------------------------------
; Copy CX bytes from [EMBASE]:[EMOFF] to DS:DX
;----------------------------------------------------------------------
        MOV     BX,CX

        ADD     WORD PTR CS:[R$EMOFF],CX    ;Update pointer
        PUSH    DS
        POP     ES
    ASSUME  ES:NOTHING
        MOV     DI,DX

        MOV     DS,WORD PTR CS:[R$EMBASE]
    ASSUME  DS:NOTHING

        REP     MOVSB
;----------------------------------------------------------------------
; Get back the original count. Subtract the number of bytes transferred.
; If 0, we're done. If not 0, load the next page and continue.
;----------------------------------------------------------------------
        POP     CX
        SUB     CX,BX
        JZ      RER_2
;----------------------------------------------------------------------
; Load the next page.
;----------------------------------------------------------------------
        MOV     WORD PTR CS:[R$EMOFF],0
        MOV     AX,4400H                ;Load to phys page 0
        INC     WORD PTR CS:[R$EMPAGE]  ;Next logical page
        MOV     BX,WORD PTR CS:[R$EMPAGE]
        MOV     DX,WORD PTR CS:[R$SWAP_HANDLE]
        CALL    R$EMMINT

        JC      RER_2
;----------------------------------------------------------------------
; Reenter routine.
; DS:DX = memory address to copy to, CX = number of bytes to copy.
;----------------------------------------------------------------------
        PUSH    ES
        POP     DS
    ASSUME  DS:NOTHING

        MOV     DX,DI
        JMP     RER_0

;----------------------------------------------------------------------
; Restore registers and exit.
;----------------------------------------------------------------------
RER_2:
        POP     ES
        POP     DS
    ASSUME  ES:NOTHING
        POP     DI
        POP     SI
        POP     DX
        POP     CX

        MOV     AX,CX
        RET

RE$READ     ENDP

;======================================================================
; RE$PROLOGUE
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Get control of the EMM.
;----------------------------------------------------------------------
; Entry: None
;----------------------------------------------------------------------
; Changes: AX DX
;----------------------------------------------------------------------
RE$PROLOGUE PROC    NEAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        MOV     AH,47H          ;Save page map
        MOV     DX,WORD PTR CS:[R$SWAP_HANDLE]
        CALL    R$EMMINT        ;Sets CF if fail
        RET

RE$PROLOGUE ENDP

;======================================================================
; RE$EPILOGUE
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Restore the state of the EMM.
;----------------------------------------------------------------------
; Entry: None
;----------------------------------------------------------------------
; Changes: AX DX
;----------------------------------------------------------------------
RE$EPILOGUE PROC    NEAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        CMP     BYTE PTR CS:[R$REMOVEFLAG],TRUE
        JE      REP_1

        MOV     AH,48H
        MOV     DX,WORD PTR CS:[R$SWAP_HANDLE]
        CALL    R$EMMINT        ;Sets CF if fail
REP_1:
        RET

RE$EPILOGUE ENDP

;======================================================================
; RE$SWAPBLKS
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry: None
; Exit : CF = error status
;----------------------------------------------------------------------
; Changes:
;----------------------------------------------------------------------
RE$SWAPBLKS PROC    NEAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        PUSH    CS
        POP     DS
    ASSUME  DS:RLHSEG

;----------------------------------------------------------------------
; Position the file pointer past the IVT area.
;----------------------------------------------------------------------
        SUB     CX,CX
        MOV     DX,R$IVBUFLEN + 100H
        CALL    DWORD PTR [R$SEEKABS]
        JC      RSDB_EXIT

;----------------------------------------------------------------------
; 1. Init the pointer to the MCB_TABLE entries.
;----------------------------------------------------------------------
        MOV     SI,OFFSET RLHSEG:R$MCB_TABLE

;----------------------------------------------------------------------
; 2. Get the address and length of a memory block.
;    A -1 indicates no more entries in the table.
;----------------------------------------------------------------------
RSDB_2A:
        LODSW                   ;Fetch address
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
        MOV     WORD PTR [R$MCB_SEG],AX ;Save para adr
        LODSW                           ;Fetch block length
        MOV     WORD PTR [R$MCB_LEN],AX ;Length in paras
;----------------------------------------------------------------------
; AX = Total paragraphs in block
; BX = file handle
; DS = RLHSEG
;
; Determine how many bytes to move in this iteration.
; If the total exceeds the buffer size, just transfer a buffer's worth.
;----------------------------------------------------------------------
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
; CX = bytes to read from EM
; DI = RAM seg
; DS = RLHSEG
;
; Copy (read) CX bytes from EM to the buffer (RLHSEG:R$IVBUF).
;----------------------------------------------------------------------
        MOV     DX,OFFSET RLHSEG:R$IVBUF ;Dest = DS:DX
        CALL    RE$READ
        JC      RSDB_EXIT
;----------------------------------------------------------------------
; CX = + bytes to back up
; DI = RAM seg
; DS = RLHSEG
;
; Back up the EM pointer to the original spot.
;----------------------------------------------------------------------
        CALL    RE$BACKUP
        JC      RSDB_EXIT
;----------------------------------------------------------------------
; CX = bytes to write to file
; DI = RAM seg
; DS = RLHSEG
;
; Copy directly from RAM to the file to replace the block we just read in.
;----------------------------------------------------------------------
        MOV     DS,DI           ;From RAM seg
    ASSUME  DS:NOTHING
        SUB     DX,DX           ;and offset
        CALL    DWORD PTR [R$WRITE]
        JC      RSDB_EXIT
;----------------------------------------------------------------------
; CX = bytes to write to file
; DI = RAM seg
;
; Copy from the buffer to RAM.
;----------------------------------------------------------------------
        PUSH    DS
        POP     ES              ;Set ES to RAM seg
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
; If there are more bytes in this segment to copy, re-execute inner loop.
;----------------------------------------------------------------------
        CMP     WORD PTR [R$MCB_LEN],0  ;Paragraphs!
        JNE     RSDB_3A
;----------------------------------------------------------------------
; The block was completed. Move to the next MCB.
;----------------------------------------------------------------------
        JMP     RSDB_2A

RE$SWAPBLKS ENDP

;======================================================================
; RE$BACKUP
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Backup the EM pointer, changing pages as required.
;----------------------------------------------------------------------
; Entry:
;   CX = bytes to back up
;----------------------------------------------------------------------
; Changes: AX BX DX
;----------------------------------------------------------------------
RE$BACKUP   PROC    NEAR
    ASSUME  CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:NOTHING

        PUSH    CX
;----------------------------------------------------------------------
; The current position is the same as the maximum number of bytes we
; can back up without changing pages.
;----------------------------------------------------------------------
        MOV     AX,WORD PTR [R$EMOFF]   ;Current position
REB_1:
        CMP     CX,AX
        JA      REB_2
;----------------------------------------------------------------------
; Adjust the pointers, then exit.
;----------------------------------------------------------------------
        SUB     WORD PTR [R$EMOFF],CX
REB_EXIT:
        POP     CX
        RET
;----------------------------------------------------------------------
; Backup beyond page boundary.
;----------------------------------------------------------------------
REB_2:
        SUB     CX,AX

        MOV     AX,4400H
        DEC     WORD PTR [R$EMPAGE]
        MOV     BX,WORD PTR [R$EMPAGE]
        MOV     DX,WORD PTR [R$SWAP_HANDLE]
        CALL    R$EMMINT                    ;Sets CF if fail
        JC      REB_EXIT

        MOV     AX,R$PAGESIZE
        MOV     WORD PTR [R$EMOFF],AX
        JMP     REB_1

RE$BACKUP   ENDP


;======================================================================
; RE$REMOVE
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;   DS=RLHSEG
; Exit:
;   CF = NC, success or unrecoverable failure
;        CY, failed, recoverable
;----------------------------------------------------------------------
; Changes: AX CX DX
;----------------------------------------------------------------------
RE$REMOVE   PROC    NEAR
    ASSUME  CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:NOTHING
;----------------------------------------------------------------------
; Before the pages can be released, the previous state has to be
; restored. The subsequent call to RE$EPILOGUE will generate a
; harmless error.
;----------------------------------------------------------------------
        MOV     AH,48H
        MOV     DX,WORD PTR CS:[R$SWAP_HANDLE]
        CALL    R$EMMINT        ;Sets CF if fail
        JC      REM_EXIT

        MOV     AH,45H
        CALL    R$EMMINT
REM_EXIT:
        RET

RE$REMOVE   ENDP

;======================================================================
; RE$EMMINT
;----------------------------------------------------------------------
R$EMMINT    PROC    NEAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

        INT     67H
        OR      AH,AH
        JZ      REE_1
        STC
REE_1:
        RET

R$EMMINT    ENDP

RLHSEG      ENDS
            END
