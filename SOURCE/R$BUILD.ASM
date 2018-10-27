;======================================================================
; R$BUILD.ASM
;----------------------------------------------------------------------
;  Copyright (c) 1991 Crescent Software
;  Copyright (c) 1991 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 9/21/91	.000	Original
; 9/23/91	.001	Bring MCB table local.
; 9/24/91	.002	Save header as part of block.
;		.003	Allocate space for IVT; Fudge PSP/CORE.
;		.004	Force PSP to be first table entry.
; 10/10/91	.005	Redo externals.
; 10/11/91	.006	Reserve room for filename.
;======================================================================
PUBLIC	R$BUILD_MCB	;NEAR, Internal
PUBLIC	R$MCB_TABLE	;Word

;======================================================================
; Externals.
;----------------------------------------------------------------------
CSEG		SEGMENT	WORD	PUBLIC	'CODE'

EXTRN   FIND_FIRST_MCB:NEAR
EXTRN   FIND_NEXT_MCB:NEAR

CSEG		ENDS

;======================================================================
;
;----------------------------------------------------------------------
RLHSEG		SEGMENT	PARA	PUBLIC	'RLH_CODE'

		DW	-1	;Holds PSP. Must directly preceded table
R$MCB_TABLE	DW	16 DUP(-1,-1)

RLHSEG		ENDS

;======================================================================
; Describes end of RLHSEG
;----------------------------------------------------------------------
RHSEG		SEGMENT	PARA	PUBLIC	'RH_CODE'
RHSEG		ENDS

;======================================================================
;
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE	R$PDQ.EQU			;Standard includes

EXTRN	P$PSPSEG:WORD	;In PDQDATA.ASM

DSEG            ENDS

;======================================================================
; This portion of the code is linked in with the other CSEG routines
; and does not remain in memory.
;----------------------------------------------------------------------
CSEG		SEGMENT	WORD	PUBLIC	'CODE'
	ASSUME	CS:CSEG

;======================================================================
; R$BUILD_MCB (Internal)
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Called only once from CSEG.
;----------------------------------------------------------------------
; Entry: None
; Exit :
;	CX:DX = Total size (in bytes) of all memory blocks owned by
;               R$PSPSEG + 2048 bytes for IVT.
;	R$MCB_TABLE = Loaded with blocks.
;----------------------------------------------------------------------
;1. The PSP blocks is fudged in the table to exclude the core routines.
;----------------------------------------------------------------------
; Changes: CX, DX
;----------------------------------------------------------------------
R$BUILD_MCB	PROC	NEAR
	ASSUME	CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

		PUSH	AX			;Preserve used registers
		PUSH	BX
		PUSH	SI
		PUSH	DI
		PUSH	ES
;----------------------------------------------------------------------
; Establish addressability to the table and initialize it.
; Note that the first entry in the table is reserved for the PSP seg.
;----------------------------------------------------------------------
		MOV	AX,RLHSEG
		MOV	ES,AX
	ASSUME	ES:RLHSEG
		MOV	DI,OFFSET RLHSEG:R$MCB_TABLE+(2*2)

		MOV	BX,WORD PTR [P$PSPSEG]
		MOV	WORD PTR ES:[DI-6],BX	;Save PSP (owner)
;----------------------------------------------------------------------
; Reserve room for the file name buffer and the interrupt vector table.
;----------------------------------------------------------------------
		MOV	DX,10H + 2*(80H*4)/16
;----------------------------------------------------------------------
; Seach the MCB chain and count the memory owned by this process.
;----------------------------------------------------------------------
		CALL	FIND_FIRST_MCB		;Return in AX
;----------------------------------------------------------------------
; You've got to restore DS for FIND_NEXT_MCB.
;----------------------------------------------------------------------
BM_1A:
		PUSH	DS

		MOV	DS,AX
	ASSUME	DS:NOTHING

		CMP	BX,WORD PTR DS:[1]	;Owner field
		JNE	BM_2
;----------------------------------------------------------------------
; Block we scanned is owned by this PSP.
; If this is the PSP block, fudge it.
;----------------------------------------------------------------------
		INC	AX			;Bump MCB segment
		CMP	AX,BX			;Equal if PSP
		JNE	BM_1B
;----------------------------------------------------------------------
; PSP block.
; 1. Must adjust starting para to point to end of core.
; 2. Must adjust length.
;----------------------------------------------------------------------
		MOV	SI,RHSEG		;Segment of END of RLHSEG
		MOV	WORD PTR ES:[R$MCB_TABLE],SI	;New header address

		SUB	SI,BX			;Offset in paras
		MOV	AX,WORD PTR DS:[3]	;Original length
		SUB	AX,SI			;Altered length
		MOV	WORD PTR ES:[R$MCB_TABLE+2],AX
		JMP	SHORT BM_1C
;----------------------------------------------------------------------
; Save paragraph of block and length.
;----------------------------------------------------------------------
BM_1B:
		MOV	ES:[DI],DS		;Header paragraph address
		MOV	AX,WORD PTR DS:[3]	;Length
		INC	AX			; add 16 for header

		MOV	WORD PTR ES:[DI+2],AX	;Save it

		ADD	DI,4			;Point to next entry
BM_1C:
		ADD	DX,AX			;Total length up.
;----------------------------------------------------------------------
; Start again for the next block.
;----------------------------------------------------------------------
BM_2:
		POP	DS
	ASSUME	DS:DGROUP

		CALL	FIND_NEXT_MCB
		JNC	BM_1A
;----------------------------------------------------------------------
; Convert AX in paragraphs to CX:DX in bytes.
;----------------------------------------------------------------------
		MOV	AX,DX
		MOV	CX,16
		MUL	CX			;DX:AX = AX*CX
		MOV	CX,DX
		MOV	DX,AX
;----------------------------------------------------------------------
; Restore registers and exit.
;----------------------------------------------------------------------
		POP	ES
		POP	DI
		POP	SI
		POP	BX
		POP	AX
		RET

R$BUILD_MCB	ENDP

CSEG		ENDS
		END
