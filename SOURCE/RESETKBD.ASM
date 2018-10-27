; RESETKBD.ASM
;  ResetKeyboard PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/16/89       Stable.
; 7/29/89       .000    Split into file TSR7.
; 9/9/89        .001    Update doc, segs.
; 1/8/90        .002    Unified include file.
;----------------------------------------------------------------------
PUBLIC  ResetKeyboard

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
; ResetKeyboard
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Reset the interrupt controller (forget the key stroke).
;----------------------------------------------------------------------
; Usage:
;       CALL ResetKeyboard
;----------------------------------------------------------------------
ResetKeyboard   PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                IN      AL,61H                  ;These instructions reset
                MOV     AH,AL                   ; the keyboard.
                OR      AL,80H
                OUT     61H,AL
                MOV     AL,AH
                JMP     SHORT $+2               ;I/O delay
                OUT     61H,AL
                CLI                             ;Disable interrupts and
                MOV     AL,20H                  ;reset the int controller
                OUT     20H,AL
                STI                             ;Allow interrupts

                RET                             ;RETF

ResetKeyboard   ENDP

CSEG            ENDS
                END
