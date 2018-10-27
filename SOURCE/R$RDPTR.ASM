; R$RDPTR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 12/21/89      .000    Initial version.
; 1/3/90        .001    Add pointer for default.
; 1/8/90        .002    Add target type.
; 1/31/90       .003    Add desc so temps can be erased.
;----------------------------------------------------------------------
PUBLIC      R$PARSEDEF
PUBLIC      R$PARSESTR
PUBLIC      TARGET_TYPE
PUBLIC      INPUT_DESC

EXTRN       P$MAKETEMP:FAR

;======================================================================
; By default, R$PARSESTR contains -1, indicating that the READ/DATA
;  functions have not been enabled explicitly and that neither B$DSKI
;  has been called (to read from a disk) or B$INPP (to read from the
;  console.  These routines place a valid address into this location.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG,USEG

DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

R$PARSEDEF  DW  OFFSET CSEG:R$DUMMY
R$PARSESTR  DW  OFFSET CSEG:R$DUMMY
INPUT_DESC  DW  0

DSEG        ENDS

USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized

TARGET_TYPE DB  1 DUP(?)

USEG        ENDS

;======================================================================
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

;======================================================================
; R$DUMMY
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Allocate an empty string.
;----------------------------------------------------------------------
R$DUMMY     PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            XOR     CX,CX
            CALL    P$MAKETEMP
            XCHG    AX,BX
            RET

R$DUMMY     ENDP

CSEG        ENDS
            END
