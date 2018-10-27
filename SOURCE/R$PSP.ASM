; R$PSP.ASM
;----------------------------------------------------------------------
; Copyright (c) 1990 Crescent Software
; Copyright (c) 1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 6/21/90	.000	Original.
; 6/23/90	.001	Check major version number.
;----------------------------------------------------------------------
PUBLIC	R$GETPSP ;NEAR
PUBLIC	R$SETPSP ;NEAR

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU

EXTRN	P$DOSVER:WORD

DSEG            ENDS

;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'

EXTRN	R$DOSCRIT:DWORD

USEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

;======================================================================
; R$GETPSP (INTERNAL)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Internal routine to get the current PSP. Works around the DOS 2.x bug.
;----------------------------------------------------------------------
; Entry: none
; Exit:  BX = current PSP
;----------------------------------------------------------------------
; Changes: AX, BX
;----------------------------------------------------------------------
R$GETPSP	PROC	NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

		MOV	AH,51H

		CMP	BYTE PTR [P$DOSVER],2
		JE	GET_1

		INT	21H
GET_EXIT:
		RET
;----------------------------------------------------------------------
; Work around DOS 2.x bug.
;----------------------------------------------------------------------
GET_1:
		CALL	R$DOS2FIX
		JMP	GET_EXIT

R$GETPSP	ENDP


;======================================================================
; R$SETPSP (INTERNAL)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Internal routine to set the current PSP. Works around the DOS 2.x bug.
;----------------------------------------------------------------------
; Entry: BX = PSP to make active
; Exit:  none
;----------------------------------------------------------------------
; Changes: AX
;----------------------------------------------------------------------
R$SETPSP	PROC	NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

		MOV	AH,50H

		CMP	BYTE PTR [P$DOSVER],2
		JE	SET_1

		INT	21H
SET_EXIT:
		RET
;----------------------------------------------------------------------
; Work around DOS 2.x bug.
;----------------------------------------------------------------------
SET_1:
		CALL	R$DOS2FIX
		JMP	SET_EXIT

R$SETPSP	ENDP


;======================================================================
; R$DOS2FIX (INTERNAL)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Sets the critical error flag so DOS 2.x doesn't screw up its I/O
;    stack when working with PSP calls.
;----------------------------------------------------------------------
; Entry: AH = INT 21h function to process
; Exit:  what you'd normally expect
;----------------------------------------------------------------------
; Changes: none
;----------------------------------------------------------------------
R$DOS2FIX	PROC	NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

		PUSH	DS
		PUSH	BX

		LDS	BX,DWORD PTR [R$DOSCRIT]
	ASSUME	DS:NOTHING
		INC	BYTE PTR [BX]

		POP	BX
		POP	DS
	ASSUME	DS:DGROUP

		INT	21H

		PUSH	DS
		PUSH	BX

		LDS	BX,DWORD PTR [R$DOSCRIT]
	ASSUME	DS:NOTHING
		DEC	BYTE PTR [BX]

		POP	BX
		POP	DS
	ASSUME	DS:DGROUP

		RET

R$DOS2FIX	ENDP

CSEG            ENDS
                END
