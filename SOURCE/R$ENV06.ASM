; FILE: R$ENV06.ASM
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 8/27/89       .000    Initial.
; 9/3/89        .001    Get_env_seg error return updated.
; 1/8/90        .002    Unified include file.
;----------------------------------------------------------------------
PUBLIC  MATCH_ENV_STR   ;Proc, near

EXTRN   GET_ENV_SEG:NEAR       ;these are in R$ENV05.ASM
EXTRN   GET_ENV_STR:NEAR

;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU
DSEG            ENDS
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'
EXTRN           R$ENVSTRLEN:WORD    ;these are in R$ENV05.ASM
EXTRN           R$ENVSTRPTR:WORD
USEG            ENDS
;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG
;======================================================================
; MATCH_ENV_STR
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;       DS:SI -> env variable to match
;       CX = number of bytes in variable
; Exit:
;       CY - no match found or other error
;       ES = 0 means requested environment was invalid
;
;       NC - match found, info as follows:
;       ES:SI -> argument in environment "yy"
;       CX = length of argument
; note:
;       ES:(DS:[R$ENVSTRPTR]) -> string in environment "xx=yy"
;       length of entire string in [R$ENVSTRLEN]
;----------------------------------------------------------------------
; Changes: ES CX SI
;----------------------------------------------------------------------
MATCH_ENV_STR   PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    AX
                PUSH    BX                      ;Save used registers
                PUSH    DI

                CLD                             ;String compare forward
                MOV     BX,CX                   ;Save length of variable
                MOV     AX,SI                   ;Save offset
;----------------------------------------------------------------------
; Locate the specified environment.  Sets ES and variables.
;----------------------------------------------------------------------
                CALL    GET_ENV_SEG             ;Locate correct env
        ASSUME  ES:NOTHING
                JC      MES_EXIT
;----------------------------------------------------------------------
; Point ES:DI to a string in the environment, CX = length of entire string.
;----------------------------------------------------------------------
MES_1:
                CALL    GET_ENV_STR             ;Get next entry in ES:DI
        ASSUME  ES:NOTHING
                JC      MES_EXIT
;----------------------------------------------------------------------
; Try to match the string until found or no more strings found.
;----------------------------------------------------------------------
                MOV     CX,BX                   ;Length to match
                MOV     SI,AX                   ;Start of string

                REPE    CMPSB                   ;Compare while equal
                JNE     MES_1                   ;char NE, try next string

                CMP     BYTE PTR ES:[DI],"="    ;Match whole entry?
                JNE     MES_1
;----------------------------------------------------------------------
; String was matched. ES:DI -> "=yy".  Calculate lenth of string.
; Return ES:SI -> argument, CX length of argument.
;----------------------------------------------------------------------
                INC     DI                        ;Point past equal sign
                MOV     SI,DI                     ;Return ptr in SI

                SUB     DI,WORD PTR [R$ENVSTRPTR] ;Len of "var="
                MOV     CX,WORD PTR [R$ENVSTRLEN] ;Total length of env entry
                SUB     CX,DI                     ;Length remaining
MES_EXIT:
                POP     DI                        ;Restore used registers
                POP     BX
                POP     AX
                RET

MATCH_ENV_STR   ENDP

CSEG            ENDS
                END
