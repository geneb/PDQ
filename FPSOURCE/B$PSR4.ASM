;======================================================================
; B$PSR4.ASM
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 2/17/91   .000    Original.
; 3/24/91   .001    Print an extra blank space after the number (EW).
;----------------------------------------------------------------------
PUBLIC      B$PSR4  ;FAR (QB)

;----------------------------------------------------------------------
; FAR Externals
;----------------------------------------------------------------------
EXTRN       B$PSSD:FAR
EXTRN       B$STR4:FAR

;======================================================================
; DGROUP addressing fixed up by linker.
; DSEG: Initialized data.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

Extrn           P$1Space:Word   ;this is in PRINTDAT.ASM

DSEG            ENDS

;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'

RET_ADR     DD  1 DUP (?)

USEG            ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG04      SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG04, DS:DGROUP, ES:NOTHING, SS:DGROUP

;======================================================================
; B$PSR4:FAR (QB)
;----------------------------------------------------------------------
; Copyright (c) 1991 Crescent Software
; Copyright (c) 1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; INPUT:
;   STACK = 4-byte real to be converted.
;       WORD0 = BP+6    ;Least significant part
;       WORD1 = BP+8    ;Sign + exponent part
;----------------------------------------------------------------------
; CHANGES: AX, BX, CX, DX, ES, FLAGS
;----------------------------------------------------------------------
B$PSR4      PROC    FAR
        ASSUME  CS:CSEG04, DS:DGROUP, ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
; Since the real number has already been pushed, just remove our
; return address and save it. Then call the num to string routine. This
; cleans the stack.
;----------------------------------------------------------------------
        POP     WORD PTR [RET_ADR]
        POP     WORD PTR [RET_ADR][2]

        CALL    B$STR4
;----------------------------------------------------------------------
; Now push the returned string descriptor and print it.
;----------------------------------------------------------------------
        PUSH    AX
        CALL    B$PSSD

        Mov     AX,Offset DGROUP:P$1Space   ;show where the blank space is
        Push    AX                          ;print it
        Call    B$PSSD

;----------------------------------------------------------------------
; Return to caller.
;----------------------------------------------------------------------
        JMP     DWORD PTR [RET_ADR]

B$PSR4      ENDP

CSEG04      ENDS
        END
