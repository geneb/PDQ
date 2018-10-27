;********* STARTUP.ASM - startup code and segment definitions replace PDQ.ASM

;Copyright (c) 1989-1991 Crescent Software
;Copyright (c) 1989-1991 Schaefer Software, by Robert L. Hummel


DOSSEG

EXTRN   MAIN: FAR                   ;this is -your- program

PUBLIC  R$DOSCRIT, PDQ_STACK_FOOT, PDQ_STACK_HEAD
PUBLIC  __ASTART, B$CEND

DGROUP  GROUP COMMON, _DATA, _BSS, PDQ_STACK, __TSR

COMMON  SEGMENT PARA COMMON 'BLANK'
COMMON  ENDS

_DATA   SEGMENT WORD PUBLIC 'DATA'  ;these data items are in PDQDATA.ASM
    EXTRN   P$DOSVER    : WORD      ;the current DOS version
    EXTRN   B$SEG       : WORD      ;the default DEF SEG value
    EXTRN   P$PSPSEG    : WORD      ;the PSP segment
    EXTRN   P$TERMCODE  : BYTE      ;the ERRORLEVEL value
    EXTRN   _SPSAVE     : WORD      ;the stack pointer
    EXTRN   P$EXITADR   : WORD      ;the address of the "On Exit" routine
_DATA   ENDS

_BSS        SEGMENT WORD PUBLIC 'BSS'
    R$DOSCRIT   DD  1 DUP (?)
_BSS        ENDS

PDQ_CODE    SEGMENT PARA PUBLIC 'CODE'
PDQ_CODE    ENDS

PDQ_STACK   SEGMENT PARA STACK 'STACK'
PDQ_STACK   ENDS

__TSR       SEGMENT PARA PUBLIC 'STACK'
__TSR       ENDS

PDQ_STACK   SEGMENT PARA STACK 'STACK'
    PDQ_STACK_FOOT DB 1024 DUP (?)
    PDQ_STACK_HEAD EQU $
PDQ_STACK   ENDS

PDQ_CODE    SEGMENT PARA PUBLIC 'CODE'
    __ASTART PROC FAR               ;this is needed for compatibility with
    __ASTART ENDP                   ;  MicroHelp's SuperShell utility


STARTUP     PROC    FAR
        ASSUME CS:PDQ_CODE, DS:NOTHING, ES:NOTHING, SS:PDQ_STACK

;-----------------------------------------------------------------------
; On startup, DS and ES point to the PSP segment. Point DS to the DGROUP
; data segment to correctly address the BASIC data and load the PSP seg
; from ES into a public variable.
;-----------------------------------------------------------------------
                MOV     AX,DGROUP
                MOV     DS,AX
        ASSUME  DS:DGROUP
                MOV     WORD PTR [P$PSPSeg],ES
;----------------------------------------------------------------------
; SS and SP are adjusted so that they point to the same place in memory,
; but SS=DS and SP is relative to the start of DGROUP.
;----------------------------------------------------------------------
                CLI
                MOV     SS,AX
                MOV     SP,OFFSET DGROUP:PDQ_STACK_HEAD
                STI
        ASSUME  SS:DGROUP
;-------------------------------------------------------------------------
; Get the version of DOS, and save it for easy access later on.  This also
; lets us get it anytime within a TSR, without having to invoke a DOS call.
;-------------------------------------------------------------------------
                MOV     AH,30H
                INT     21H
                MOV     P$DOSVer,AX
;----------------------------------------------------------------------
; Find the location of the DOSCRIT flag that indicates when we're in a
; critical error situation.  This is used in DOS 2.x when using Int 21h,
; AH=50h and 51h and in all versions for TSRs.
;----------------------------------------------------------------------
                PUSH    ES              ;Save PSP
                PUSH    AX              ;Save DOS version
                MOV     AH,34H          ;Get DOS seg in ES
                INT     21H
    ASSUME  ES:NOTHING
                MOV     WORD PTR [R$DOSCRIT][2],ES  ;Save segment

                MOV     AX,BX           ;Save offset in AX
                DEC     AX              ;Point to DOSCRIT if

                POP     BX              ;Put version in BX
                XCHG    BL,BH           ;Fix version number
                CMP     BX,030AH        ; ver 3.10 or later
                JAE     PDQ_1D

                MOV     CX,0FFFFH       ;Search whole segment
                XOR     DI,DI           ; from beginning
                
                MOV     AX,28CDH        ;Int 28h opcode is target
PDQ_1B:
                REPNE   SCASB           ;Scan for first byte
                JE      PDQ_1C
;----------------------------------------------------------------------
; If we get here, then we scanned the entire DOS segment without finding
; the correct area we need to function.  Terminate with a fatal error.
;----------------------------------------------------------------------
                XOR     AX,AX           ;we'll check for this 0 in the future
                JMP     SHORT PDQ_1D
;----------------------------------------------------------------------
; The first byte of the opcode (INT) was found. Check for the second one.
;----------------------------------------------------------------------
PDQ_1C:
                CMP     AH,BYTE PTR ES:[DI] ;If not, continue search
                JNE     PDQ_1B
;----------------------------------------------------------------------
; Found INT 28h. Now check for reference to CRITFLAG.
;----------------------------------------------------------------------
                CMP     WORD PTR ES:[DI-8],3E80H    ;If not, search
                JNE     PDQ_1B
                MOV     AX,WORD PTR ES:[DI-6]       ;Loc of CRITFLAG
PDQ_1D:
                MOV     WORD PTR [R$DOSCRIT],AX     ; and save it
                POP     ES
;----------------------------------------------------------------------
; Adjust memory allocation down to fit program.
;----------------------------------------------------------------------
                MOV     AX,ES
                MOV     BX,__TSR
                SUB     BX,AX
                MOV     AH,4AH
                INT     21H
                
                MOV     WORD PTR [_SPSAVE],SP   ;save SP for access any time
                
;----------------------------------------------------------------------
; Set up access to BASIC data.
;----------------------------------------------------------------------
                PUSH    DS                      ;Put DGROUP in ES
                POP     ES
        ASSUME  ES:DGROUP
                MOV     WORD PTR [B$Seg],DS     ;Set default for DEF SEG

;----------------------------------------------------------------------
; Jump into the main program.
;----------------------------------------------------------------------
                JMP     FAR PTR MAIN
STARTUP         ENDP

;----------------------------------------------------------------------
; This is where we come when the program ends.
;----------------------------------------------------------------------
B$CEND          PROC    FAR    
                MOV     AL,BYTE PTR [P$TermCode]  ;error level
                MOV     AH,4CH                    ;end the program
                INT     21H
B$CEND          ENDP

PDQ_CODE        ENDS
                END     STARTUP
