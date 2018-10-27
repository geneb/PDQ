; INTRPTX.ASM
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/17/89       .002    Doc update. Final Alpha.
; 7/29/89       .003    Change proc names.
; 9/9/89        .004    Fix segment bug, change doc.
; 9/28/89       .005    Split Interrupt/InterruptX into separate files (ew).
; 1/8/90        .006    Unified include file.
;----------------------------------------------------------------------
PUBLIC  InterruptX

;----------------------------------------------------------------------
; 1. The Register stucture is used to pass and receive register values.
;    This differs from BASIC which uses two seperate arrays, one input, one
;    output.
; 2. The PDQ structure has extra words that are not used.  See INTRPT.ASM.
; 3. Interrupt does not use the DS or ES entries.
;
; element #   0  1  2  3  4  5  6   7    8  9
; REG_ARRAY: AX BX CX DX BP SI DI FLAGS DS ES
; (offset)    0  2  4  6  8  A  C   E   10 12
;----------------------------------------------------------------------

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU
DSEG            ENDS

;----------------------------------------------------------------------
; Code Segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; InterruptX (PDQ)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. InterruptX uses the value for DGROUP for DS and ES.
;----------------------------------------------------------------------
; Usage:
;       CALL InterruptX(IntNum%, Registers)
; where
;       IntNum% - integer with the number of the interrupt
;       Registers - PDQ structure.
;----------------------------------------------------------------------
; 7/4/89        Initial.
; 9/9/89        Modify doc. Fix seg bug.
;----------------------------------------------------------------------
InterruptX              PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                PUSH    SI                      ;Save required registers
                PUSH    DI
                PUSH    DS
;----------------------------------------------------------------------
; Load the interrupt number.
;----------------------------------------------------------------------
                MOV     BX,WORD PTR [BP+8]      ;Pointer to ARG1
                MOV     BL,BYTE PTR [BX]
                MOV     BYTE PTR CS:[INTNUMX],BL
                JMP     SHORT $ + 2             ;flush the pre-fetch queue
;----------------------------------------------------------------------
; Point SI to the structure.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BP+6]      ;Ptr to register structure
;----------------------------------------------------------------------
; Load the processor registers from the struct
;----------------------------------------------------------------------
                MOV     AX,WORD PTR [STRUCT_AX]
                MOV     BX,WORD PTR [STRUCT_BX]
                MOV     CX,WORD PTR [STRUCT_CX]
                MOV     DX,WORD PTR [STRUCT_DX]

                MOV     BP,WORD PTR [STRUCT_BP]
                MOV     DI,WORD PTR [STRUCT_DI]

                MOV     ES,WORD PTR [STRUCT_ES]
        ASSUME  ES:NOTHING

                PUSH    WORD PTR [STRUCT_SI]            ;Save SI on stack

                CMP     WORD PTR [STRUCT_ES],0FFFFH     ;If -1
                JNE     InterruptX_1

                PUSH    DS                              ; set to DGROUP
                POP     ES
InterruptX_1:
                CMP     WORD PTR [STRUCT_DS],0FFFFH     ;If not -1
                JE      InterruptX_2

                MOV     DS,WORD PTR [STRUCT_DS]         ; use passed value
        ASSUME  DS:NOTHING
InterruptX_2:
                POP     SI                              ;Retrieve SI
;----------------------------------------------------------------------
; A fill-in-the-blank interrupt instruction.
;----------------------------------------------------------------------
                DB      0CDH
INTNUMX         DB      0
;----------------------------------------------------------------------
; Get control of the machine again.
;----------------------------------------------------------------------
                PUSH    BP                      ;Temporary stack frame
                MOV     BP,SP

                PUSH    DS                      ;Save returned registers
                PUSH    SI
;----------------------------------------------------------------------
; Establish addressability to the struct and transfer register values.
;----------------------------------------------------------------------
                MOV     DS,WORD PTR [BP+2]
                MOV     SI,WORD PTR [BP+0EH]

                MOV     WORD PTR [STRUCT_AX],AX
                MOV     WORD PTR [STRUCT_BX],BX
                MOV     WORD PTR [STRUCT_CX],CX
                MOV     WORD PTR [STRUCT_DX],DX

                POP     WORD PTR [STRUCT_SI]
                POP     WORD PTR [STRUCT_DS]
                POP     WORD PTR [STRUCT_BP]

                MOV     WORD PTR [STRUCT_DI],DI
                MOV     WORD PTR [STRUCT_ES],ES

                PUSHF
                POP     WORD PTR [STRUCT_FLAGS]
;----------------------------------------------------------------------
; Restore registers, clean stack, and leave.
;----------------------------------------------------------------------
                POP     DI                      ;Fast way to discard DS
                POP     DI                      ;Restore values
                POP     SI

                POP     BP                      ;Destroy stack frame
                RET     4                       ;Discard 2 args

InterruptX      ENDP

CSEG            ENDS
                END
