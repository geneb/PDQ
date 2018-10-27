;======================================================================
; B$PCR8.ASM
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 2/17/91	.000	Original.
;----------------------------------------------------------------------
PUBLIC	B$PCR8	;FAR (QB)

;----------------------------------------------------------------------
; FAR Externals
;----------------------------------------------------------------------
EXTRN		B$PCSD:FAR
EXTRN		B$STR8:FAR

;======================================================================
; DGROUP addressing fixed up by linker.
; DSEG: Initialized data.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
DSEG            ENDS

;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'

RET_ADR		DD	1 DUP (?)

USEG            ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG04		SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG04, DS:DGROUP, ES:NOTHING, SS:DGROUP

;======================================================================
; B$PCR8:FAR (QB)
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; INPUT:
;	STACK = 8-byte real to be converted.
;		WORD0 = BP+6	;Least significant part
;		WORD1 = BP+8
;		WORD2 = BP+0AH
;		WORD3 = BP+0CH	;Sign + exponent part
;----------------------------------------------------------------------
; CHANGES: AX, BX, CX, DX, ES, FLAGS
;----------------------------------------------------------------------
B$PCR8		PROC	FAR
        ASSUME  CS:CSEG04, DS:DGROUP, ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
; Since the real number has already been pushed, just remove our
; return address and save it. Then call the num to string routine. This
; cleans the stack.
;----------------------------------------------------------------------
		POP	WORD PTR [RET_ADR]
		POP	WORD PTR [RET_ADR][2]

		CALL	B$STR8
;----------------------------------------------------------------------
; Now push the returned string descriptor and print it.
;----------------------------------------------------------------------
		PUSH	AX
		CALL	B$PCSD
;----------------------------------------------------------------------
; Return to caller.
;----------------------------------------------------------------------
		JMP	DWORD PTR [RET_ADR]

B$PCR8		ENDP

CSEG04		ENDS
		END
