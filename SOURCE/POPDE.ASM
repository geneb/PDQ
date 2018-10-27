;======================================================================
; POPDE.ASM
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 8/18/91   .000    Split from POPUP.037.
; 9/17/91   .001    Modify for swapping.
; 9/20/91   .002    Fix fail thread.
; 10/10/91  .003    Redo externals.
; 10/11/91  .004    Split vector unhooking.
;           .005    Support swapping TSRs.
; 10/14/91  .006    Fix swap test.
;----------------------------------------------------------------------
PUBLIC  PopDeinstall    ;FAR, PDQ

;======================================================================
; Externals.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EXTRN   R$REMOVEFLAG:BYTE   ;In R$CORE.ASM
EXTRN   R$SWAPFLAG:BYTE     ;In R$CORE.ASM

EXTRN   R$UNHOOKIVT:FAR     ;In R$UNHOOK.ASM

RLHSEG      ENDS

;======================================================================
; Externals.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

EXTRN   DeinstallTSR:FAR    ;In DEINSTAL.ASM

CSEG        ENDS

;======================================================================
; A convenient alias for 0 when playing with the interrupt table.
;----------------------------------------------------------------------
LOMEM       SEGMENT AT  0000H
LOMEM       ENDS

;======================================================================
; Define these data segments to be part of DGROUP.
; DSEG is initialized data.
; USEG is uninitialized data.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU

EXTRN   R$RLHSEG:WORD   ;In R$CORE.ASM

DSEG            ENDS

;======================================================================
; Code.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; PopDeinstall (FAR, PDQ)
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Remove the TSR from memory.
; 2. PopDown must still be called.
;----------------------------------------------------------------------
; Usage:
;       If NOT (PopDeinstall%(DGROUP,ID$)) THEN failure
; where
;       ID$ is the identification string
;       DGROUP is the value returned by TsrInstalled. (0=current)
;----------------------------------------------------------------------
; 8/5/89    Fill in.
; 8/9/89    Eliminate DI usage.
; 8/13/89   Update overrides.
; 9/18/91   Update for swapping.
;----------------------------------------------------------------------
PopDeinstall    PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                PUSH    SI                      ;Save used registers
                PUSH    DI
;----------------------------------------------------------------------
; If TSR is swapper, just queue the request.
;----------------------------------------------------------------------
                MOV     BX,RLHSEG
                MOV     ES,BX
        ASSUME  ES:RLHSEG

                CMP     BYTE PTR [R$SWAPFLAG],0
                JE      PDI_0

                MOV     AX,TRUE
                MOV     BYTE PTR ES:[R$REMOVEFLAG],AL
                CLC
                JMP     SHORT PDI_EXIT
;----------------------------------------------------------------------
; Get the value of DGROUP passed to us.
;----------------------------------------------------------------------
PDI_0:
                MOV     BX,WORD PTR [BP+8]      ;point to DGROUP arg
                MOV     BX,WORD PTR [BX]        ;Get DGROUP arg
;----------------------------------------------------------------------
; If 0 was passed, then use current DGROUP value.
; Otherwise load DGROUP of other copy.
;----------------------------------------------------------------------
                OR      BX,BX                   ;0 = current DGROUP
                JZ      PDI_1

                MOV     DS,BX                   ;Get passed DGROUP
        ASSUME  DS:DGROUP
PDI_1:
;----------------------------------------------------------------------
; Locate core module of program to be forcibly removed.
; The address is in DGROUP.
;----------------------------------------------------------------------
                MOV     DS,WORD PTR [R$RLHSEG]
        ASSUME  DS:RLHSEG

                SUB     DI,DI                   ;Point ES:DI to low memory
                MOV     ES,DI
        ASSUME  ES:LOMEM
;----------------------------------------------------------------------
; Attempt to restore the original interrupts.  A single failure voids
; the process. Offsets are taken relative to RLHSEG.
;----------------------------------------------------------------------
                MOV     CL,1                    ;Non-zero to set to -1
                CALL    R$UNHOOKIVT

                PUSH    SS
                POP     DS                      ;Restore DS at entry
        ASSUME  DS:DGROUP
PDI_2:
                MOV     AX,FALSE
                JC      PDI_EXIT
;----------------------------------------------------------------------
; All vectors were restored successfully.
; Release memory belonging to this PID.
;----------------------------------------------------------------------
                PUSH    WORD PTR [BP+8]         ;DGROUP
                PUSH    WORD PTR [BP+6]         ;ID$
                CALL    DeinstallTsr            ;(DGROUP,ID$)
                JC      PDI_2
;----------------------------------------------------------------------
; This test is used to clear the carry flag - don't change it.
;----------------------------------------------------------------------
PDI_EXIT:
                POP     DI
                POP     SI
                POP     BP                      ;Erase stack frame
                RET     4                       ;Remove args

PopDeinstall    ENDP

CSEG            ENDS
                END
