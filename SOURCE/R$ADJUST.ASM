; R$ADJUST.ASM
;   ADJUST_STRING (Internal:NEAR)
;----------------------------------------------------------------------
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1/30/90   .000    Split from R$DSKI.
; 4/19/90   .001    Adjust by 2 extra bytes if a null is entered (Ethan)
;----------------------------------------------------------------------
PUBLIC  ADJUST_STRING ;NEAR

INCLUDE R$PDQ.EQU
;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG, USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

EXTRN   P$BYTESFREE:WORD
EXTRN   P$BYTESUSED:WORD

DSEG        ENDS
;----------------------------------------------------------------------
USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized
USEG        ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; ADJUST_STRING
;   Copyright (c) 1989 Crescent Software
;   Copyright (c) 1989 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;   BX - string desc pointer
;   CX - length to make string
;----------------------------------------------------------------------
; Changes: CX
;----------------------------------------------------------------------
ADJUST_STRING   PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

            XCHG    CX,WORD PTR [BX]
            SUB     CX,WORD PTR [BX]

            CMP     WORD PTR [BX],0     ;was a null string entered?
            JNE     @F                  ;no, continue
            INC     CX                  ;yes, so we don't need the two
            INC     CX                  ;  extra bytes for the back pointer

@@:
            ADD     WORD PTR [P$BYTESFREE],CX
            SUB     WORD PTR [P$BYTESUSED],CX

            RET

ADJUST_STRING   ENDP

CSEG        ENDS
            END
