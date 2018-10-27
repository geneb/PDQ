;======================================================================
; RESTORE.ASM
;  B$RSTA PDQ:FAR
;  B$RSTB PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1/4/90        .000    Split out and fix up. Change include file.
; 3/13/90       .001    Add call to P$DoError (Ethan)
; 3/13/90       .002    Adjusted SI downward by 2 just below RSTB_4: (EW)
;                       Added SS: override just below label RSTB_4: (EW)
; 3/14/90       .003    Changed JE to JAE just above label RSTB_2: (EW)
; 10/3/90       .004    Update for separate OBJ reads.
; 10/7/90       .005    Excise common code.
;----------------------------------------------------------------------
PUBLIC  B$RSTA  ;FAR
PUBLIC  B$RSTB  ;FAR

EXTRN   P$DOERROR:FAR       ;in DOERROR.ASM
EXTRN   R$FIND_DATA:NEAR    ;In FINDDATA.ASM

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG, USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

INCLUDE R$PDQ.EQU
BAD_LABEL   EQU -1              ;error code
EXTRN       P$PDQERR:WORD       ;this is in ERRDATA.ASM

DSEG        ENDS
;----------------------------------------------------------------------
USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized
USEG        ENDS

;======================================================================
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; B$RSTA - Restore All Data in THIS object module.
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; CHANGES: BX, ES
;----------------------------------------------------------------------
B$RSTA      PROC    FAR
    ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

        PUSH    BP          ;Phony stack frame
        MOV     BP,SP
;----------------------------------------------------------------------
; Reseting the "Data has been read" flag restores the data.
;----------------------------------------------------------------------
        CALL    R$FIND_DATA
    ASSUME  ES:NOTHING
        MOV     WORD PTR DS:[BX],0

        POP     BP
        RET

B$RSTA      ENDP

;======================================================================
; B$RSTB - Restore Data From A Location
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; CHANGES: AX BX CX ES
;----------------------------------------------------------------------
B$RSTB      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

        PUSH    BP                      ;Create stack frame
        MOV     BP,SP

        PUSH    SI

        MOV     WORD PTR [P$PDQERR],0
;----------------------------------------------------------------------
; Find the data pointers.
;----------------------------------------------------------------------
        CALL    R$FIND_DATA
    ASSUME  ES:NOTHING
;----------------------------------------------------------------------
; Point DS:SI to start of DATA.  Search for the correct label.
;----------------------------------------------------------------------
        MOV     SI,WORD PTR ES:[0CH]    ;Start of DATA in DGROUP
;;;     SUB     SI,2                    ;Point to label
        DEC     SI
        DEC     SI

        MOV     CX,WORD PTR [BP+6]       ;Label to match
;----------------------------------------------------------------------
; Label is first word on line. If no match, scan for ending zero, then
; try again.
;----------------------------------------------------------------------
RSTB_1:
        LODSW                           ;Get label in AX

        CMP     AX,-1                   ;Out of data?
        JE      RSTB_3

        CMP     AX,CX                   ;Label match?
        JAE     RSTB_4
RSTB_2:
        LODSB                           ;Scan data

        OR      AL,AL                   ;Till zero
        JNZ     RSTB_2
        JMP     RSTB_1
;----------------------------------------------------------------------
; Tried to restore a label that didn't exist.
;----------------------------------------------------------------------
RSTB_3:
        MOV     WORD PTR [P$PDQERR],BAD_LABEL
        CALL    P$DOERROR
        JMP     RSTB_EXIT
;----------------------------------------------------------------------
; Set flags to indicate that data has been read (ie, pointer is valid).
; Pointer points to the label that matched.
;----------------------------------------------------------------------
RSTB_4:
;;;     SUB     SI,2                    ;Point to label
        DEC     SI
        DEC     SI

        MOV     WORD PTR [BX],1         ;Queue new line
        MOV     WORD PTR [BX+2],SI      ;Set pointer
;----------------------------------------------------------------------
; Return to PDQ.
;----------------------------------------------------------------------
RSTB_EXIT:
        POP     SI
        POP     BP
        RET     1 * 2

B$RSTB      ENDP

CSEG        ENDS
        END
