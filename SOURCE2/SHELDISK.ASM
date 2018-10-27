	PAGE    ,132
;======================================================================
; SHELDISK.ASM
;  Copyright (c) 1993 Schaefer Software, by Robert L. Hummel
;  Copyright (c) 1993 Crescent Software
;----------------------------------------------------------------------
; Contains the routines required to support spawning a program while
; copying the majority of itself to a disk file.
;----------------------------------------------------------------------
; 9/30/93       .000    Adapted from SWAPDISK.ASM, R$BUILD, R$MCB.
;======================================================================
PUBLIC  SHELL2DISK   ;(PDQ)

;======================================================================
; Externals without a segment association.
;======================================================================
	EXTRN   P$DOERROR:FAR   ;In DOERROR.ASM
	EXTRN   P$PDQERR:WORD   ;In ERRDATA.ASM

;======================================================================
; RLHSEG (core segment) externals.
; RHSEG marks the end of RLHSEG.
;======================================================================
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'
	EXTRN   YOU_MUST_LINK_POPSWAP_FIRST:ABS ;In POPSWAP.ASM
;;; EXTRN   R$IVBUF:BYTE            ;In R$IVBUF.ASM
;;; EXTRN   R$SWAPLEN:WORD          ;In R$IVBUF.ASM
RLHSEG      ENDS

RHSEG       SEGMENT PARA    PUBLIC  'RH_CODE'
RHSEG       ENDS

;======================================================================
; CSEG (discardable) externals.
;======================================================================
CSEG        SEGMENT WORD    PUBLIC  'CODE'
CSEG        ENDS

;======================================================================
; A convenient alias for 0 when playing with the interrupt table.
;======================================================================
LOMEM       SEGMENT AT  0000H
LOMEM       ENDS

;======================================================================
; The infamous DGROUP.
;======================================================================
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
	INCLUDE R$PDQ.EQU               ;Standard includes
	EXTRN   P$PSPSEG:WORD       ;In PDQDATA.ASM
DSEG            ENDS

;======================================================================
; Core data.
;======================================================================
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EVEN
		DW  256 DUP(0)      ;Stack while shelling
R$STACK     LABEL   WORD

R$PDQSP     DW  0           ; stack swap
R$PDQSS     DW  0           ;Save PDQ stack during

R$MCBSEG    DW  0           ;Scratch find first/next

R$MBUF      DW  0           ;Temporary buffer seg

R$RTNCODE   DW  0           ;Child return code
R$PDQERR    DW  0

R$SWAPFILE  DB  127 DUP(0),0        ;ASCIIZ name
R$SWAP_HANDLE   DW  -1          ;Handle of swap file

R$CHILD     DB  127 DUP(0),0        ;ASCIIZ name

R$FCB1      DB  37 DUP (0)      ;Parameters
R$FCB2      DB  37 DUP (0)      ; for the
R$TAIL      DB  0, 127 DUP (13)     ; EXEC call

R$XCB       LABEL   BYTE
 RP$ENV     DW  0           ;Environment segment
 RP$CMDTAIL DW  R$TAIL          ;Ptr to command tail
		DW  RLHSEG
 RP$FCB1    DW  OFFSET RLHSEG:R$FCB1    ;Ptr to FCB 1
		DW  RLHSEG
 RP$FCB2    DW  OFFSET RLHSEG:R$FCB2    ;Ptr to FCB 2
		DW  RLHSEG

	;These three items must be continguous
R$PSPLEN    DW  -1          ;Holds original PSP length
R$PSPSEG    DW  -1          ;Holds PSP segment
R$MCB_TABLE DW  16 DUP(-1,-1)       ;Segment, size

HUNG_MSG    DB  "PDQ: Memory Corrupt - PC Halted"
HUNG_LEN    EQU $-OFFSET RLHSEG:HUNG_MSG

;======================================================================
; FIND_FIRST_MCB (internal)
;   Copyright (c) 1989-1993 Schaefer Software, Robert L. Hummel
;   Copyright (c) 1989-1993 Crescent Software
;----------------------------------------------------------------------
; 1. Locates the begining of the memory control block chain.
;----------------------------------------------------------------------
; Entry: none
; Exit:  AX = segment of first MCB header.
;----------------------------------------------------------------------
; 9/29/93   .001    Absorbed into RLHSEG.
;----------------------------------------------------------------------
; Changes: AX
;----------------------------------------------------------------------
FIND_FIRST_MCB  PROC    FAR
		ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

		PUSH    BX                      ;Save used registers
		PUSH    ES

		MOV     AH,52H                  ;Get IVARS pointer
		INT     21H                     ; in ES:BX
	ASSUME  ES:NOTHING
		MOV     AX,ES:[BX][-2]      ;First MCB
		MOV     CS:[R$MCBSEG],AX    ;Update saved entry

		POP     ES                      ;Restore registers
		POP     BX
		RET

FIND_FIRST_MCB  ENDP

;======================================================================
; FIND_NEXT_MCB (internal)
;   Copyright (c) 1989-1993 Schaefer Software, Robert L. Hummel
;   Copyright (c) 1989-1993 Crescent Software
;----------------------------------------------------------------------
; 1. Locates the next entry in the memory control block chain.
;----------------------------------------------------------------------
; Entry: none
; Exit: NC, AX = segment of MCB header.
;       CY, No more segments
;----------------------------------------------------------------------
; 8/5/89        .000    Original.
; 9/29/93   .001    Absorbed into RLHSEG.
;----------------------------------------------------------------------
; Changes: AX
;----------------------------------------------------------------------
FIND_NEXT_MCB   PROC    FAR
		ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

		PUSH    DS                      ;Save register

		MOV     AX,CS:[R$MCBSEG]    ;Get Previous block
		MOV     DS,AX                   ;Point DS to it
	ASSUME  DS:NOTHING
		CMP     BYTE PTR DS:[0],"Z"     ;Z if last block
		JNE     FNM_1

		STC
FNM_EXIT:
		POP     DS
	ASSUME  DS:NOTHING

		RET
FNM_1:
	ASSUME  DS:NOTHING
		ADD     AX,DS:[3]       ;Add length of this block
		INC     AX                      ;Skip arena header

		MOV     CS:[R$MCBSEG],AX    ;Update segment

		CLC
		JMP     FNM_EXIT

FIND_NEXT_MCB   ENDP

RLHSEG      ENDS

;======================================================================
; This portion of the code is linked in with the other CSEG routines
; and gets swapped out during shelling.
;======================================================================
CSEG        SEGMENT WORD    PUBLIC  'CODE'
	ASSUME  CS:CSEG

;======================================================================
; R$SBUILD_MCB (Internal)
;   Copyright (c) 1991-1993 Schaefer Software, Robert L. Hummel
;   Copyright (c) 1991-1993 Crescent Software
;----------------------------------------------------------------------
; Entry:
;   CS=CSEG
;   DS=SS=DGROUP
; Exit :
;   CX:DX = Total size (in bytes) of all memory blocks owned by
;               R$PSPSEG except the environment + 2048 bytes for IVT.
;   R$MCB_TABLE = Loaded with blocks.
;----------------------------------------------------------------------
; The PSP block is fudged in the table to exclude the core routines.
;----------------------------------------------------------------------
; Changes: CX DX
;----------------------------------------------------------------------
R$SBUILD_MCB    PROC    FAR
	ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

		PUSH    AX          ;Preserve used registers
		PUSH    BX
		PUSH    SI
		PUSH    DI
		PUSH    ES
;----------------------------------------------------------------------
; Establish addressability to the table and initialize it.
; Note that the first entry in the table is reserved for the PSP seg.
;----------------------------------------------------------------------
		MOV AX,RLHSEG
		MOV ES,AX
	ASSUME  ES:RLHSEG

		MOV DI,OFFSET RLHSEG:R$MCB_TABLE+(2*2)
		MOV BX,[P$PSPSEG]       ;Get PSP segment
		MOV WORD PTR ES:[R$PSPSEG],BX   ;Save PSP (owner)
;----------------------------------------------------------------------
; Reserve room for the file name buffer (256 bytes) and the IVT (1024).
;----------------------------------------------------------------------
		MOV DX,10H + 2*(80H*4)/16   ;=1280 bytes
;----------------------------------------------------------------------
; Search the MCB chain and count the memory owned by this process.
;----------------------------------------------------------------------
		CALL    FIND_FIRST_MCB      ;Return in AX
;----------------------------------------------------------------------
; MCB is in AX. You've got to restore DS for FIND_NEXT_MCB.
;----------------------------------------------------------------------
BM_1A:
		PUSH    DS          ;Save DS

		MOV DS,AX           ;Point to MCB header
	ASSUME  DS:NOTHING

		CMP BX,WORD PTR DS:[1]  ;Owned by us?
		JNE BM_1D
;----------------------------------------------------------------------
; Block is owned by this PSP. Check if this is the PSP block.
;----------------------------------------------------------------------
		INC AX              ;Bump MCB segment
		CMP AX,BX           ;Equal if PSP
		JNE BM_1B
;----------------------------------------------------------------------
; Adjust the PSP block entry so that the starting para points to the
; end of the core, then adjust the length of this new block.
;----------------------------------------------------------------------
		MOV SI,RHSEG        ;Segment of END of RLHSEG
		MOV ES:[R$MCB_TABLE],SI ;New header address

		SUB SI,BX           ;Offset in paras

		MOV AX,DS:[3]       ;Original length
		MOV ES:[R$PSPLEN],AX    ; save it

		SUB AX,SI           ;Altered length
		MOV ES:[R$MCB_TABLE+2],AX
		JMP SHORT BM_1C
;----------------------------------------------------------------------
; Save paragraph of block and length.
;----------------------------------------------------------------------
BM_1B:
		MOV ES:[DI],DS      ;Header paragraph address
		MOV AX,WORD PTR DS:[3]  ;Length in paras
		INC AX          ;Add 1 para for MCB header
		MOV WORD PTR ES:[DI+2],AX   ;Save length in table
		ADD DI,4            ;Point to next entry
BM_1C:
		ADD DX,AX           ;Add length in paras
BM_1D:
;----------------------------------------------------------------------
; Start again for the next block.
;----------------------------------------------------------------------
		POP DS
	ASSUME  DS:DGROUP

		CALL    FIND_NEXT_MCB
		JNC BM_1A
;----------------------------------------------------------------------
; Convert paragraphs in AX to bytes in CX:DX.
;----------------------------------------------------------------------
		MOV AX,DX
		MOV CX,16
		MUL CX          ;DX:AX = AX*CX
		MOV CX,DX
		MOV DX,AX
;----------------------------------------------------------------------
; Restore registers and exit.
;----------------------------------------------------------------------
		POP ES
	ASSUME  ES:NOTHING
		POP DI
		POP SI
		POP BX
		POP AX
		RET

R$SBUILD_MCB    ENDP

;======================================================================
; R$SSWAPOUT (Internal)
;   Copyright (c) 1991-1993 Schaefer Software, Robert L. Hummel
;   Copyright (c) 1991-1993 Crescent Software
;----------------------------------------------------------------------
;1. This routine is responsible for copying the image of the program
;   from memory to disk.
;2. It assumes that R$BUILD has already been called, so the MCB table
;   already is built in memory.
;3. The swapped part of the PSP segment is always the first entry in the
;   table.
;----------------------------------------------------------------------
; Entry:
;   ES = RLHSEG
; Exit:
;   CF: NC, DX = new PSP length to save (in paras)
;       CY, Fatal error, do not shell
;----------------------------------------------------------------------
; Changes: AX BX CX DX SI DI ES
;----------------------------------------------------------------------
R$SSWAPOUT  PROC    FAR
	ASSUME  CS:CSEG, DS:NOTHING, ES:RLHSEG, SS:NOTHING
;----------------------------------------------------------------------
; Save the original DS, then point DS to the resident segment.
;----------------------------------------------------------------------
		PUSH    DS          ;Save original DS

		PUSH    ES
		POP DS
	ASSUME  DS:RLHSEG
;----------------------------------------------------------------------
; Position the swap file pointer to the first byte past the filename
; and IVT areas.
;----------------------------------------------------------------------
		SUB CX,CX           ;Start of file
		MOV     DX,R$IVBUFLEN+100H  ; past buffers
		CALL    FAR PTR R$SSEEKABS  ;In RLHSEG
		JC      RSS_EXIT
;----------------------------------------------------------------------
; Init the pointer to the MCB_TABLE entries.
;----------------------------------------------------------------------
		MOV     SI,OFFSET RLHSEG:R$MCB_TABLE
;----------------------------------------------------------------------
; 1. Get the address and length of a memory block.
;    A -1 in the table indicates no more entries.
;----------------------------------------------------------------------
RSS_2A:
		LODSW                   ;Fetch address DS:SI
		CMP     AX,-1           ;-1 = empty entry
		JE      RSS_3

		MOV     DI,AX           ;Save paragraph address
		LODSW                   ;Fetch block length in AX
;----------------------------------------------------------------------
; Can only write FFFFh bytes at a time to the file. If AX>FFFh paras,
; must perform multiple writes.
;----------------------------------------------------------------------
		MOV     BX,DI           ;Save for segment release

		MOV     CX,AX           ;AX contains paragraphs to write
RSS_2B:
		CMP     CX,0FFFH        ;Max paragraphs per write
		JBE     RSS_2C

		MOV     CX,0FFFH        ;Write this many bytes
RSS_2C:
		SUB     AX,CX           ;This many bytes remain
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

		SHL     CX,1        ;Multiply by 16
		SHL     CX,1
		SHL     CX,1
		SHL     CX,1

		PUSH    AX      ;Preserve regs
		PUSH    BX

		CALL    FAR PTR R$SWRITE

		POP     BX      ;Restore regs
		POP     AX

		POP     DS              ;Restore in case of error
	ASSUME  DS:RLHSEG
		JC      RSS_EXIT

		MOV     CX,AX           ;Retrieve paragraphs remaining
		OR      AX,AX           ;If 0, we're done
		JNZ     RSS_2B
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

		JMP     RSS_2A
;----------------------------------------------------------------------
; No more RAM blocks left to copy. Copy the current IVT (PDQ's) to the
; IVT buffer. Point DS:SI to the IVT and ES:DI to the buffer.
;----------------------------------------------------------------------
RSS_3:
;;;     MOV     DI,OFFSET RLHSEG:R$IVBUF
;;;     PUSH    DS
;;;     POP     ES
;;; ASSUME  ES:RLHSEG
;;;
;;;     SUB     SI,SI
;;;     MOV     DS,SI
;;; ASSUME  DS:LOMEM
;;;
;;;     MOV     CX,R$IVBUFLEN
;;;     SHR     CX,1
;;;     REP     MOVSW
;----------------------------------------------------------------------
; Adjust DX so that the PSP block will be shrunk to the correct size.
;----------------------------------------------------------------------
		MOV BX,DGROUP       ;Point DS to DGROUP
		MOV DS,BX
	ASSUME  DS:DGROUP

		MOV     DX,RHSEG        ;End of resident segment
		SUB     DX,WORD PTR [P$PSPSEG]  ; minus PSP start

		CLC             ;Success
RSS_EXIT:
		POP DS          ;Restore orginal DS
	ASSUME  DS:NOTHING
		RET

R$SSWAPOUT  ENDP

CSEG        ENDS

;======================================================================
; The combination of name and class force this code segment to be the
; first segment in memory when the program is linked with the correct
; stub file.
;======================================================================
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'
	ASSUME  CS:RLHSEG

;======================================================================
; SHELL2DISK (PDQ)
;   Copyright (c) 1993 Schaefer Software, Robert L. Hummel
;   Copyright (c) 1993 Crescent Software
;----------------------------------------------------------------------
; Usage:
;       Result%=Shell2Disk%(SwapFile$, Child$, CmdTail$)
; Where:
;       SwapFile$ - Name passed to DOS verbatim
;       Child$ - pathname of COM or EXE file to spawn
;   CmdTail$ - exact command tail for child program
; Returns:
;       Result% = Return code of child program if no error
;   PDQErr = status of exec call
;----------------------------------------------------------------------
; CHANGES: AX BX CX DX ES
;----------------------------------------------------------------------
SHELL2DISK  PROC    FAR
	ASSUME  CS:RLHSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP
;----------------------------------------------------------------------
; Establish the local stack frame.
;----------------------------------------------------------------------
		PUSH    BP          ;Create stack frame
		MOV     BP,SP

		PUSH    SI                  ;Save used regs
		PUSH    DI          ; req'd by PDQ
;----------------------------------------------------------------------
; Initialize the error variable. Address as byte per Ethan.
;----------------------------------------------------------------------
		MOV     BYTE PTR [P$PDQERR],0   ;In DGROUP
;----------------------------------------------------------------------
; Point ES to the resident core segment.
;----------------------------------------------------------------------
		PUSH    CS          ;Point ES
		POP ES          ; to RLHSEG
	ASSUME  ES:RLHSEG
;----------------------------------------------------------------------
; Parse the child program and the command tail into the exec structure.
;----------------------------------------------------------------------
		MOV BX,[BP+8]       ;Child$
		MOV CX,[BX]         ;Length

		CMP CX,127          ;Can't exceed 127
		JBE S2D_1A

		MOV AX,64           ;Bad file name
		JMP S2D_FAIL
S2D_1A:
		MOV SI,[BX+2]       ;String
		MOV DI,OFFSET RLHSEG:R$CHILD

		REP MOVSB           ;Copy it
		SUB AL,AL           ;Make ASCIIZ
		STOSB

		MOV BX,[BP+6]       ;Command tail
		MOV CX,[BX]         ;Length

		CMP CX,126          ; can't exceed 126
		JBE S2D_1B

		MOV AX,82           ;Invalid parameter
		JMP S2D_FAIL
S2D_1B:
		MOV SI,[BX+2]       ;String
		MOV DI,OFFSET RLHSEG:R$TAIL

		MOV AL,CL           ;AL = length
		STOSB               ;Write length
		REP MOVSB           ;Write string
		SUB AL,AL
		MOV BX,DI           ;Save destination
		STOSB               ;Write 0
;----------------------------------------------------------------------
; Then parse the command tail into the FCBs.
; DS:SI -> tail to parse
; ES:DI -> FCB
;----------------------------------------------------------------------
		PUSH    ES
		POP DS
	ASSUME  DS:RLHSEG

		MOV AX,2900H        ;Parse
		MOV SI,OFFSET RLHSEG:R$TAIL+1
		MOV DI,OFFSET RLHSEG:R$FCB1
		INT 21H

		MOV AX,2900H        ;Parse
		MOV DI,OFFSET RLHSEG:R$FCB2
		INT 21H

		MOV BYTE PTR [BX],13    ;Carriage return

		PUSH    SS
		POP DS
	ASSUME  DS:DGROUP
;----------------------------------------------------------------------
; Convert the swap file name to an ASCIIZ string.
;----------------------------------------------------------------------
		MOV     BX,WORD PTR [BP+0AH]    ;Filespec descriptor
		MOV     CX,WORD PTR [BX]    ;Length of string

		CMP CX,127          ;Max length
		JBE S2D_2A

		MOV AX,64           ;Bad file name
		JMP S2D_FAIL
S2D_2A:
		MOV     SI,WORD PTR [BX+2]  ;Offset of string

		MOV     DI,OFFSET RLHSEG:R$SWAPFILE
		MOV     DX,DI           ;Save for later write

		REP     MOVSB           ;Xfer string
		SUB     AL,AL           ;Add final 0 byte
		STOSB
;----------------------------------------------------------------------
; Open the swap file pointed to by DS:DX.
; If it exists, this procedure will truncate it and destroy it.
; If the open call fails, the DOS error code in AX is returned.
;----------------------------------------------------------------------
		PUSH    ES              ;DS:DX -> filename
		POP     DS      ; req'd for DOS call
	ASSUME  DS:RLHSEG

		MOV     AH,3CH          ;Open file (AX=hndl)
		SUB     CX,CX           ;Normal attributes
		INT     21H             ; thru DOS
		JNC     S2D_2C
S2D_2B:
		PUSH    SS      ;Point DS to DGROUP
		POP     DS      ; for exit
	ASSUME  DS:DGROUP

		CALL    P$DOERROR
		JMP     S2D_EXIT
S2D_2C:
	ASSUME  DS:RLHSEG
;----------------------------------------------------------------------
; Save the file handle (in AX) in the core module data.
;----------------------------------------------------------------------
		MOV     WORD PTR [R$SWAP_HANDLE],AX
;----------------------------------------------------------------------
; Write the filename to the file for consistency with swapping TSRs.
; DS:DX points to start of buffer where filename has been stored.
;----------------------------------------------------------------------
		MOV     BX,AX           ;Handle in BX
		MOV     AH,40H          ;Write to file
		MOV     CX,100H     ;Write 256 bytes from DS:DX
		INT     21H     ; thru DOS
		JC      S2D_2B

		PUSH    SS      ;Point DS to DGROUP
		POP     DS
	ASSUME  DS:DGROUP

		CMP     AX,CX       ;All bytes written?
		JE      S2D_3B
S2D_3A:
		MOV     AL,RE$DISKFULL  ;Generate error
		JMP     S2D_FAIL
S2D_3B:
;----------------------------------------------------------------------
; Build and save the MCB chain of our blocks.
;
; Returns 32-bit (CX:DX) number representing the amount of memory
; required to save the program. Size is padded by 256+1024 bytes to
; accomodate the filename and IVT (saved by swapping TSRs).
;----------------------------------------------------------------------
		CALL    R$SBUILD_MCB    ;Far call wrapper
;----------------------------------------------------------------------
; Remove the environment segment from the MCB list. The environment
; must be left intact if the child is to inherit a copy of it.
;----------------------------------------------------------------------
		PUSH    ES
		POP DS          ;DS=RLHSEG
	ASSUME  DS:RLHSEG

		MOV SI,OFFSET RLHSEG:R$MCB_TABLE

		MOV AX,[SI-2]       ;This PSP segment
		MOV ES,AX
	ASSUME  ES:NOTHING
		MOV AX,ES:[2CH]     ;Our env segment
		DEC AX          ;Past MCB header

		PUSH    DS          ;Prepare for string move
		POP ES
	ASSUME  ES:RLHSEG
S2D_4A:
		CMP WORD PTR [SI],-1    ;End of table?
		JE  S2D_4C

		CMP AX,[SI]         ;Is this Env seg?
		JE  S2D_4B

		ADD SI,4            ;Point to next entry
		JMP S2D_4A
S2D_4B:
;----------------------------------------------------------------------
; Remove the environment entry from the table.
; Don't adjust the file size -- to maintain compatibility.
;----------------------------------------------------------------------
		PUSH    SI          ;Save SI

		MOV DI,SI           ;Point DI to
		ADD SI,4            ; next table entry

		MOV CX,OFFSET RLHSEG:R$MCB_TABLE + 64
		SUB CX,SI
		REP MOVSB

		POP SI          ;Restore SI
S2D_4C:
		PUSH    SS
		POP DS
	ASSUME  DS:DGROUP
;----------------------------------------------------------------------
; Set the file size by moving the pointer to the signed offset
; from the beginning as specified in CX:DX. This function must complete
; without error. The pointer must be where we told it to go.
;----------------------------------------------------------------------
		MOV     SI,DX           ;Save low part of size

		MOV     AX,4200H        ;Set pointer CX:DX from start
		INT     21H
		JC      S2D_2B          ;Call P$DOERROR
;----------------------------------------------------------------------
; Write 1 byte from DS:DX to cement the size. (The location of DS:DX is
; irrelevant. The file will be 1 byte larger than required, but it's
; not worth the code to eliminate it.
;----------------------------------------------------------------------
		MOV     AH,40H          ;Write to file
							;BX=handle
		MOV     CX,1            ;1 byte
		INT     21H             ; thru DOS
		JC      S2D_2B

		CMP     AX,CX       ;Requested bytes written?
		JNE     S2D_3A
;----------------------------------------------------------------------
; Get a duplicate handle for the file referenced by BX and return in
; AX. Close the duplicate handle to commit the current file length.
;----------------------------------------------------------------------
		MOV     AH,45H          ;Return dupe handle in AX
							;BX=handle to dupe
		INT     21H             ; thru DOS
		JC      S2D_2B

		MOV     BX,AX           ;Take the duplicate
		MOV     AH,3EH          ;Close handle
		INT     21H             ; thru DOS
		JC      S2D_2B
;----------------------------------------------------------------------
; Swap stacks before releasing memory. After this, there is no
; graceful recovery.
;----------------------------------------------------------------------
		MOV CS:[R$PDQSS],SS     ;Save old stack
		MOV CS:[R$PDQSP],SP

		PUSH    CS              ;Stack in this seg
		POP SS
	ASSUME  SS:RLHSEG
		MOV SP,OFFSET R$STACK   ;Top of new stack
;----------------------------------------------------------------------
; Copy the MCBs from memory to disk as directed by the table.
; Release all MCBs excluding the PSP.
;
; Returns DX set to the required resident length for the PSP block.
;----------------------------------------------------------------------
		CALL    R$SSWAPOUT      ;In CSEG
;----------------------------------------------------------------------
; Close the swap file so the child doesn't inherit it.
; If an error occurs, we save it, but we'll ignore it.
;----------------------------------------------------------------------
		PUSH    CS
		POP DS
	ASSUME  DS:RLHSEG

		MOV AH,3EH          ;Close handle
		MOV BX,[R$SWAP_HANDLE]  ;In RLHSEG
		INT 21H         ; thru DOS
		JNC S2D_5

		MOV [R$PDQERR],AX       ;Save error locally
S2D_5:
;----------------------------------------------------------------------
; Shrink the PSP so it contains only RLHSEG and RHSEG.
; If an error occurs here, it's fatal.
;----------------------------------------------------------------------
		MOV AH,4AH          ;Size memory block
		MOV BX,DX           ;New size in paras
		MOV ES,[R$PSPSEG]       ;This segment
	ASSUME  ES:NOTHING
		INT 21H         ; thru DOS
		JNC S2D_5B
;----------------------------------------------------------------------
; Fatal error: Attempt to display message and halt the machine. Don't
; assume any registers.
;----------------------------------------------------------------------
S2D_HALT:   PUSH    CS
		POP DS
	ASSUME  DS:RLHSEG
		MOV CX,HUNG_LEN
		MOV SI,OFFSET RLHSEG:HUNG_MSG
S2D_H1:
		MOV AH,0AH
		MOV AL,[SI]
		INC SI
		SUB BX,BX
		INT 10H
		LOOP    S2D_H1

S2D_H2:     JMP S2D_H2



;----------------------------------------------------------------------
; EXEC the child program. It can fail without causing a problem.
;----------------------------------------------------------------------
S2D_5B:
		PUSH    CS
		POP ES
	ASSUME  ES:RLHSEG

		MOV BX,OFFSET RLHSEG:R$XCB
		MOV DX,OFFSET RLHSEG:R$CHILD

		MOV AX,4B00H        ;Exec program
		INT 21H             ; thru DOS
		
;----------------------------------------------------------------------
; Return from the EXEC call.
; Assume all registers are destroyed -- including stack.
;----------------------------------------------------------------------
		CLI
		MOV BX,RLHSEG           ;Set back to
		MOV SS,BX               ; temp stack
	ASSUME  SS:RLHSEG
		MOV SP,OFFSET RLHSEG:R$STACK
		STI

		MOV DS,BX
	ASSUME  DS:RLHSEG

		JNC S2D_6
		MOV [R$PDQERR],AX       ;Save error
S2D_6:
;----------------------------------------------------------------------
; Retrieve the child's termination code in AL with a DOS call.
;----------------------------------------------------------------------
		MOV AH,4DH              ;Get return code
		INT 21H                 ; thru DOS

		SUB AH,AH               ;Clear high byte
		MOV [R$RTNCODE],AX      ;Save it


;----------------------------------------------------------------------
; Re-expand the PSP segment to its original size.
;----------------------------------------------------------------------
		MOV ES,[R$PSPSEG]       ;The PSP segment
	ASSUME  ES:NOTHING
		MOV BX,[R$PSPLEN]       ;Its full size

		MOV AH,4AH              ;Resize memory block
		INT 21H                 ; thru DOS
		JC  S2D_HALT
;----------------------------------------------------------------------
; Re-allocate the same MCBs that we had before. Good heavens!
; At this point, the PSP has been restored to its correct size.
;----------------------------------------------------------------------
		CALL    MCB_MAGIC
		JC  S2D_HALT
;----------------------------------------------------------------------
; Open the swap file again.
;----------------------------------------------------------------------
		MOV AX,3D00H        ;Open handle
		SUB CX,CX           ;Normal attributes
		MOV DX,OFFSET RLHSEG:R$SWAPFILE
		INT 21H         ; thru DOS
		JC  S2D_HALT

		MOV [R$SWAP_HANDLE],AX
;----------------------------------------------------------------------
; Reload the program code.
;----------------------------------------------------------------------
		CALL    R$SSWAPIN
		JC  S2D_HALT
;----------------------------------------------------------------------
; After this point, the program has been successfully restored.
; Delete the swap file.
;----------------------------------------------------------------------
		MOV AH,3EH          ;Close handle
		MOV BX,[R$SWAP_HANDLE]
		INT 21H         ; thru DOS
		JNC S2D_7
		MOV [R$PDQERR],AX       ;Save the error
S2D_7:
		MOV AH,41H          ;Delete file
		MOV DX,OFFSET RLHSEG:R$SWAPFILE
		INT 21H         ; thru DOS
		JNC S2D_8
		MOV [R$PDQERR],AX
S2D_8:
;----------------------------------------------------------------------
; Restore the PDQ stack.
;----------------------------------------------------------------------
		MOV AX,[R$PDQSS]
		MOV SS,AX
	ASSUME  SS:DGROUP
		MOV SP,[R$PDQSP]

		PUSH    SS
		POP DS
	ASSUME  DS:DGROUP

		MOV AX,CS:[R$PDQERR]    ;Get error from core
;----------------------------------------------------------------------
; End with an error code in AX.
;----------------------------------------------------------------------
	ASSUME  DS:DGROUP
S2D_FAIL:
		MOV     [P$PDQERR],AX
;----------------------------------------------------------------------
; Common exit.
;----------------------------------------------------------------------
S2D_EXIT:
		MOV AX,[R$RTNCODE]
		POP     DI          ;Restore registers
		POP     SI
		POP     BP
		RET     2*2         ;Return to PDQ

SHELL2DISK  ENDP

;======================================================================
; R$SSEEKABS (Internal)
;   Copyright (c) 1991-1993 Schaefer Software, Robert L. Hummel
;   Copyright (c) 1991-1993 Crescent Software
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
R$SSEEKABS  PROC    FAR
	ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

		MOV     AX,4200H        ;Move file pointer CX:DX
		MOV     BX,WORD PTR CS:[R$SWAP_HANDLE]
		INT     21H             ;Thru DOS
		RET

R$SSEEKABS  ENDP







;======================================================================
; R$SSWAPIN (Internal)
;   Copyright (c) 1991-1993 Schaefer Software, Robert L. Hummel
;   Copyright (c) 1991-1993 Crescent Software
;
; 12/04/93  .001 PP Relocate PUSH DS to RSI_2B for MCB > 0x0FFF paras
;----------------------------------------------------------------------
; Entry: None
; Exit : CF = error status
;----------------------------------------------------------------------
; Changes: AX BX CX DX SI DI DS ES
;----------------------------------------------------------------------
R$SSWAPIN   PROC    NEAR
	ASSUME  CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:RLHSEG
;----------------------------------------------------------------------
; Position the file pointer past the filename and IVT area.
;----------------------------------------------------------------------
		SUB     CX,CX           ;Offset is CX:DX
		MOV     DX,R$IVBUFLEN + 100H
		CALL    R$SSEEKABS
		JC      RSI_EXIT
;----------------------------------------------------------------------
; Point DS:SI to the MCB_TABLE entries.
;----------------------------------------------------------------------
		MOV     SI,OFFSET RLHSEG:R$MCB_TABLE
;----------------------------------------------------------------------
; Get the address of an address block. -1 indicates the end of table.
;----------------------------------------------------------------------
RSI_1A:
		LODSW               ;AX=Dest seg
		CMP AX,-1           ;End of table?
		JNE RSI_1B

		CLC                 ;Success
RSI_EXIT:
		RET
RSI_1B:
;----------------------------------------------------------------------
; Retrieve the size of the block to restore.
;----------------------------------------------------------------------
		MOV DI,AX           ;Save para address
		LODSW               ;AX = block length
		MOV CX,AX           ;CX = paras to read

;----------------------------------------------------------------------
; If > FFFh paras, must perform multiple reads from the file.
;----------------------------------------------------------------------
RSI_2B:
		PUSH    DS          ;(R$SSWAPIN .001)
		CMP CX,0FFFH        ;Max permissible
		JBE RSI_2C

		MOV CX,0FFFH        ;Write this many
RSI_2C:
		SUB AX,CX           ;AX=paras remaining
;----------------------------------------------------------------------
; Point DS:DX to the destination in memory.
;----------------------------------------------------------------------
		MOV DS,DI           ;Point DS to MCB
	ASSUME  DS:NOTHING
		SUB DX,DX           ; DX = offset 0

		ADD DI,CX           ;Advance dest address

		SHL CX,1            ;Convert CX to bytes
		SHL CX,1
		SHL CX,1
		SHL CX,1

		PUSH    AX          ;Preserve registers
		PUSH    BX
		CALL    R$SREAD         ;Copy to memory
		POP BX
		POP AX

		POP DS
	ASSUME  DS:RLHSEG

		JC  RSI_EXIT
;----------------------------------------------------------------------
; If more paras remain to be filled, repeat the process.
;----------------------------------------------------------------------
		MOV CX,AX           ;Paras remaining
		OR  AX,AX           ;None left?
		JNZ RSI_2B

;----------------------------------------------------------------------
; This block was completed. Move to the next MCB.
;----------------------------------------------------------------------
		JMP RSI_1A

R$SSWAPIN   ENDP














;======================================================================
; MCB_MAGIC (Internal)
;   Copyright (c) 1993 Schaefer Software, Robert L. Hummel
;   Copyright (c) 1993 Crescent Software
;----------------------------------------------------------------------
; This routine has the non-enviable task of attempting to restore the
; same memory configuratio that existed before we shelled.
;----------------------------------------------------------------------
; Entry:
;   CS=DS=SS=RLHSEG
;----------------------------------------------------------------------
MCB_MAGIC   PROC    NEAR
	ASSUME  CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:NOTHING
;----------------------------------------------------------------------
; Loop through the table of pre-shell segments. Skip the first entry --
; the fudged PSP -- because it has already been restored.
;----------------------------------------------------------------------
		MOV SI,OFFSET RLHSEG:R$MCB_TABLE + 4
MM_0A:
		MOV DI,[SI]         ;Header
		CMP DI,-1           ;End of table?
		JNE MM_0B

		CLC             ;Success
MM_EXIT:
		RET
MM_0B:
;----------------------------------------------------------------------
; Set Blo to the first memory block.
;----------------------------------------------------------------------
		CALL    FIND_FIRST_MCB      ;Returns AX
		MOV CX,AX           ;Put into Blo
;----------------------------------------------------------------------
; Find the next memory block. If no more blocks, select Blo.
;----------------------------------------------------------------------
MM_1:
		CALL    FIND_NEXT_MCB       ;Bhi = next block
		JC  MM_3A
;----------------------------------------------------------------------
; Is Bhi > Breq? If so, Blo is the block we need to test.
;----------------------------------------------------------------------
		CMP AX,DI           ;CMP Bhi,Breq
		JA  MM_3A
;----------------------------------------------------------------------
; Abandon this Blo, but make sure it won't get allocated by mistake.
; 1. If Len(Blo) < Len(Breq), it can be skipped.
; 2. If Blo is not free, it can be skipped.
; Otherwise, mark it as used temporarily.
;----------------------------------------------------------------------
		MOV ES,CX           ;ES -> Blo
	ASSUME  ES:NOTHING

		CMP WORD PTR ES:[1],0   ;Is Blo free?
		JNE MM_2A

		MOV BX,ES:[3]       ;Len(Blo)
		MOV DX,[SI+2]
		DEC DX
		CMP BX,DX           ;cmp Len(Blo),Len(Breq)
		JAE MM_2B
MM_2A:
		MOV CX,AX           ;Set Blo=Bhi
		JMP MM_1
MM_2B:
		MOV WORD PTR ES:[1],0FFFEH  ;Our signature
		JMP MM_1
;----------------------------------------------------------------------
; Blo is the eligible block.
; If Blo is after Breq in memory, memory is corrupt.
;----------------------------------------------------------------------
MM_3A:
		CMP CX,DI           ;Blo:Breq
		JNA MM_3C
MM_3B:
		STC
		JMP MM_EXIT
MM_3C:
;----------------------------------------------------------------------
; If Blo is not free, memory is corrupt.
;----------------------------------------------------------------------
		MOV AX,CX           ;Blo header
		MOV ES,AX           ;Point ES
	ASSUME  ES:NOTHING

		CMP WORD PTR ES:[1],0   ;Is Blo free?
		JNE MM_3B
;----------------------------------------------------------------------
; If Blo is smaller than Breq, memory is corrupt.
;----------------------------------------------------------------------
		MOV AX,ES:[3]       ;Len(Blo)
		MOV DX,[SI+2]
		DEC DX
		CMP AX,DX           ;cmp Len(Blo),Len(Breq)
		JB  MM_3B
;----------------------------------------------------------------------
; If Blo is lower in memory than Breq, we have to temporarily allocate
; a buffer block. (Can only be lower or equal.)
;----------------------------------------------------------------------
		CMP CX,DI           ;Cmp Blo,Breq
		JNB MM_4

		MOV BX,DI           ;Breq
		SUB BX,CX           ; -Blo
		DEC BX          ; -1 for new header

		MOV AH,48H          ;Allocate memory
		INT 21H         ; thru DOS
		JC  MM_3B

		MOV [R$MBUF],AX     ;Save pad segment
MM_4:
;----------------------------------------------------------------------
; Re-allocate the desired segment.
;----------------------------------------------------------------------
		MOV AH,48H          ;Allocate memory
		MOV BX,DX           ;Len(Blo)
		INT 21H         ; thru DOS
		JC  MM_3B
;----------------------------------------------------------------------
; Release the buffer segment if req'd.
;----------------------------------------------------------------------
		SUB AX,AX           ;Zero
		XCHG    AX,[R$MBUF]     ;Fetch & clear
		OR  AX,AX           ;Seg allocated?
		JZ  MM_6

		MOV ES,AX           ;This segment
		MOV AH,49           ;Release it
		INT 21H         ; thru DOS
MM_6:
;----------------------------------------------------------------------
; Scan to free any blocks that we've marked with our signature.
;----------------------------------------------------------------------
		CALL    FIND_FIRST_MCB
MM_7A:
		MOV ES,AX
	ASSUME  ES:NOTHING
		CMP WORD PTR ES:[1],0FFFEH  ;Our signature?
		JNE MM_7B

		MOV WORD PTR ES:[1],0   ;Clear it
MM_7B:
		CALL    FIND_NEXT_MCB
		JNC MM_7A
;----------------------------------------------------------------------
; Advance to the next table entry.
;----------------------------------------------------------------------
		ADD SI,4            ;Next table entry
		JMP MM_0A

MCB_MAGIC   ENDP

;======================================================================
; R$SWRITE
;   Copyright (c) 1991-1993 Schaefer Software, Robert L. Hummel
;   Copyright (c) 1991-1993 Crescent Software
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
R$SWRITE    PROC    FAR
	ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

		MOV     AH,40H          ;Write to file
		MOV     BX,WORD PTR CS:[R$SWAP_HANDLE]
		INT     21H
		RET

R$SWRITE    ENDP

;======================================================================
; RD$READ
;   Copyright (c) 1991-1993 Schaefer Software, Robert L. Hummel
;   Copyright (c) 1991-1993 Crescent Software
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
R$SREAD     PROC    NEAR
	ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

		MOV     AH,3FH          ;Write to file
		MOV     BX,WORD PTR CS:[R$SWAP_HANDLE]
		INT     21H
		RET

R$SREAD     ENDP

RLHSEG      ENDS
		END

