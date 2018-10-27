;======================================================================
; R$UNHOOK.ASM
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 10/11/91	.000	Split from POPDE.ASM
; 10/12/91	.001	Check before unhooking to allow later attempts.
; 10/14/91	.002	Fix check to unhook AA.
;		.003	Remove direct reference to R$AA.ASM
;----------------------------------------------------------------------
PUBLIC	R$UNHOOKIVT	;Far, internal
PUBLIC	RESTORE_INT	;Near, internal
PUBLIC	R$UNHOOKAA$1	;Word, RLHSEG

;======================================================================
; DSEG is initialized data and part of DGROUP.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU				;Standard includes

DSEG            ENDS

;======================================================================
; Externals.
;----------------------------------------------------------------------
RLHSEG		SEGMENT	PARA	PUBLIC	'RLH_CODE'

EXTRN	pOLDINT8:DWORD		;In R$CORE.ASM
EXTRN	pOLDINT9:DWORD
EXTRN	pOLDINT10:DWORD
EXTRN	pOLDINT13:DWORD
EXTRN	pOLDINT14:DWORD
EXTRN	pOLDINT16:DWORD
EXTRN	pOLDINT17:DWORD
EXTRN	pOLDINT21:DWORD
EXTRN	pOLDINT25:DWORD
EXTRN	pOLDINT26:DWORD
EXTRN	pOLDINT28:DWORD

EXTRN	INT_8:FAR		;In R$CORE.ASM
EXTRN	INT_9:FAR
EXTRN	INT_10:FAR
EXTRN	INT_13:FAR
EXTRN	INT_14:FAR
EXTRN	INT_16:FAR
EXTRN	INT_17:FAR
EXTRN	INT_21:FAR
EXTRN	INT_25:FAR
EXTRN	INT_26:FAR
EXTRN	INT_28:FAR

EXTRN	R$SWAPFLAG:BYTE		;In R$CORE.ASM

R$UNHOOKAA$1	DW	0	;Near pointer

;======================================================================
; R$UNHOOKIVT (FAR, Internal)
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;	CX  = 0, Don't set program vectors to -1,-1 (swapping)
;	   != 0, set to -1,-1 (non-swapping)
;	DS = RLHSEG, segment containing offsets
;	ES:DI -> Origin of IVT table to unhook
; Exit:
;	CF = NC if success
;	     CY if failure
;----------------------------------------------------------------------
; Changes: BX DX SI
;----------------------------------------------------------------------
R$UNHOOKIVT	PROC	FAR
	ASSUME	CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:NOTHING
		PUSH	BP
;----------------------------------------------------------------------
; First time through, just verify that all the vectors CAN be unhooked.
; If any ONE can't, don't unhook any of them.
;----------------------------------------------------------------------
		MOV	BP,0			;Test only
UNH_0:
                MOV     BL,9H
                MOV     SI,OFFSET RLHSEG:pOLDINT9
                MOV     DX,OFFSET RLHSEG:INT_9
                CALL    RESTORE_INT             ;Try to restore
                JC      UNH_EXIT

                MOV     BL,8H
                MOV     SI,OFFSET RLHSEG:pOLDINT8
                MOV     DX,OFFSET RLHSEG:INT_8
                CALL    RESTORE_INT
                JC      UNH_EXIT

                MOV     BL,10H
                MOV     SI,OFFSET RLHSEG:pOLDINT10
                MOV     DX,OFFSET RLHSEG:INT_10
                CALL    RESTORE_INT
                JC      UNH_EXIT

                MOV     BL,13H
                MOV     SI,OFFSET RLHSEG:pOLDINT13
                MOV     DX,OFFSET RLHSEG:INT_13
                CALL    RESTORE_INT
                JC      UNH_EXIT

                MOV     BL,14H
                MOV     SI,OFFSET RLHSEG:pOLDINT14
                MOV     DX,OFFSET RLHSEG:INT_14
                CALL    RESTORE_INT
                JC      UNH_EXIT

                MOV     BL,16H
                MOV     SI,OFFSET RLHSEG:pOLDINT16
                MOV     DX,OFFSET RLHSEG:INT_16
                CALL    RESTORE_INT
                JNC     UNH_1
UNH_EXIT:
		POP	BP
		RET
UNH_1:
                MOV     BL,17H
                MOV     SI,OFFSET RLHSEG:pOLDINT17
                MOV     DX,OFFSET RLHSEG:INT_17
                CALL    RESTORE_INT
                JC      UNH_EXIT

                MOV     BL,21H
                MOV     SI,OFFSET RLHSEG:pOLDINT21
                MOV     DX,OFFSET RLHSEG:INT_21
                CALL    RESTORE_INT
                JC      UNH_EXIT

                MOV     BL,25H
                MOV     SI,OFFSET RLHSEG:pOLDINT25
                MOV     DX,OFFSET RLHSEG:INT_25
                CALL    RESTORE_INT
                JC      UNH_EXIT

                MOV     BL,26H
                MOV     SI,OFFSET RLHSEG:pOLDINT26
                MOV     DX,OFFSET RLHSEG:INT_26
                CALL    RESTORE_INT
                JC      UNH_EXIT

                MOV     BL,28H
                MOV     SI,OFFSET RLHSEG:pOLDINT28
                MOV     DX,OFFSET RLHSEG:INT_28
                CALL    RESTORE_INT
		JC	UNH_EXIT
;----------------------------------------------------------------------
; Check this vector only if a swapping TSR.
;----------------------------------------------------------------------
		CMP	BYTE PTR [R$SWAPFLAG],0
		JE	UNH_2

		CALL	WORD PTR [R$UNHOOKAA$1]
		JC	UNH_EXIT
UNH_2:
;----------------------------------------------------------------------
; If we get through here first time, all vectors can be removed.
; Do it for real.
;----------------------------------------------------------------------
		OR	BP,BP			;Nonzero=we're done
		JNZ	UNH_EXIT

		NOT	BP			;Make nonzero
		JMP	UNH_0			;Start over

R$UNHOOKIVT	ENDP

;======================================================================
; RESTORE_INT (Internal)
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;	BL = interrupt number to unhook
;
;	DS = RLHSEG
;	SI = RLHSEG:offset of DWORD pointer to old int
;
;	DX = RLHSEG:offset of our ISR
;
;	ES = Segment of IVT
;	DI = Offset of origin of IVT
;----------------------------------------------------------------------
; Changes: AX BX DX
;----------------------------------------------------------------------
RESTORE_INT     PROC    NEAR
        ASSUME  CS:RLHSEG, DS:RLHSEG, ES:NOTHING, SS:NOTHING

                CMP     WORD PTR DS:[SI],-1     ;-1 means not hooked
                JNE     RI_1
RI_PASS:
                CLC                             ;Successful
RI_EXIT:
                RET
;----------------------------------------------------------------------
; Does the interrupt vector in low memory still point to our resident routine?
;----------------------------------------------------------------------
RI_1:
                SUB     BH,BH                   ;Get offset of interrupt
                SHL     BX,1
                SHL     BX,1                    ; * 4 = offset in BX
                CMP     DX,WORD PTR ES:[BX][DI] ;Does offset match?
                JE      RI_3
RI_FAIL:
                STC                             ;Fail uninstall
                JMP     RI_EXIT                 ;Exit
RI_3:
                MOV     AX,DS
                CMP     AX,WORD PTR ES:[BX][DI][2]  ;Does segment match?
                JNE     RI_FAIL
;----------------------------------------------------------------------
; The vector in low memory still points to our routine.
; If just testing, leave now.
;----------------------------------------------------------------------
		OR	BP,BP			;Zero means test only
		JZ	RI_PASS
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
                MOV     AX,WORD PTR DS:[SI]
                MOV     DX,WORD PTR DS:[SI][2]

                CLI
                MOV     WORD PTR ES:[BX][DI][0],AX
                MOV     WORD PTR ES:[BX][DI][2],DX
                STI

		JCXZ	RI_PASS

                MOV     AX,-1

                MOV     WORD PTR DS:[SI][0],AX
                MOV     WORD PTR DS:[SI][2],AX

                JMP     RI_PASS

RESTORE_INT     ENDP

RLHSEG		ENDS
		END
