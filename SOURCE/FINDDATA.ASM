;======================================================================
; FINDDATA.ASM
;  R$FIND_DATA  INTERNAL:NEAR
;----------------------------------------------------------------------
; Copyright (c) 1990 Crescent Software
; Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 10/7/90   .000    Split from RESTORE.
;----------------------------------------------------------------------
PUBLIC  R$FIND_DATA ;NEAR


;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG, USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized
DSEG        ENDS
USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized
USEG        ENDS

;======================================================================
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; R$FIND_DATA - Find data for an object module.
;  Copyright (c) 1990 Crescent Software
;  Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1. Do a stack trace and find the CS of the PDQ code that wanted us to
;    do a READ.  Each object module's code is combined into a single
;    segment.  The beginning of that segment (30 bytes) contains important
;    info.  Let's call it the Code Segment Prefix (CSP).
;
; 2. The word at BX:[E] points to 2 WORDs in DGROUP that may be used to
;    store information about the read.  I use them a little differently
;    than QB.
;   WORD 1 = 0 if data has not yet been read from this module.
;          WORD 2 must be initialized.
;        Bit 0=1 if data has been read from this module.
;          WORD 2 is assumed valid.
;        Bit 1=1 to signify that the pointer is aimed at the
;          start of a new line of data.
;   WORD 2 = Current read pointer for this module.
;
; ENTER:
;   BP must point to a stack frame created by a program called
;      directly from the compiler-generated code.
; EXIT:
;   ES - Points to code segment of object file
;   DS:BX - address of two scratch words defined above
;----------------------------------------------------------------------
; CHANGES: BX,ES
;----------------------------------------------------------------------
R$FIND_DATA PROC    NEAR
    ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

        MOV     BX,BP                   ;Previous stack frame
        ADD     BX,4                    ;Location of calling CS
        MOV     BX,WORD PTR SS:[BX]     ;Get calling CS in BX

        MOV     ES,BX                   ;Point ES to CSP
    ASSUME  ES:NOTHING

        MOV     BX,ES:[0EH]             ;Get ptr to scratch words
        RET

R$FIND_DATA ENDP

CSEG        ENDS
        END
