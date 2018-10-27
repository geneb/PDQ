; CRITERR.ASM
;   CRITERROFF  PDQ:FAR
;   CRITERRON   PDQ:FAR
;       INT_24      Local:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/18/89       .000    Initial.
; 7/22/89       .001    Change proc names.
; 8/13/89       .002    Fix segment declaration.
; 9/9/89        .003    Modify to set error code.
; 1/8/90        .004    Unified include file.
;----------------------------------------------------------------------
PUBLIC  CritErrOff
PUBLIC  CritErrOn

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU
EXTRN   P$PDQERR:WORD

pOLDINT24       DD      0

DSEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; CritErrOff (PDQ)
;       Copyright (c) 1989 Crescent Software
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Intercept the DOS critical error interrupt during TSR programs.
; 2. Must be restored before exiting the TSR.
;----------------------------------------------------------------------
; Usage:
;       CALL CritErrOff
;----------------------------------------------------------------------
; 7/18/89       Initial.
; 9/9/89        Modify not to fail on multiple calls.
;----------------------------------------------------------------------
; Changes: AX BX ES
;----------------------------------------------------------------------
CritErrOff      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                XOR     AX,AX

                CMP     WORD PTR [pOLDINT24],AX ;If offset non-zero,
                JNE     CEOFF_EXIT              ; already hooked

                MOV     ES,AX                   ;Address low memory
        ASSUME  ES:NOTHING

                MOV     AX,WORD PTR ES:[24H*4+0]        ;Get critical vector
                MOV     BX,WORD PTR ES:[24H*4+2]

                MOV     WORD PTR [pOLDINT24][0],AX      ;Save it
                MOV     WORD PTR [pOLDINT24][2],BX

                CLI
                MOV     WORD PTR ES:[24H*4+0],OFFSET CSEG:INT_24
                MOV     WORD PTR ES:[24H*4+2],CS
                STI
CEOFF_EXIT:
                RET                             ;Return to PDQ

CritErrOff      ENDP

;======================================================================
; CritErrOn (PDQ)
;       Copyright (c) 1989 Crescent Software
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Reset the DOS critical error.
;----------------------------------------------------------------------
; Usage:
;       CALL CritErrOn
;----------------------------------------------------------------------
; 7/18/89       Initial.
; 9/9/89        Modify not to fail on multiple calls.
;----------------------------------------------------------------------
; Changes: AX BX ES
;----------------------------------------------------------------------
CritErrOn       PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                XOR     AX,AX                   ;Zero AX

                CMP     WORD PTR [pOLDINT24],AX ;If offset zero,
                JE      CEON_EXIT               ; already unhooked

                MOV     ES,AX                   ;Address low memory
        ASSUME  ES:NOTHING

                MOV     BX,AX                           ;0 in BX, too
                XCHG    AX,WORD PTR [pOLDINT24][0]      ;Get old vector
                XCHG    BX,WORD PTR [pOLDINT24][2]      ; and zero storage

                CLI
                MOV     WORD PTR ES:[24H*4+0],AX        ;Restore it
                MOV     WORD PTR ES:[24H*4+2],BX
                STI
CEON_EXIT:
                RET                             ;Return to PDQ

CritErrOn       ENDP

;======================================================================
; INT_24 (internal)
;       Copyright (c) 1989 Crescent Software
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Capture the DOS critical error and return the code to ignore the
;    error.
; 2. Make the error available to PDQ.
;----------------------------------------------------------------------
; 7/18/89       Initial.
;----------------------------------------------------------------------
; Changes: AX
;----------------------------------------------------------------------
INT_24          PROC    FAR
        ASSUME  CS:CSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                PUSH    AX
                PUSH    DS
                MOV     AX,DGROUP
                MOV     DS,AX
        ASSUME  DS:DGROUP
                MOV     WORD PTR [P$PDQErr],71
                POP     DS
                POP     AX
                XOR     AL,AL                   ;Ignore the error
                IRET

INT_24          ENDP

CSEG            ENDS
                END
