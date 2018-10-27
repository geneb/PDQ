; R$MCB.ASM
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Internal routine for memory control block manipulation used when
;    deinstalling TSRs.
;----------------------------------------------------------------------
; 8/5/89        .000    Original.
; 8/7/89        .001    Fix POP DS location.
; 9/9/89        .002    Update doc.
; 1/8/90        .003    Unified include file.
;----------------------------------------------------------------------
PUBLIC  FIND_FIRST_MCB
PUBLIC  FIND_NEXT_MCB

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU
DSEG            ENDS
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'
MCBSEG          DW      1 DUP (?)
USEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;======================================================================
; FIND_FIRST_MCB (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Locates the begining of the memory control block chain.
;----------------------------------------------------------------------
; Entry: none
; Exit:  AX = segment of first MCB header.
;----------------------------------------------------------------------
; 8/5/89        Original.
;----------------------------------------------------------------------
; Changes: AX
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

FIND_FIRST_MCB  PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BX                      ;Save used registers
                PUSH    ES

                MOV     AH,52H                  ;Get IVARS pointer
                INT     21H                     ; in ES:BX
        ASSUME  ES:NOTHING
                MOV     AX,WORD PTR ES:[BX][-2] ;First MCB
                MOV     WORD PTR [MCBSEG],AX    ;Update saved entry

                POP     ES                      ;Restore registers
                POP     BX
                RET                             ;Near return

FIND_FIRST_MCB  ENDP

;======================================================================
; FIND_NEXT_MCB (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Locates the next entry in the memory control block chain.
;----------------------------------------------------------------------
; Entry: none
; Exit: NC, AX = segment of MCB header.
;       CY, No more segments
;----------------------------------------------------------------------
; 8/5/89        Original.
;----------------------------------------------------------------------
; Changes: AX
;----------------------------------------------------------------------
FIND_NEXT_MCB   PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    DS                      ;Save register

                MOV     AX,WORD PTR [MCBSEG]    ;Get Previous block
                MOV     DS,AX                   ;Point DS to it
        ASSUME  DS:NOTHING
                CMP     BYTE PTR DS:[0],"Z"     ;Z if last block
                JNE     FNM_1

                STC
FNM_EXIT:
                POP     DS
        ASSUME  DS:DGROUP

                RET
FNM_1:
        ASSUME  DS:NOTHING
                ADD     AX,WORD PTR DS:[3]      ;Add length of this block
                INC     AX                      ;Skip arena header

                MOV     WORD PTR [MCBSEG],AX

                CLC
                JMP     FNM_EXIT

FIND_NEXT_MCB   ENDP

CSEG            ENDS
                END
