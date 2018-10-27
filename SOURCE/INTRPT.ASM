; INTRPT.ASM - Give PDQ programs ability to call interrupts directly.
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/17/89       .002    Doc update. Final Alpha.
; 7/29/89       .003    Change proc names.
; 9/9/89        .004    Fix segment bug, change doc.
; 9/28/89       .005    Split Interrupt/InterruptX into separate files (ew).
; 1/8/90        .006    Unified include file.
; 7/18/96       .007    Added code to handle DOS interrupts 25h and 26h
;----------------------------------------------------------------------
PUBLIC  Interrupt

;----------------------------------------------------------------------
; 1. The Register stucture is used to pass and receive register values.
;    This differs from BASIC which uses two seperate arrays, one input, one
;    output.
; 2. The "default" PDQ structure has some extra words that are not used.
;    If bytes are tight you may create your own TYPE for Interrupt.
; 3. Interrupt does not use the DS or ES entries.
;
; element #   0  1  2  3  4  5  6   7  
; REG_ARRAY: AX BX CX DX BP SI DI FLAGS
; (offset)    0  2  4  6  8  A  C   E
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
; Interrupt (PDQ)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Interrupt does not set DS or ES to anything special.
;----------------------------------------------------------------------
; Usage:
;       CALL Interrupt(IntNum%, Registers)
; where
;       IntNum% - integer with the number of the interrupt
;       Registers - PDQ struct
;----------------------------------------------------------------------
; 7/4/89        Initial.
; 9/9/89        Change doc.
;----------------------------------------------------------------------
Interrupt               PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                PUSH    SI                      ;Save required registers
                PUSH    DI
                PUSH    DS
;----------------------------------------------------------------------
; Self-modify the code to load the interrupt number.
;----------------------------------------------------------------------
                MOV     BX,WORD PTR [BP+8]      ;Pointer to ARG1
                MOV     BL,BYTE PTR [BX]
                MOV     BYTE PTR CS:[INTNUM],BL
                JMP     SHORT $ + 2             ;flush the pre-fetch queue
;----------------------------------------------------------------------
; Point SI to the Registers structure.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BP+6]      ;Ptr to register structure
;----------------------------------------------------------------------
; Load the processor registers from the structure.
;----------------------------------------------------------------------
                MOV     AX,WORD PTR [STRUCT_AX]
                MOV     BX,WORD PTR [STRUCT_BX]
                MOV     CX,WORD PTR [STRUCT_CX]
                MOV     DX,WORD PTR [STRUCT_DX]

                MOV     BP,WORD PTR [STRUCT_BP]
                MOV     DI,WORD PTR [STRUCT_DI]
                MOV     SI,WORD PTR [STRUCT_SI]
;----------------------------------------------------------------------
; A fill-in-the-blank interrupt instruction. INT ??
;----------------------------------------------------------------------
                DB      0CDH
INTNUM          DB      0
;----------------------------------------------------------------------
; Get control of the machine again.
;----------------------------------------------------------------------
                PUSH    BP                      ;Temporary stack frame
                MOV     BP,SP
                PUSH    SI                      ;Save register
;----------------------------------------------------------------------
; Establish addressability to the struct and transfer resulting register
; values to the struct.
;----------------------------------------------------------------------
                MOV     DS,WORD PTR [BP+2]
                MOV     SI,WORD PTR [BP+0EH]

                MOV     WORD PTR [STRUCT_AX],AX
                MOV     WORD PTR [STRUCT_BX],BX
                MOV     WORD PTR [STRUCT_CX],CX
                MOV     WORD PTR [STRUCT_DX],DX

                POP     WORD PTR [STRUCT_SI]
                POP     WORD PTR [STRUCT_BP]

                MOV     WORD PTR [STRUCT_DI],DI

                PUSHF
                POP     WORD PTR [STRUCT_FLAGS]
;----------------------------------------------------------------------
; Restore registers, clean stack, and leave.
; EW added 7/18/96: the next six lines to pop the flags that DOS
;    stupidly leaves on the stack when reading/writing disk sectors.
;----------------------------------------------------------------------
                CMP     BYTE PTR CS:[INTNUM],25h
                JNE     @F
                POP     AX
@@:
                CMP     BYTE PTR CS:[INTNUM],26h
                JNE     @F
                POP     AX
@@:
                POP     DI                      ;Fast way to discard DS

                POP     DI                      ;Restore values
                POP     SI

                POP     BP                      ;Destroy stack frame
                RET     4                       ;Discard 2 args

Interrupt       ENDP

CSEG            ENDS
                END
