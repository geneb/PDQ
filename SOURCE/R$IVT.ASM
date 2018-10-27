;======================================================================
; R$IVT.ASM
;  Copyright (c) 1991-1994 Crescent Software
;  Copyright (c) 1991-1994 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 10/8/91	.000	Split from SWAPDISK.ASM
; 7/3/94	.001	Force direction flag forward
;----------------------------------------------------------------------
PUBLIC	R$SWAPIVT	;NEAR, internal

;======================================================================
; Externals.
;----------------------------------------------------------------------
RLHSEG		SEGMENT	PARA	PUBLIC	'RLH_CODE'

EXTRN	R$IVBUF:BYTE	;In POPSWAP.ASM

RLHSEG		ENDS

;======================================================================
; A convenient alias for 0 when playing with the interrupt table.
;----------------------------------------------------------------------
LOMEM		SEGMENT	AT	0000H
LOMEM		ENDS

;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU

DSEG            ENDS

;======================================================================
; Resident code.
;----------------------------------------------------------------------
RLHSEG		SEGMENT	PARA	PUBLIC	'RLH_CODE'
	ASSUME	CS:RLHSEG

;======================================================================
; R$SWAPIVT (Internal)
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Swap the current interrupt vector table with the one in the buffer.
;----------------------------------------------------------------------
; Entry:
;	R$IVBUF = IVT to be loaded
; Exit:
;	R$IVBUF = IVT that was replaced
;----------------------------------------------------------------------
; Changes: CX, SI, DI, DS, ES
;----------------------------------------------------------------------
R$SWAPIVT	PROC	NEAR
        ASSUME  CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:NOTHING
		CLD				;String moves forward
;----------------------------------------------------------------------
; Point DS:SI to the buffer. Point ES:DI to the IVT.
;----------------------------------------------------------------------
		MOV	SI,OFFSET RLHSEG:R$IVBUF ;Beginning of buffer
		PUSH	CS
		POP	DS
	ASSUME	DS:RLHSEG

		SUB	DI,DI
		MOV	ES,DI
	ASSUME	ES:LOMEM

		MOV	CX,100H			;Number of int vectors
SIVT_1:
		LODSW				;Load offset from buf
		MOV	BX,AX
		LODSW				; and segment from buf

		CLI
		XCHG	BX,WORD PTR ES:[DI]	;Swap offset
		XCHG	AX,WORD PTR ES:[DI+2]	; and segment
		STI

		ADD	DI,4			;Advance IVT pointer
		MOV	WORD PTR [SI-4],BX	;Save old offset
		MOV	WORD PTR [SI-2],AX	; and segment

		LOOP	SIVT_1
		RET

R$SWAPIVT	ENDP

RLHSEG		ENDS
		END
