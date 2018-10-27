;======================================================================
; DEINSTAL.ASM
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/22/89   Original.
; 7/29/89   Modify use of DGROUP, PSP. Move data to USEG.
;           .000    Split into file TSR11.
; 8/2/89    .001    Remove bad CS override.
; 8/5/89    .002    Add redundant overrides for clarity.
;           .003    Use segment finding routines.
;           .004    Reset string if successful.
; 8/7/89    .005    Fix register return usage.
; 8/9/89    .006    Handle 0 DGROUP correctly.
;                   Bad DS/ES second set.
; 8/13/89   .007    Bad ret, str arg off.
; 9/9/89    .008    Update doc, segs.
; 9/25/89   .009    Move extrns.
; 1/8/90    .010    Unify include file.
; 6/21/90   .011    Use new 50h/51h procs.
; 9/20/91   .012    Modify for swapping.
; 10/10/91  .013    Redo externals.
;----------------------------------------------------------------------
PUBLIC  DeinstallTsr    ;FAR, PDQ

;======================================================================
; Externals.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

EXTRN   R$GETPSP:NEAR       ;In R$PSP.ASM
EXTRN   R$SETPSP:NEAR       ;In R$PSP.ASM
EXTRN   FIND_FIRST_MCB:NEAR ;In R$MCB.ASM
EXTRN   FIND_NEXT_MCB:NEAR  ;In R$MCB.ASM

CSEG        ENDS

;======================================================================
; Externals.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EXTRN   R$ID:BYTE           ;this is in R$TSRDAT.ASM

RLHSEG      ENDS

;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU
EXTRN   P$PSPseg:WORD       ;in PDQDATA.ASM

DSEG            ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
    ASSUME  CS:CSEG

;======================================================================
; DeinstallTSR (FAR, PDQ)
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Assumes that all interrupt vectors have been unhooked and that
;    conditions are favorable.
; 2. Using the PSP of the resident segment, walk the memory chain and
;    try to release all the memory blocks.
; 3. If this routine returns a fail, the best procedure is to warn the
;    user to ctrl-atl-del immediately.
; 4. This routine uses Int 21h, so make sure it's safe to do so.
;----------------------------------------------------------------------
; Usage:
;       IF NOT DeinstallTsr(DGROUP,ID$) THEN PRINT "Please reboot"
; where
;       DGROUP = address returned by TsrInstalled.
;                0 - current DGROUP
;                otherwise - use that number
;----------------------------------------------------------------------
; Changes: AX, BX, CX, ES
;----------------------------------------------------------------------
DeinstallTsr    PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP
;----------------------------------------------------------------------
; Save the active PSP.
;----------------------------------------------------------------------
                CALL    R$GETPSP                ;Get active PSP in BX
                PUSH    BX                      ;Save on stack
;----------------------------------------------------------------------
; The argument is in the current data area and is the DGROUP of the
; program to remove.
;----------------------------------------------------------------------
                MOV     BX,WORD PTR [BP+8]      ;Pointer to DGROUP arg
                MOV     CX,WORD PTR DS:[BX]     ;Get DGROUP
                OR      CX,CX
                JNZ     DT_0

                MOV     CX,DS                   ;Else, use current DGROUP
DT_0:
                MOV     ES,CX                   ;In ES
        ASSUME  ES:DGROUP           ;Of resident copy
;----------------------------------------------------------------------
; Find the PSP that owns the specified DGROUP and the memory blocks.
; Make the resident PSP the active procedure so it can free its own memory.
;----------------------------------------------------------------------
                MOV     BX,WORD PTR ES:[P$PSPseg] ;Get indicated PSP seg
                CALL    R$SETPSP
;----------------------------------------------------------------------
; Find the begining of the DOS memory control block chain.
;----------------------------------------------------------------------
                MOV     CX,FALSE
                CALL    FIND_FIRST_MCB          ;MCB in AX
DT_1:
                MOV     ES,AX                   ;Point ES to arena header
        ASSUME  ES:NOTHING

                CMP     BX,WORD PTR ES:[1]      ;Does PSP match?
                JNE     DT_2
;----------------------------------------------------------------------
; Attempt to release this block. ES points to MCB, add one for block.
;----------------------------------------------------------------------
                INC     AX                      ; +1 = memory block addr
                MOV     ES,AX                   ;Point to block, not header
        ASSUME  ES:NOTHING

                MOV     AH,49H                  ;Release block at ES
                INT     21H                     ; CY set if fail
                JC      DT_3
;----------------------------------------------------------------------
; Try the next block.
;----------------------------------------------------------------------
DT_2:
                CALL    FIND_NEXT_MCB           ;Get next MCB in AX
                JNC     DT_1                    ;Try again
;----------------------------------------------------------------------
; Memory is freed, but erase string signature.
;----------------------------------------------------------------------
                MOV     AX,RLHSEG
                MOV     ES,AX
        ASSUME  ES:RLHSEG

                NOT     WORD PTR ES:[R$ID]
                NOT     CX                      ;Signal success
;----------------------------------------------------------------------
; Clean up and leave.
;----------------------------------------------------------------------
DT_3:
                POP     BX                      ;Restore active PSP
                CALL    R$SETPSP

                MOV     AX,CX

                POP     BP                      ;Erase stack frame
                RET     4                       ;Remove args

DeinstallTsr    ENDP

CSEG            ENDS
                END
