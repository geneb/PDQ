; UNHOOK.ASM
;  UnHookInt PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/19/89       Original.
; 7/22/89       Modify to accept DGROUP argument.
; 7/29/89       Change in DGROUP meaning. Already unhooked = not fail.
;               .000    Split into file TSR10.
; 7/30/89       .001    Fix typo in vector restore.
; 9/9/89        .002    Update docs, regs, struct.
; 9/10/89       .003    Preserve SI.
; 1/8/90        .004    Unified include file.
;----------------------------------------------------------------------
PUBLIC  UnHookInt
;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU
DSEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; UnHookInt
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Attempt to unhook the interrupt and restore it to the previous
;    vector.
; 2. Returns TRUE if unhook is successful, FALSE if not.
; 3. If the unhook fails, DO NOT uninstall the TSR.
; 4. Segment overrides are needed for the assembler -- don't touch.
;----------------------------------------------------------------------
; Usage:
;       IF NOT UnHookInt%(Registers, DGROUP) THEN PRINT "Uninstall failed."
; where
;       DGROUP = 0 - Current DGROUP
;                anything else = that addressed used (get from TsrInstalled).
;----------------------------------------------------------------------
UnHookInt       PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP
                PUSH    SI                      ;Save used registers
                PUSH    DS
;----------------------------------------------------------------------
; Can be used to unhook another program segment or this one.
;----------------------------------------------------------------------
                MOV     BX,WORD PTR [BP+6]      ;pointer to DGROUP
                CMP     WORD PTR [BX],0         ;If 0, use current
                JE      UHI_0

                MOV     DS,WORD PTR [BX]        ;Get value
        ASSUME  DS:NOTHING
UHI_0:
;----------------------------------------------------------------------
; Restore the interrupt if it still points to the PDQ proc.  If another
; TSR has grabbed the interrupt, we can't restore it.
; Unhooking the interrupt twice will do nothing, but will return success.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BP+8]      ;Pointer to struct

                XOR     AX,AX                   ;Address low memory
                MOV     ES,AX                   ; in ES
        ASSUME  ES:NOTHING

                MOV     AX,FALSE                ;Assume failure

                MOV     BX,WORD PTR DS:[STRUCT_INTNUM]  ;Interrupt #
                SHL     BX,1
                SHL     BX,1                    ; * 4 = offset in BX

                MOV     DX,WORD PTR DS:[STRUCT_PDQSEG]
                CMP     DX,0                    ;If 0, don't unhook
                JE      UHI_1

                CMP     DX,WORD PTR ES:[BX][2]  ;Point to PDQ?
                JNE     UHI_2

                MOV     CX,WORD PTR DS:[STRUCT_PDQOFF]
                CMP     CX,WORD PTR ES:[BX][0]  ;Point to PDQ?
                JNE     UHI_2

                MOV     CX,WORD PTR DS:[STRUCT_OLDINTOFF]       ;Get old
                MOV     DX,WORD PTR DS:[STRUCT_OLDINTSEG]       ; vector

                CLI
                MOV     WORD PTR ES:[BX][0],CX  ;Restore the vector
                MOV     WORD PTR ES:[BX][2],DX
                STI

                MOV     WORD PTR DS:[STRUCT_PDQSEG],0   ;Set unhooked flag
UHI_1:
                MOV     AX,TRUE                 ;Success
UHI_2:
                POP     DS                      ;Restore used registers
        ASSUME  DS:DGROUP
                POP     SI
                POP     BP
                RET     4

UnHookInt       ENDP

CSEG            ENDS
                END
