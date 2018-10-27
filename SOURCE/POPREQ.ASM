;POPREQ.ASM
;======================================================================
; PopRequest:PDQ
;   Copyright (c) 1990-1991 Crescent Software
;   Copyright (c) 1990-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; PopRequest is called from somewhere in a PDQ program (such as a
;   discrete interrupt handler) to pass a pop up request to the TSR
;   routines. If a request is already pending, this request is ignored.
; This routine works only for non-swapping TSRs!
;----------------------------------------------------------------------
; 8/18/91   .000    Split from POPUP.ASM.
; 9/18/91   .001    Modify for swapping.
;----------------------------------------------------------------------
PUBLIC  PopRequest

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU
DSEG            ENDS

;======================================================================
;
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EXTRN   REQ_FLAG_PTR:WORD   ;In core
EXTRN   REQ_TIMER:WORD      ;In core

RLHSEG      ENDS

;======================================================================
; This data MUST stay in the code segment. Don't move it.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; PopRequest (PDQ)
;   Copyright (c) 1990-1991 Crescent Software
;   Copyright (c) 1990-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Usage:
;       RESULT = PopRequest%(FlagName, TimerTicks)
; where
;       FlagName = Integer variable. Will be set TRUE if this request
;                  eventually caused the simplified routine to pop up.
;                  Cleared to FALSE by this call.
;       TimerTicks = Number of timer ticks that this request should
;                    remain in effect. 18 = 1 sec. -1 = 1 hour.
;       RESULT = TRUE if the request was accepted.
;                FALSE if a previous request was pending.
;----------------------------------------------------------------------
; Notes:
; 1. No request (except from the keyboard) will be acknowledged if another
;    is pending.
; 2. A keyboard request overrides any pending requests and does so without
;    notifying anyone.
;----------------------------------------------------------------------
PopRequest      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP
                MOV     BP,SP
;----------------------------------------------------------------------
; If a request is already pending, ignore this one.
;----------------------------------------------------------------------
                MOV     AX,RLHSEG
                MOV     ES,AX
        ASSUME  ES:RLHSEG

                MOV     AX,FALSE      ;Assume failure as function output
                CMP     WORD PTR ES:[REQ_TIMER],0
                JNE     PR_EXIT
;----------------------------------------------------------------------
; No other request pending. Put us at the head of the line.
;----------------------------------------------------------------------
                MOV     BX,WORD PTR [BP+8]           ;Adr of flag
                MOV     WORD PTR [BX],AX             ;Initialize to false

                MOV     AX,TRUE

                CLI
                MOV     WORD PTR ES:[REQ_FLAG_PTR],BX   ;Save Flag's address

                MOV     BX,WORD PTR [BP+6]              ;get the number of
                MOV     BX,WORD PTR [BX]                ; ticks to re-try

                MOV     WORD PTR ES:[REQ_TIMER],BX      ;and save it
;----------------------------------------------------------------------
; Exit the routine.
;----------------------------------------------------------------------
PR_EXIT:
                POP     BP
                STI
                RET     4

PopRequest      ENDP

CSEG            ENDS
                END
