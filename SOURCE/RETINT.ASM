; RETINT.ASM
;  ReturnFromInt PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/17/89       Int on/off fix.
; 7/29/89       .000    Split into file TSR3.
; 9/9/89        .001    Update doc, struct.
; 11/4/89       .002    Add stack swap options.
; 12/18/89      .003    Fix return flags.  Optimize.
; 12/28/89      .004    Return with interrupts enabled.
; 1/8/90        .005    Unified include file.
;----------------------------------------------------------------------
PUBLIC          ReturnFromInt

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU
EXTRN   _SWAPPER:WORD   ;The interrupt that has control of the stack
DSEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; ReturnFromInt
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Restore registers from Registers struct and execute an IRET.
; 2. Does not return to PDQ.
; 3. If used with Int 9 (keyboard), the PIC must be reset manually.
;----------------------------------------------------------------------
; Usage:
;       CALL    ReturnFromInt(Registers)
;----------------------------------------------------------------------
ReturnFromInt   PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                POP     SI              ;Remove far retn address
                POP     SI
                POP     SI              ;Get address of struct
;----------------------------------------------------------------------
; If the _SWAPPER word contains the number of this interrupt, then it's
; responsible for restoring the stack.
;----------------------------------------------------------------------
                MOV     AX,WORD PTR [_SWAPPER]          ;If stack manager
                CMP     AX,WORD PTR [STRUCT_INTNUM]     ; is us
                JNE     RFI_1

                CLI                                     ; swap stacks back
                MOV     SS,WORD PTR [STRUCT_SS]
        ASSUME  SS:NOTHING
                MOV     SP,WORD PTR [STRUCT_SP]
                STI

                MOV     WORD PTR [_SWAPPER],0           ;Reset flag
;----------------------------------------------------------------------
; Restore the original registers.
;----------------------------------------------------------------------
RFI_1:
                PUSH    WORD PTR [STRUCT_SI]    ;Put SI on stack

                MOV     AX,WORD PTR [STRUCT_AX] ;Load registers from struct
                MOV     BX,WORD PTR [STRUCT_BX]
                MOV     CX,WORD PTR [STRUCT_CX]
                MOV     DX,WORD PTR [STRUCT_DX]
                MOV     DI,WORD PTR [STRUCT_DI]
                MOV     BP,WORD PTR [STRUCT_BP]
                MOV     ES,WORD PTR [STRUCT_ES]
        ASSUME  ES:NOTHING
                PUSH    WORD PTR [STRUCT_FLAGS] ;Restore flags
                POPF

                MOV     WORD PTR [STRUCT_BUSY],FALSE    ;Okay to invoke

                CLI
                MOV     DS,WORD PTR [STRUCT_DS]         ;Restore DS
        ASSUME  DS:NOTHING
                POP     SI                              ; and SI

        STI                       ;Return with interrupts on
                RET     2

ReturnFromInt   ENDP

CSEG            ENDS
                END
