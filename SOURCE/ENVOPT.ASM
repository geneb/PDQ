; FILE: ENVOPT.ASM
; EnvOption (PDQ)
;       Copyright (c) 1989 Crescent Software
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 8/14/89       .000    Initial.
; 8/16/89       .001    Fix indirect ref.
; 9/10/89       .002    Update doc.
;----------------------------------------------------------------------
PUBLIC  EnvOption       ;Far proc
;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
EXTRN   R$ENVSW:WORD
DSEG            ENDS
USEG            SEGMENT WORD    PUBLIC  'BSS'
USEG            ENDS
;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
;======================================================================
; EnvOption
;       Copyright (c) 1989 Crescent Software
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
;       switch = 0, use environment belonging to this code
;       bit:     0, use environment belonging to parent
;                1, don't cap strings before adding to env
;                2, options are relative to active process
;----------------------------------------------------------------------
EnvOption       PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                MOV     BX,WORD PTR [BP+6]
                MOV     BX,WORD PTR [BX]
                XCHG    WORD PTR [R$ENVSW],BX

                POP     BP
                RET     2

EnvOption       ENDP

CSEG            ENDS
                END
