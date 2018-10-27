; READSTR.ASM
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1/8/90        .000    Split from R$RD.
; 3/16/90       .001    Allow inputting fixed-length strings (Ethan)
;----------------------------------------------------------------------
PUBLIC      B$RDSD

EXTRN       B$SASS:FAR      ;this is in ASSIGN$.ASM
EXTRN       B$ASSN:FAR      ;this is in ASSIGN.ASM

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG,USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

INCLUDE     R$PDQ.EQU

EXTRN       R$PARSESTR:WORD                 ;In R$RDPTR.ASM

DSEG        ENDS

USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized

EXTRN       TARGET_TYPE:BYTE                ;In R$RDPTR.ASM

USEG        ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; B$RDSD
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Read a string from the indicated source.
;----------------------------------------------------------------------
B$RDSD      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            PUSH    BP
            MOV     BP,SP

            MOV     BYTE PTR [TARGET_TYPE],_STRING
            CALL    WORD PTR [R$PARSESTR]   ;Returns the descriptor in AX

            CMP     WORD PTR [BP+6],0       ;is the assignee fixed-length?
            JE      RDSD_1                  ;no, use B$SASS to assign it

            PUSH    DS                      ;yes, pass the segmented source
            PUSH    AX                      ;  to B$ASSN
            XOR     AX,AX                   ;the source is not fixed-length
            PUSH    AX
            
            PUSH    WORD PTR [BP+10]        ;and the assignee's segment 
            PUSH    WORD PTR [BP+8]         ;  and address
            PUSH    WORD PTR [BP+6]         ;  and length
            CALL    B$ASSN                  ;this assigns fixed-length data
            JMP     SHORT RDSD_EXIT         ;skip over
RDSD_1:
            PUSH    AX
            PUSH    WORD PTR [BP+8]

            CALL    B$SASS

RDSD_EXIT:
            POP     BP
            RET     3 * 2

B$RDSD      ENDP

CSEG        ENDS
            END
