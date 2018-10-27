; TESTKEY.ASM
;  TestHotKey PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/16/89       Stable.
; 7/29/89       .000    Split into file TSR6.
; 9/9/89        .001    Update doc, segs.
; 1/8/90        .002    Unified include file.
;----------------------------------------------------------------------
PUBLIC          TestHotKey

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU
DSEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; TestHotKey
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Given a shift mask and scan code, will test to see if that's what
;    was just hit and return TRUE or FALSE.
;----------------------------------------------------------------------
; Usage:
;       IF TestHotKey%(ARG%) THEN ...
; where
;       ARG% = SHIFTMASK*256+SCANCODE
;----------------------------------------------------------------------
TestHotKey      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                MOV     BX,WORD PTR [BP+6]      ;Get argument in BX
                MOV     BX,WORD PTR [BX]

                IN      AL,60H                  ;Get key scan code
                CMP     AL,BL                   ;Check if hot-key
                JE      THK_2
;----------------------------------------------------------------------
; No match, return failure
;----------------------------------------------------------------------
THK_0:
                MOV     AX,FALSE                ;No match
THK_1:
                POP     BP                      ;Erase stack frame
                RET     2                       ;RETF, discard 1 param
;----------------------------------------------------------------------
; Check for shift status.
;----------------------------------------------------------------------
THK_2:
                MOV     AH,2                    ;Get shift status fn
                INT     16H                     ;Thru BIOS

                AND     AL,0FH                  ;Test only for 'shift' keys
                CMP     AL,BH                   ;If they match our combination
                JNE     THK_0                   ;then is our signal

                MOV     AX,TRUE                 ;Hotkey matched
                JMP     THK_1                   ;Exit

TestHotKey      ENDP

CSEG            ENDS
                END
