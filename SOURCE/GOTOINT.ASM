; GOTOINT.ASM
;  GotoOldInt PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/17/89       Int on/off fix.
; 7/29/89       .000    Split into file TSR4.
; 9/9/89        .001    Update doc, struct.
; 11/4/89       .002    Add stack swap options.
; 12/18/89      .003    Reduce byte count on stack math.
; 1/8/90        .004    Unified include file.
;----------------------------------------------------------------------
PUBLIC  GotoOldInt

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
EXTRN   _SWAPPER:WORD   ;The interrupt that has control of the stack
INCLUDE R$PDQ.EQU
DSEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
;======================================================================
; GOTOOLDINT
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Restore registers from Registers struct and execute a direct jump to
;    the previous TSR handler.
; 2. Does not return to PDQ.
;----------------------------------------------------------------------
; Usage:
;       CALL    GotoOldInt(Registers)
;----------------------------------------------------------------------
GotoOldInt      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                POP     SI                      ;Remove PDQ retn address
                POP     SI
                POP     SI                      ;Get address of struct
;----------------------------------------------------------------------
; If the _SWAPPER word contains the number of this interrupt, then it's
; responsible for restoring the stack.
;----------------------------------------------------------------------
                MOV     AX,WORD PTR [_SWAPPER]          ;If stack manager
                CMP     AX,WORD PTR [STRUCT_INTNUM]     ; is us
                JNE     GOI_1

                CLI
                MOV     SS,WORD PTR [STRUCT_SS]
        ASSUME  SS:NOTHING
                MOV     SP,WORD PTR [STRUCT_SP]
                STI

                MOV     WORD PTR [_SWAPPER],0           ;Reset flag
;----------------------------------------------------------------------
; Put the address of the interrupt on the stack so a RETF will goto the
; old interrupt routine.
;----------------------------------------------------------------------
GOI_1:
                PUSH    WORD PTR [STRUCT_OLDINTSEG]
                PUSH    WORD PTR [STRUCT_OLDINTOFF]
;----------------------------------------------------------------------
; Reset the registers from the structure (allows changes).
;----------------------------------------------------------------------
                PUSH    WORD PTR [STRUCT_SI]    ;Put SI on stack

                MOV     BX,WORD PTR [STRUCT_BX] ;Load registers from struct
                MOV     CX,WORD PTR [STRUCT_CX]
                MOV     DX,WORD PTR [STRUCT_DX]
                MOV     DI,WORD PTR [STRUCT_DI]
                MOV     BP,WORD PTR [STRUCT_BP]
                MOV     ES,WORD PTR [STRUCT_ES]
        ASSUME  ES:NOTHING

                PUSH    WORD PTR [STRUCT_FLAGS]         ;Original flags
                POPF

                MOV     AX,WORD PTR [STRUCT_AX]         ;Restore AX

                MOV     WORD PTR [STRUCT_BUSY],FALSE    ;Unbusy

                CLI                                     ;Interrupts off
                MOV     DS,WORD PTR [STRUCT_DS]         ;Restore DS
        ASSUME  DS:NOTHING
                POP     SI                              ; and SI

                RET                             ;Far return, interrupts off

GotoOldInt      ENDP

CSEG            ENDS
                END
