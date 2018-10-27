;======================================================================
; R$SWAP.ASM
;  Copyright (c) 1991-1994 Crescent Software
;  Copyright (c) 1991-1994 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1. This file contains the routines and data that are always required
;    for swapping, regardless of the medium used.
;----------------------------------------------------------------------
; 10/13/91	.000    Split from SWAPDISK.ASM
;		.001    Absorb data from POPSWAP.002
;		.002    Add common data.
; 11/15/91	.003    Make buffer size variable.
; 11/15/91	.004    Remove R$IVBUF
; 12/6/91	.005    Buffer ISWAPOUT.
; 12/22/91	.006    Add swapping stack.
; 7/3/94	.007	Force direction flag in R$ISWAPOUT
;======================================================================
PUBLIC  R$ISWAPOUT      ;Near, CSEG

PUBLIC  R$SWAPIN        ;Far, RLHSEG
PUBLIC  R$SWAPOUT       ;Far, RLHSEG

PUBLIC  R$SWAP_HANDLE   ;Word, RLHSEG
PUBLIC  R$PROGID        ;Word, RLHSEG
PUBLIC  R$WRITE         ;Word, RLHSEG
PUBLIC  R$SEEKABS       ;Word, RLHSEG
PUBLIC  R$READ          ;Word, RLHSEG
PUBLIC  R$PROLOGUE      ;Word, RLHSEG
PUBLIC  R$REMOVE        ;Word, RLHSEG
PUBLIC  R$EPILOGUE      ;Word, RLHSEG
PUBLIC  R$SWAPBLKS      ;Word, RLHSEG
PUBLIC  R$MCB_LEN       ;Word, RLHSEG
PUBLIC  R$MCB_SEG       ;Word, RLHSEG

;======================================================================
; Externals.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EXTRN   YOU_MUST_LINK_POPSWAP_FIRST:ABS ;In POPSWAP.ASM
EXTRN   R$MCB_TABLE:WORD    ;In R$BUILD.ASM
EXTRN   R$REMOVEFLAG:BYTE   ;In R$CORE.ASM
EXTRN   R$SWAPIVT:NEAR      ;In R$IVT.ASM
EXTRN   R$UNHOOKIVT:FAR     ;In R$UNHOOK.ASM
EXTRN   R$IVBUF:BYTE        ;In R$IVBUF.ASM

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

EXTRN   R$POPUP:FAR     ;In POPUP.ASM

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

EXTRN   P$PSPseg:WORD               ;In PDQDATA.ASM

DSEG            ENDS

;======================================================================
; This portion of the code is linked in with the other CSEG routines
; and gets swapped out.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
    ASSUME  CS:CSEG
;======================================================================
; R$ISWAPOUT (Internal)
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
;1. This routine is responsible for adjusting the image of the program in
;   memory. It must perform the initial save from memory to disk or EM,
;   including setting up the IVT buffer for the first time.
;2. After saving, it must free all allocated memory blocks except the PSP.
;3. Finally, the size of the PSP block is set by changing the amount of
;   memory that must be resident and passing control back to ENDTSR.
;4. Note that this routine resides in CSEG and is called NEAR from CSEG.
;5. R$BUILD has already been called, so MCB table is built in memory.
;   The swapped part of the PSP segment is always the first entry in the
;   table.
;----------------------------------------------------------------------
; Entry:
;   ES = RLHSEG
;   SS = DGROUP
; Exit:
;   DS = DGROUP
;
;   If NC:
;   DX = new length in paras to save.
;   If CY:
;   Fatal error, do not go resident.
;----------------------------------------------------------------------
; Changes: AX BX CX DX SI DI DS ES
;----------------------------------------------------------------------
R$ISWAPOUT  PROC    NEAR
    ASSUME  CS:CSEG, DS:DGROUP, ES:RLHSEG, SS:DGROUP
		CLD				;Moves forward
;----------------------------------------------------------------------
; Point DS to RLHSEG. Initialize disk handle.
;----------------------------------------------------------------------
        PUSH    ES
        POP     DS
    ASSUME  DS:RLHSEG
;----------------------------------------------------------------------
; Position the file pointer to the first byte past the IVT area.
;----------------------------------------------------------------------
        SUB     CX,CX           ;To beginning of file
        MOV     DX,R$IVBUFLEN+100H
        CALL    DWORD PTR [R$SEEKABS]
        JC      RIS_EXIT
;----------------------------------------------------------------------
; Init the pointer to the MCB_TABLE entries.
;----------------------------------------------------------------------
        MOV     SI,OFFSET RLHSEG:R$MCB_TABLE

;----------------------------------------------------------------------
; 1. Get the address and length of a memory block.
;    A -1 in the table indicates no more entries.
;----------------------------------------------------------------------
RIS_2A:
        LODSW                   ;Fetch address DS:SI
        CMP     AX,-1           ;-1 = empty entry
        JE      RIS_3

        MOV     DI,AX           ;Save paragraph address

        LODSW                   ;Fetch block length in AX
;----------------------------------------------------------------------
; Can only write FFFFh bytes at a time to the file. If AX>FFFh paras,
; must perform multiple writes.
;----------------------------------------------------------------------
        MOV     BX,DI           ;Save for segment release

        MOV     CX,AX           ;AX contains paragraphs to write
RIS_2B:
        CMP     CX,0FFFH        ;Max paragraphs per write
        JBE     RIS_2C

        MOV     CX,0FFFH        ;Write this many
RIS_2C:
        SUB     AX,CX           ;This many remain
        
;----------------------------------------------------------------------
; 1. Load DS = segment of source buffer (in BX).
;    (DS is saved as shown because of error exit requirements. Do not
;    alter.)
; 2. Advance BX by the number of paras to be written in prep for next
;    write.
; 3. Load DX = offset of source buffer (always 0).
; 4. Convert AX (paras) to bytes in CX.
; 5. Perform the write.
;----------------------------------------------------------------------
        PUSH    DS              ;Save segment

        SUB     DX,DX           ;Offset and segment of
        MOV     DS,BX           ; source in DS:DX
    ASSUME  DS:NOTHING

        ADD     BX,CX           ;Move segment pointer

        SHL     CX,1
        SHL     CX,1
        SHL     CX,1
        SHL     CX,1

        PUSH    AX
        PUSH    BX

        CALL    DWORD PTR ES:[R$WRITE]

        POP     BX
        POP     AX

        POP     DS              ;Restore in case of error
    ASSUME  DS:RLHSEG
        JC      RIS_EXIT

        MOV     CX,AX           ;Retrieve paragraphs remaining
        OR      AX,AX           ;If 0, we're done
        JNZ     RIS_2B
        
;----------------------------------------------------------------------
; Release the block from memory.
; Attempt to release PSP block will fail.
;----------------------------------------------------------------------
        PUSH    ES

        MOV     AH,49H          ;Free memory block
        INC     DI              ;Past header
        MOV     ES,DI
    ASSUME  ES:NOTHING
        INT     21H

        POP     ES
    ASSUME  ES:RLHSEG

        JMP     RIS_2A
;----------------------------------------------------------------------
; No more RAM blocks left to copy. Copy the current IVT (PDQ's) to the
; IVT buffer. Point DS:SI to the IVT and ES:DI to the buffer.
;----------------------------------------------------------------------
    ASSUME  DS:RLHSEG
RIS_3:
        MOV     DI,OFFSET RLHSEG:R$IVBUF
        PUSH    DS
        POP     ES
    ASSUME  ES:RLHSEG

        SUB     SI,SI
        MOV     DS,SI
    ASSUME  DS:LOMEM

        MOV     CX,R$IVBUFLEN
        SHR     CX,1
        REP     MOVSW
;----------------------------------------------------------------------
; Adjust DX so that the PSP block will be shrunk to the correct size.
;----------------------------------------------------------------------
        MOV     DX,RHSEG
        SUB     DX,WORD PTR SS:[P$PSPSEG]
        CLC
RIS_EXIT:
        PUSH    SS
        POP     DS
    ASSUME  DS:DGROUP

        RET

R$ISWAPOUT  ENDP

CSEG        ENDS

;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;//////////////////////////////////////////////////////////////////////
;                       Unzip Here

;======================================================================
; This code and data becomes part of the resident core.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'
    ASSUME  CS:RLHSEG
;----------------------------------------------------------------------
; Data.
;----------------------------------------------------------------------
R$MCB_LEN       DW -1
R$MCB_SEG       DW -1
R$SWAP_HANDLE   DW -1       ;File handle of swap file
R$PROGID        DW  0

;----------------------------------------------------------------------
; Far pointers.
;----------------------------------------------------------------------
R$WRITE         DW  -1,RLHSEG
R$SEEKABS       DW  -1,RLHSEG

;----------------------------------------------------------------------
; Near pointers.
;----------------------------------------------------------------------
R$READ          DW  -1
R$PROLOGUE      DW  -1
R$REMOVE        DW  -1
R$EPILOGUE      DW  -1
R$SWAPBLKS      DW  -1

;----------------------------------------------------------------------
; Stack used while swapping.
;----------------------------------------------------------------------
EVEN
        DB  8 DUP ("GWENDOLYN HUMMEL","ALEXANDER HUMMEL")

        SWAP_STACK DW  -1, -1


;======================================================================
; R$SWAPIN (Internal)
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Must be in the core module.
; 2. The R$SWAP proc is patched to call this routine instead of
;    calling the R$POPUP routine.
; 3. Any errors that occur here halt the computer.
;----------------------------------------------------------------------
; Entry: State machine had at interrupt. Nothing saved so far.
;    Interrupts enabled.
; Exit: Same
;----------------------------------------------------------------------
; Changes: None
;----------------------------------------------------------------------
R$SWAPIN    PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

;----------------------------------------------------------------------
; Swap to a temporary stack.
;----------------------------------------------------------------------
        MOV     CS:[SWAP_STACK],SP
        MOV     CS:[SWAP_STACK+2],SS

        CLI
        PUSH    CS
        POP     SS

    ASSUME SS:RLHSEG
        MOV     SP,OFFSET RLHSEG:SWAP_STACK
        STI

;----------------------------------------------------------------------
; All operation must proceed as if this were the first routine to get
; control from the interrupt handler.
;----------------------------------------------------------------------
        PUSH    AX          ;Save used registers
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        PUSH    DS
        PUSH    ES
;----------------------------------------------------------------------
; Before any activity, the interrupt vector table must be reset to
; the values it held when we were swapped out INITIALLY. In other
; words, you can't permanently change an interrupt vector after you
; are resident.
;----------------------------------------------------------------------
        CALL    R$SWAPIVT
    ASSUME  DS:NOTHING, ES:NOTHING      ;Changed by proc

;----------------------------------------------------------------------
; Prep for either disk or EM work as patched by invoker.
;----------------------------------------------------------------------
        CALL    WORD PTR CS:[R$PROLOGUE]
    ASSUME  DS:NOTHING

;----------------------------------------------------------------------
; Save the IVT table that is in the buffer to the swapping medium.
;----------------------------------------------------------------------
        PUSH    CS
        POP     DS
    ASSUME  DS:RLHSEG

        SUB     CX,CX           ;To beginning of IVT
        MOV     DX,100H
        CALL    DWORD PTR [R$SEEKABS]
        JC      RDI_HALT

        MOV     CX,R$IVBUFLEN               ;Move CX bytes
        MOV     DX,OFFSET RLHSEG:R$IVBUF    ;to/from DS:DX
        CALL    DWORD PTR [R$WRITE]
        JNC     RDI_2

;----------------------------------------------------------------------
; If an error occurs here, we halt the computer with interrupts enabled.
;----------------------------------------------------------------------
RDI_HALT:   HLT
        JMP     RDI_HALT

;----------------------------------------------------------------------
; Swap the contents of the MCBs with the image on disk.
;----------------------------------------------------------------------
RDI_2:
        CALL    WORD PTR [R$SWAPBLKS]
    ASSUME  DS:NOTHING, ES:NOTHING      ;Changed by proc
        JC      RDI_HALT
;----------------------------------------------------------------------
; Restore altered registers and invoke the popup routine.
;----------------------------------------------------------------------
        POP     ES
    ASSUME  ES:NOTHING
        POP     DS
    ASSUME  DS:NOTHING

        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
;----------------------------------------------------------------------
; Put the return address for R$SWAPOUT onto the stack.
; When PopDown executes its normal RETF, it will transfer to R$SWAPOUT.
;----------------------------------------------------------------------
        PUSH    CS              ;Save diskout segment
        PUSH    AX              ;placeholder
        PUSH    BP

        MOV     BP,SP
        MOV     AX,OFFSET RLHSEG:R$SWAPOUT
        XCHG    AX,WORD PTR [BP+2]

        POP     BP

        JMP     R$POPUP         ;Never to return

R$SWAPIN    ENDP

;======================================================================
; R$SWAPOUT (Quasi-internal)
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
;1. Control is transferred here when PopDown executes a FAR return.
;   Normally, control would be returned to the interrupt handler.
;   At this point, therefore, nothing is known but CS and all registers
;   must be preserved.
;----------------------------------------------------------------------
; Changes: None
;----------------------------------------------------------------------
R$SWAPOUT   PROC    FAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:RLHSEG
;----------------------------------------------------------------------
; All operation must proceed as if this were the first routine to get
; control from the interrupt handler.
;----------------------------------------------------------------------
        PUSH    AX          ;Save used registers
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        PUSH    DS
        PUSH    ES
;----------------------------------------------------------------------
; Exchange the contents of memory (thru the buffer) with the disk file.
; This brings the foreground program back into memory.
;----------------------------------------------------------------------
        CALL    WORD PTR CS:[R$SWAPBLKS]
      ASSUME  DS:NOTHING, ES:NOTHING      ;Changed by proc
        JNC     RDO_1

;----------------------------------------------------------------------
; If an error occurs here, we halt the computer with interrupts enabled.
;----------------------------------------------------------------------
RDO_HALT:   HLT
        JMP     RDO_HALT

;----------------------------------------------------------------------
; Copy the image of the foreground's IVT (stored on the swapping medium)
; to the buffer.
; This is the last medium activity performed during a normal popdown.
;----------------------------------------------------------------------
RDO_1:
        PUSH    CS
        POP     DS
    ASSUME  DS:RLHSEG

        SUB     CX,CX                   ;To beginning of IVT
        MOV     DX,100H
        CALL    DWORD PTR [R$SEEKABS]
        JC      RDO_HALT

        MOV     CX,R$IVBUFLEN           ;Move CX bytes
        MOV     DX,OFFSET RLHSEG:R$IVBUF    ;to DS:DX
        CALL    WORD PTR [R$READ]
        JC      RDO_HALT

;----------------------------------------------------------------------
; If the R$REMOVEFLAG is TRUE, then we want to attempt to remove
; ourself here. The foreground's IVT is in the buffer. It is from THIS
; IVT that we want to attempt to unhook ourself.
; Point DS to the segment with the vectors and ISRs.
; Point ES:DI to the IVT to unhook.
; Even if the attempt doesn't work, the swap out process continues.
;----------------------------------------------------------------------
        PUSH    CS
        POP     DS
    ASSUME  DS:RLHSEG

        CMP     BYTE PTR [R$REMOVEFLAG],TRUE
        JNE     RDO_2

        PUSH    CS
        POP     ES
    ASSUME  ES:RLHSEG

        MOV     DI,OFFSET RLHSEG:R$IVBUF
        SUB     CX,CX                   ;Don't -1 vectors
        CALL    R$UNHOOKIVT
        JNC     RDO_2

        NOT     BYTE PTR [R$REMOVEFLAG] ;Set flag to false
RDO_2:
;----------------------------------------------------------------------
; Swap the IVT in the buffer for the current one.
;----------------------------------------------------------------------
        CALL    R$SWAPIVT
    ASSUME  DS:NOTHING, ES:NOTHING      ;Changed by proc
;----------------------------------------------------------------------
; If R$REMOVEFLAG is TRUE, process the removal and release code.
;----------------------------------------------------------------------
        PUSH    CS
        POP     DS
    ASSUME  DS:RLHSEG

        CMP     BYTE PTR [R$REMOVEFLAG],TRUE
        JNE     RDO_3

        CALL    WORD PTR [R$REMOVE]
        JC      RDO_3
;----------------------------------------------------------------------
; Free the PSP block if removal successful.
;----------------------------------------------------------------------
        MOV     AX,WORD PTR [R$MCB_TABLE][-2]
        MOV     ES,AX
    ASSUME  ES:NOTHING
        MOV     AH,49H          ;Free memory block
        INT     21H             ; Thru DOS
;----------------------------------------------------------------------
; Clean up as required before returning control.
;----------------------------------------------------------------------
RDO_3:
        CALL    WORD PTR [R$EPILOGUE]

;----------------------------------------------------------------------
; Restore altered registers.
;----------------------------------------------------------------------
        POP     ES
    ASSUME  ES:NOTHING
        POP     DS
    ASSUME  DS:NOTHING

        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX

;----------------------------------------------------------------------
; Swap back to the foreground stack (it has the return address).
;----------------------------------------------------------------------
        CLI
        MOV     SS,CS:[SWAP_STACK+2]
    ASSUME  SS: NOTHING
        MOV     SP,CS:[SWAP_STACK]
        STI

        RET

R$SWAPOUT   ENDP

RLHSEG      ENDS
        END
