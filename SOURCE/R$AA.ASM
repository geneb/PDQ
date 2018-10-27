;======================================================================
; R$AA.ASM
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 10/10/91	.000	Original.
; 10/11/91	.001	Patch for IRET. Add publics.
; 10/13/91	.002	Return code in DX.
; 10/14/91	.003	Add R$UNHOOKAA.
;----------------------------------------------------------------------
PUBLIC	R$HOOKAA	;NEAR, CSEG

PUBLIC	pOLDINTAA	;DWORD, RLHSEG
PUBLIC	R$UNHOOKAA	;NEAR, RLHSEG
PUBLIC	INT_AA		;FAR, RLHSEG

;======================================================================
; Externals
;----------------------------------------------------------------------
RLHSEG		SEGMENT	PARA	PUBLIC	'RLH_CODE'

EXTRN	R$PROGID:WORD	;In POPSWAP.ASM

EXTRN	REQ_TIMER:WORD	;In R$CORE.ASM
EXTRN	R$SWAPCODE:WORD	;In R$CORE.ASM
EXTRN	R$IRET:NEAR	;In R$CORE.ASM

EXTRN	RESTORE_INT:NEAR	;In R$UNHOOK.ASM

RLHSEG		ENDS

;======================================================================
; Externals
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

EXTRN	SET_INT:NEAR	;In POPUP.ASM

CSEG		ENDS

;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU

DSEG            ENDS

;======================================================================
; Resident code segment.
;----------------------------------------------------------------------
RLHSEG		SEGMENT	PARA	PUBLIC	'RLH_CODE'
	ASSUME	CS:RLHSEG

;======================================================================
; INT_AA (Internal)
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. External hook to PDQ swapping core.
;----------------------------------------------------------------------
; Entry:
;	AX = Program ID
;	BX = Command to give to program
;	CX = Number of tick to try for
; Exit:
;	DX = TRUE, if request accepted
;	     FALSE, if not
;----------------------------------------------------------------------
INT_AA          PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

		CMP	AX,WORD PTR CS:[R$PROGID]
		JE	IAA_2
;----------------------------------------------------------------------
; If program ID doesn't match, pass on to earlier handlers.
; If next handler is invalid, code is patched to simply IRET.
;----------------------------------------------------------------------
IAA_1:
R$IAA$1		LABEL	BYTE
                PUSHF
                CALLFAR
pOLDINTAA	DD	-1

                STI
                RET     2
;----------------------------------------------------------------------
; If a request is already pending, ignore this one.
;----------------------------------------------------------------------
IAA_2:
                SUB	DX,DX	;Assume failure as function output
                CMP     WORD PTR CS:[REQ_TIMER],DX
		JNE	IAA_3
;----------------------------------------------------------------------
; No other request pending. Put us at the head of the line.
; Save the command code and queue a request to pop up.
;----------------------------------------------------------------------
		NOT	DX

                CLI
                MOV     WORD PTR CS:[REQ_TIMER],CX
		MOV	WORD PTR CS:[R$SWAPCODE],BX
IAA_3:
		IRET

INT_AA		ENDP

;======================================================================
; R$UNHOOKAA (Internal)
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;----------------------------------------------------------------------
; CHANGES: AX, DX, DI
;----------------------------------------------------------------------
R$UNHOOKAA	PROC	NEAR
	ASSUME	CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:NOTHING

                MOV     BL,0AAH
                MOV     SI,OFFSET RLHSEG:pOLDINTAA
                MOV     DX,OFFSET RLHSEG:INT_AA
                CALL    RESTORE_INT

		RET

R$UNHOOKAA	ENDP

RLHSEG		ENDS

;======================================================================
; Non-resident code.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; R$HOOKAA (Internal)
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;	DS:DI -> DWORD destination for old address
;	DS:DX -> new interrupt address
;----------------------------------------------------------------------
; CHANGES: AX, DX, DI
;----------------------------------------------------------------------
R$HOOKAA	PROC	NEAR
        ASSUME  CS:CSEG, DS:RLHSEG, ES:NOTHING, SS:DGROUP

		MOV	AL,0AAH
                MOV     DI,OFFSET RLHSEG:pOLDINTAA
                MOV     DX,OFFSET RLHSEG:INT_AA
                CALL    SET_INT
	ASSUME	ES:NOTHING

		CMP	WORD PTR [DI+2],0		;If seg is 0
		JNE	HAA_1

		MOV	BYTE PTR DS:[R$IAA$1],0CFH	;IRET
HAA_1:
		RET

R$HOOKAA	ENDP

CSEG		ENDS
		END
