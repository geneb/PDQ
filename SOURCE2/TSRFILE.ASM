;======================================================================
; TSRFILE.ASM
;  TsrFileOn  PDQ:FAR
;  TsrFileOff PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989-1992 Crescent Software
; Copyright (c) 1989-1992 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/29/89       .000    Split into file TSR09.
; 8/2/89        .001    Make TSR active PID.
; 9/9/89        .002    Update doc, segs, struct.
; 9/10/89       .003    Safe for multiple calls.
; 9/25/89       .004    Move extrns.
; 1/8/90        .005    Unified include file.
; 6/21/90       .006    Fix 50h/51h DOS bug.
; 11/24/92      .007    Use TSR PSP to handle DTA calls.
;----------------------------------------------------------------------
EXTRN   R$GETPSP:NEAR
EXTRN   R$SETPSP:NEAR

PUBLIC  TsrFileOn
PUBLIC  TsrFileOff

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
    INCLUDE         R$PDQ.EQU
    EXTRN           P$PSPSeg:WORD   ;in PDQDATA.ASM

OLDPSP1         DW      0

DSEG            ENDS
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'

OLDDTA          DD      1 DUP (?)

USEG            ENDS
;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; TsrFileOn (PDQ)
;   Copyright (c) 1989-1992 Crescent Software
;   Copyright (c) 1989-1992 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Preserves the current DTA, changes the active PSP to the resident
;    program.
; 2. You also need to install a critical error handler and perhaps
;    a break handler.
; 3. These functions use Int 21h calls, and can only be used when higher
;    21h stack is available.
;----------------------------------------------------------------------
; Usage:
;       CALL TsrFileOn
;----------------------------------------------------------------------
; 7/22/89       Original.
; 7/29/89       Move data to USEG.
; 8/2/89        Make PDQ program the active PID.
;----------------------------------------------------------------------
TsrFileOn       PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                CMP     WORD PTR [OLDPSP1],0    ;If already called, exit
                JNE     TFOFF_EXIT
;----------------------------------------------------------------------
; Save the old PSP.  PSP must be switched for any file operations.
; These are undocumented functions.
;----------------------------------------------------------------------
                CALL    R$GETPSP
                MOV     WORD PTR [OLDPSP1],BX
;----------------------------------------------------------------------
; Make the PDQ program the active process.
;----------------------------------------------------------------------
                MOV     BX,WORD PTR [P$PSPSEG]  ;Get PSP
                CALL    R$SETPSP
;----------------------------------------------------------------------
; Get and save the current DTA address.  Needed for any PDQ calls that
; set the DTA somewhere else.
;----------------------------------------------------------------------

                MOV     AH,2FH                  ;Get current DTA
                INT     21H
        ASSUME  ES:NOTHING

                MOV     WORD PTR [OLDDTA][0],BX ;Save DTA
                MOV     WORD PTR [OLDDTA][2],ES
TFON_EXIT:
                RET

TsrFileOn       ENDP

;======================================================================
; TsrFileOff (PDQ)
;   Copyright (c) 1989-1992 Crescent Software
;   Copyright (c) 1989-1992 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Undoes what TsrFileOn does.
;----------------------------------------------------------------------
; Usage:
;       CALL TsrFileOff
;----------------------------------------------------------------------
; 7/22/89       Original.
; 7/29/89       Move data to USEG.
; 8/2/89        Fix CS data ref.
;----------------------------------------------------------------------
TsrFileOff      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                CMP     WORD PTR [OLDPSP1],0    ;If already off, exit
                JE      TFOFF_EXIT
;----------------------------------------------------------------------
; Restore the old DTA in case it was changed.
;----------------------------------------------------------------------
                PUSH    DS                      ;Save register

                LDS     DX,DWORD PTR [OLDDTA] ;Restore old DTA
        ASSUME  DS:NOTHING
                MOV     AH,1AH
                INT     21H

                POP     DS                      ;Restore register
        ASSUME  DS:DGROUP
;----------------------------------------------------------------------
; Make the process that was active before, active again.
;----------------------------------------------------------------------
                XOR     BX,BX
                XCHG    BX,WORD PTR [OLDPSP1] ;Restore active process
                CALL    R$SETPSP
TFOFF_EXIT:
                RET

TsrFileOff      ENDP

CSEG            ENDS
                END
