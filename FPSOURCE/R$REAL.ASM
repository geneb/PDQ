;======================================================================
; R$REAL.ASM
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 2/18/91	.000	Original.
;----------------------------------------------------------------------

;======================================================================
; DGROUP addressing fixed up by linker.
; DSEG: Initialized data.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU

D87	MACRO
	ENDM

;----------------------------------------------------------------------
; The binary powers of ten as represented as binary real numbers.
;----------------------------------------------------------------------
PUBLIC		POSPOWER
PUBLIC		R_10
PUBLIC		R_100
PUBLIC		NEGPOWER

POSPOWER	EQU	$
R_10		DQ	1.0E+1
R_100		DQ	1.0E+2
		DQ	1.0E+4
		DQ	1.0E+8
		DQ	1.0E+16
		DQ	1.0E+32
		DQ	1.0E+64
		DQ	1.0E+128
		DQ	1.0E+256

NEGPOWER	DQ	1.0E-1
		DQ	1.0E-2
		DQ	1.0E-4
		DQ	1.0E-8
		DQ	1.0E-16
		DQ	1.0E-32
		DQ	1.0E-64
		DQ	1.0E-128
		DQ	1.0E-256

DSEG            ENDS
;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'
USEG            ENDS

		END
