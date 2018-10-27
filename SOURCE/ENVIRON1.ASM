; FILE: ENVIRON1.ASM
; Integer implementation of the ENVIRON$ function.
;       Copyright (c) 1989 Crescent Software
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 8/13/89       .000    Initial.
; 8/14/89       .001    Modify addressing.
; 8/27/89       .002    Update for new GET_ procs.
; 9/16/89       .003    Add pdqerr return.
;----------------------------------------------------------------------
PUBLIC  B$FEVI                  ;A$=ENVIRON$(1)

EXTRN   P$MakeTemp:FAR          ;This is in MAKETEMP.ASM
EXTRN   GET_ENV_STR:NEAR        ;In R$ENV05
EXTRN   GET_ENV_SEG:NEAR        ;In R$ENV05

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
EXTRN   P$PDQERR:WORD           ;this is in ERRDATA.ASM
DSEG            ENDS
;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
;======================================================================
; B$FEVI (PDQ)
;       Copyright (c) 1989 Crescent Software
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Usage:
;       A$=ENVIRON$(B%)
;----------------------------------------------------------------------
; 1. Stack contain the number of the string to find, NOT a ptr to number.
; 2. Returns AX -> string descriptor.
; 3. If no string of that number, returns null descriptor.
; 4. If short of string space, returns truncated string.
;----------------------------------------------------------------------
; 8/14/89       Use effective addressing for external descriptor.
;----------------------------------------------------------------------
B$FEVI          PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                MOV     WORD PTR [P$PDQERR],0   ;Initialize error

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP
                PUSH    SI                      ;Saved used registers
                PUSH    DI
;----------------------------------------------------------------------
; If environment cannot be located, fail.
;----------------------------------------------------------------------
                CALL    GET_ENV_SEG             ;Locate correct env
        ASSUME  ES:NOTHING
                JC      MAKENULL

                MOV     AX,WORD PTR [BP+6]      ;Entry # to find
;----------------------------------------------------------------------
; Point ES:DI to the next string in the environment.
;----------------------------------------------------------------------
FEVI_1:
                CALL    GET_ENV_STR             ;Get next entry in ES:DI
        ASSUME  ES:NOTHING
                JC      MAKENULL      ; Fail by returning zero length string.

;----------------------------------------------------------------------
; Count down entries until correct number or out of strings.
;----------------------------------------------------------------------
FEVI_2:
                DEC     AX                      ;Adjust count
                JNZ     FEVI_1                  ;If not done, continue
                MOV     SI,DI                   ;Save env str offset
;----------------------------------------------------------------------
; ES:SI now points to the entire entry "xx=yy".
;----------------------------------------------------------------------
                PUSH    DS                      ;Current DGROUP
                PUSH    ES                      ;Save env segment
;----------------------------------------------------------------------
                CALL P$MakeTemp                 ;Ethan's routine
                POP     DS                      ;Point DS to env
        ASSUME  DS:NOTHING

                REP     MOVSB                   ;mov CX bytes DS:SI->ES:DI
                POP     DS                      ;Restore DGROUP
        ASSUME  DS:DGROUP
FEVI_EXIT:
                MOV     AX,BX                   ;Desc ptr in AX

                POP     DI                      ;Restore registers
                POP     SI
                POP     BP                      ;Erase stack frame
                RET     2                       ;Discard 1 param

MAKENULL:
                XOR     CX,CX                   ;return a null string
                CALL    P$MakeTemp
                JMP     SHORT FEVI_EXIT         ;and exit

B$FEVI          ENDP

CSEG            ENDS
                END
