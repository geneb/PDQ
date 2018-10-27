; CALLINT.ASM
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; CallOldInt PDQ:FAR
;----------------------------------------------------------------------
; 7/17/89       Int on/off fix.
; 7/29/89       .000    Split into file TSR5.
; 9/9/89        .001    Update doc, struct.
; 12/8/89       .002    Fix entry flags.
; 12/18/89      .003    Reduce bytes in stack math.
; 1/2/90        .004    Use correct flags.
; 1/8/90        .005    Unified include file.
;----------------------------------------------------------------------
PUBLIC  CallOldInt

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE  R$PDQ.EQU
DSEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; CallOldInt
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Load the processor registers from the struct.
; 2. Call the old interrupt and return control to this routine.
; 3. Move the processor registers into the struct and return control
;    to the PDQ program.
;----------------------------------------------------------------------
; Usage:
;       CALL    CallOldInt(Registers)
;----------------------------------------------------------------------
CallOldInt      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                PUSH    SI                      ;Save used registers
                PUSH    DI
                PUSH    DS
;----------------------------------------------------------------------
; Set pointer to struct.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BP+6]      ;Get pointer to struct
;----------------------------------------------------------------------
; Push info on stack for the ISR's IRET that returns control to us.
;----------------------------------------------------------------------
                PUSH    WORD PTR [STRUCT_FLAGS] ;Use original flags
                PUSH    CS                      ;Segment
                MOV     AX,OFFSET COI_RET       ;Offset
                PUSH    AX
;----------------------------------------------------------------------
; Instead of a CALL to the old int, we'll use a far RET. Push ret address.
;----------------------------------------------------------------------
                PUSH    WORD PTR [STRUCT_OLDINTSEG]
                PUSH    WORD PTR [STRUCT_OLDINTOFF]
;----------------------------------------------------------------------
; Load the processor registers from the struct.
;----------------------------------------------------------------------
                MOV     AX,WORD PTR [STRUCT_AX] ;Restore remaining regs
                MOV     BX,WORD PTR [STRUCT_BX]
                MOV     CX,WORD PTR [STRUCT_CX]
                MOV     DX,WORD PTR [STRUCT_DX]
                MOV     DI,WORD PTR [STRUCT_DI]
                MOV     BP,WORD PTR [STRUCT_BP]
                MOV     ES,WORD PTR [STRUCT_ES]
        ASSUME  ES:NOTHING

                PUSH    WORD PTR [STRUCT_FLAGS] ;Flags
                POPF

                PUSH    WORD PTR [STRUCT_SI]    ;Save SI on stack
                MOV     DS,WORD PTR [STRUCT_DS] ;Load DS
        ASSUME  DS:NOTHING
                POP     SI                      ;Load SI
;----------------------------------------------------------------------
; Far return works like a call, but doesn't put anything on stack.
;----------------------------------------------------------------------
                CLI
                RET     ;FAR RETURN looks like a call
;----------------------------------------------------------------------
; Save all the registers returned from the ISR.
; Assume everything but SS:SP has been changed. CS:IP can be counted on
; as well.
; Create a new stack frame using the current SP.
;----------------------------------------------------------------------
COI_RET:
        ASSUME  CS:CSEG, DS:NOTHING, ES:NOTHING, SS:DGROUP

                STI                             ;Enable interrupts

                PUSH    BP                      ;Create temp stack frame
                MOV     BP,SP

                PUSH    DS                      ;Save registers
                PUSH    SI
;----------------------------------------------------------------------
; Set DS:SI to point to struct.
;----------------------------------------------------------------------
                MOV     DS,WORD PTR [BP+2]
        ASSUME  DS:DGROUP
                MOV     SI,WORD PTR [BP+0EH]    ;Offset of struct
;----------------------------------------------------------------------
; Move the processor registers to the struct.
; Since stacks were not switched, SS:SP will not change.
; Note that certain interrupts (25h, 26h) cannot be used with this proc
;  since they leave an extra word on the stack.
;----------------------------------------------------------------------
                MOV     WORD PTR [STRUCT_AX],AX ;From registers
                MOV     WORD PTR [STRUCT_BX],BX
                MOV     WORD PTR [STRUCT_CX],CX
                MOV     WORD PTR [STRUCT_DX],DX
                POP     WORD PTR [STRUCT_SI]
                MOV     WORD PTR [STRUCT_DI],DI
                POP     WORD PTR [STRUCT_DS]
                MOV     WORD PTR [STRUCT_ES],ES
                PUSHF
                POP     WORD PTR [STRUCT_FLAGS]
                POP     WORD PTR [STRUCT_BP]
;----------------------------------------------------------------------
; We put the offset of the struct on the stack earlier, then retrieved
;  it relative to the second BP.  Now SI holds that value, but popping
;  is the easiest way to remove it from the stack.
; Load the original BP in the same way.
; Return to BASIC and remove the parameter.
;----------------------------------------------------------------------
                POP     DI                      ;Remove DS from stack

                POP     DI
                POP     SI

                POP     BP                      ;Destroy stack frame
                RET     1 * 2                   ;Discard 1 arg

CallOldInt      ENDP

CSEG            ENDS
                END
