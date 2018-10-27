; READLONG.ASM
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1/8/90        .000    Split from R$RD.
; 9/27/91       .001    Add call to P$FreeTemp (EW)
;----------------------------------------------------------------------
PUBLIC      B$RDI4

EXTRN       PDQVALL:FAR         ;this is in PDQVAL.ASM
EXTRN       P$FreeTemp:FAR      ;this is in FREETEMP.ASM

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG,USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

INCLUDE R$PDQ.EQU

EXTRN       R$PARSESTR:WORD                 ;In R$RDPTR.ASM

DSEG        ENDS
;----------------------------------------------------------------------
USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized

EXTRN       TARGET_TYPE:BYTE                ;In R$RDPTR.ASM

USEG        ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; B$RDI4
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Read an integer value from a string source.
; By default, reads are made from the internal strings created by the
;  DATA statement.
;
;----------------------------------------------------------------------
B$RDI4      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            PUSH    BP
            MOV     BP,SP
;----------------------------------------------------------------------
; Parse off a single entry in the string at the default location and
; return it as a seperate string.
;----------------------------------------------------------------------
            MOV     BYTE PTR [TARGET_TYPE],_NUMERIC
            CALL    WORD PTR [R$PARSESTR]

;----------------------------------------------------------------------
; Convert the string pointed to by AX to an integer value and return it
; in DX:AX.  Push AX once in anticipation of deleting the incoming
; string if necessary, and once more for the call to PDQValI.
;----------------------------------------------------------------------
            PUSH    AX
            PUSH    AX
            CALL    PDQVALL

            LES     BX,DWORD PTR [BP+6]
        ASSUME  ES:NOTHING

            MOV     WORD PTR ES:[BX][0],AX
            MOV     WORD PTR ES:[BX][2],DX
            CALL    P$FreeTemp

            POP     BP
            RET     2 * 2

B$RDI4      ENDP

CSEG        ENDS
            END
