;********** PDQ.ASM - alternate PDQ startup code replacement for QuickBASIC

; Copyright (c) 1989-1991 Crescent Software
; Copyright (c) 1989-1991 Schaefer Software, by Robert L. Hummel
;
; 6/10/89       .002    Revised for stack frame.
; 6/11/89       .003    Modify $AC termination.
; 6/16/89       .004    Add TSR support.
; 6/16/89       .005    Updated by Ethan.
; 1/5/90        .006    Change segment ordering
; 3/11/90       .007    Add code to hook/unhook an Interrupt 39h handler
; 3/18/90       .008    Change the BP fudge from 0AH to 12H for BASIC 7
; 6/21/90       .009    Add support for DOS 2.x bug.
; 6/23/90       .010    Save PSP.
; 6/26/90       .011    Change name of Hook/Unhook39 to Hook/UnhookFP (Ethan)
; 12/17/90      .012    Move code to clear P$TempDesc to TEMPDESC.ASM (Ethan)
; 3/30/91       .013    Delete EXTRN for P$UNHOOKFP
; 5/20/91       .014    Always locate DOS Critical Error Flag
; 7/11/91       .015    Made TSR segment PARA align so /st: handles odd nums
; 12/5/91       .016    Get BC_SA from DGROUP relative.
;------------------------------------------------------------------------
; PDQ Segment definitions.  Do not change names OR order.  All of the data
; items in the _DATA segment below are stored in PDQDATA.ASM
;------------------------------------------------------------------------
DOSSEG

PUBLIC  R$DOSCRIT   ;DWORD

EXTRN   ENABLEREAD:FAR              ;this is in ENABLERD.ASM
EXTRN   P$HOOKFP:FAR                ;in P$HOOKFP, _87ONLY, _EMONLY, DEBUGFP

DGROUP  GROUP   BR_DATA, BR_SKYS, COMMON, BC_DATA, NMALLOC, ENMALLOC, BC_FT
DGROUP  GROUP   BC_CN, BC_DS, BC_SAB, BC_SA, _DATA, _BSS, PDQ_STACK, __TSR

BR_DATA         SEGMENT PARA    PUBLIC  'BLANK'
BR_DATA         ENDS

BR_SKYS         SEGMENT PARA    PUBLIC  'BLANK'
BR_SKYS         ENDS

COMMON          SEGMENT PARA    COMMON  'BLANK'
COMMON          ENDS

BC_DATA         SEGMENT WORD    PUBLIC  'BC_VARS'
BC_DATA         ENDS

NMALLOC         SEGMENT WORD    COMMON  'BC_VARS'
NMALLOC         ENDS

ENMALLOC        SEGMENT WORD    COMMON  'BC_VARS'
ENMALLOC        ENDS

BC_FT           SEGMENT WORD    PUBLIC  'BC_SEGS'
BC_FT           ENDS

BC_CN           SEGMENT PARA    PUBLIC  'BC_SEGS'
BC_CN           ENDS

BC_DS           SEGMENT PARA    PUBLIC  'BC_SEGS'
BC_DS           ENDS

BC_SAB          SEGMENT WORD    PUBLIC  'BC_SEGS'
BC_SAB          ENDS

BC_SA           SEGMENT WORD    PUBLIC  'BC_SEGS'
BC_SA           ENDS

;----------------------------------------------------------------------
; Simplified segment definitions.
;----------------------------------------------------------------------
_DATA           SEGMENT WORD    PUBLIC  'DATA'  ;Initialized
    ;----- All of these data items are in PDQDATA.ASM
    EXTRN   P$DosVer:Word   ;this holds the current DOS version
    EXTRN   B$Seg:Word      ;this holds the default DEF SEG value
    EXTRN   P$PSPSeg:Word   ;this holds the PSP segment
    EXTRN   P$TermCode:Byte ;this holds the ERRORLEVEL value
    EXTRN   _SPSave:Word    ;this saves the stack pointer
    EXTRN   P$ExitAdr:Word  ;this holds the address of the "On Exit" routine
_DATA           ENDS

_BSS            SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized
    R$DOSCRIT   DD  1 DUP (?)
_BSS            ENDS

;----------------------------------------------------------------------
; Local segments.
;----------------------------------------------------------------------
PDQ_CODE        SEGMENT PARA    PUBLIC  'CODE'
PDQ_CODE        ENDS

PDQ_STACK       SEGMENT PARA    STACK   'STACK'
PDQ_STACK       ENDS

__TSR           SEGMENT PARA    PUBLIC  'STACK'
__TSR           ENDS

;======================================================================
; Stack Segment. The size may be altered by LINK /ST= option.
;----------------------------------------------------------------------
PUBLIC          PDQ_STACK_FOOT, PDQ_STACK_HEAD

PDQ_STACK       SEGMENT PARA    STACK   'STACK'

PDQ_STACK_FOOT  DB      1024 DUP (?)
PDQ_STACK_HEAD  EQU     $

PDQ_STACK       ENDS

;======================================================================
; Code Segments.
;----------------------------------------------------------------------
PDQ_CODE          SEGMENT PARA    PUBLIC  'CODE'

PUBLIC      __ASTART                ;this is needed for compatibility with
__ASTART    PROC    FAR             ;  MicroHelp's SuperShell utility
__ASTART    ENDP

STARTUP     PROC    FAR
            ASSUME  CS:PDQ_CODE,DS:NOTHING,ES:NOTHING,SS:PDQ_STACK

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
                MOV     [P$DOSVer],AX
;----------------------------------------------------------------------
; Find the location of the DOSCRIT flag that indicates when we're in a
; critical error situation. This is used in DOS 2.x when using INT 21h,
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
; the correct area we need to function. Terminate with a fatal error.
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

;----------------------------------------------------------------------
; The code produced by the BC compiler starts in a separate segment.
; Retrieve certain data parameters including the entry point of the
; BASIC program.  Because the BC_SA segment is word aligned, address
; it as an offset from DGROUP.
;----------------------------------------------------------------------
                MOV     BX,OFFSET DGROUP:BC_SAB
                MOV     BX,WORD PTR [BX][2]     ;Segment of BASIC code

;----------------------------------------------------------------------
; Create work area on the stack.  12h bytes are reserved by BASIC and
; duplicated here.
;----------------------------------------------------------------------
                MOV     ES,BX                   ;(Access data area)
        ASSUME  ES:NOTHING
                MOV     CX,WORD PTR ES:[22H]    ;Program stack frame
                MOV     BP,SP                   ;Top of stack
                ADD     CX,12H                  ;BASIC stores temps here
                                                ;  (using BP-xx instructions)
                SUB     SP,CX                   ;Adjust pointer
                MOV     WORD PTR [_SPSAVE],SP   ;save SP for access any time

                PUSH    BX                      ;Save BASIC's code segment
                                                ;in anticipation of Ret below
                
;----------------------------------------------------------------------
; Set up access to BASIC data.
;----------------------------------------------------------------------
                PUSH    DS                      ;Put DGROUP in ES
                POP     ES
        ASSUME  ES:DGROUP
                MOV     WORD PTR [B$Seg],DS     ;Set default for DEF SEG

;----------------------------------------------------------------------
; Set up the Interrupt 39h floating point handler and set the input
; kernal to READ DATA by default (as opposed to INPUT or INPUT #1).
;----------------------------------------------------------------------
                CALL    P$HOOKFP
                CALL    ENABLEREAD
                
;----------------------------------------------------------------------
; Set up FAR RET to start of BASIC code by pushing IP on the stack.
; The CS (in BX) was already puished above.
;----------------------------------------------------------------------
                MOV     CX,30H          ;Offset of basic program
                PUSH    CX              ; on stack
                
                RET                     ;Far return to start program

STARTUP         ENDP

;----------------------------------------------------------------------
; This is where we come when the program ends.
;----------------------------------------------------------------------
           PUBLIC  $AC, $DAC, B$CEND, B$CENP, B$STOP

$AC             PROC    FAR      ;BC sometimes calls this to end
$DAC            PROC    FAR      ;if this is ever called, end the program
B$CEND          PROC    FAR      ;this is called when you use END
B$CENP          PROC    FAR      ;this is called when a program runs out
B$STOP          PROC    FAR      ;this is called when a program uses STOP

                CALL    DWORD PTR P$EXITADR ;deinstall whatever hooked itself
                                            ;(default to the Int 39h handler)
                MOV     AL,BYTE PTR [P$TermCode]  ;error level
                MOV     AH,4CH                    ;end the "BASIC" program
                INT     21H

B$STOP          ENDP
B$CENP          ENDP
B$CEND          ENDP
$DAC            ENDP
$AC             ENDP

PDQ_CODE        ENDS
                END     STARTUP
