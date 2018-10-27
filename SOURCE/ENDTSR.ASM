;======================================================================
; ENDTSR.ASM
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 6/11/89   .000    Initial, no memory allocation.
; 7/4/89    .001    Add ID string.
; 7/17/89   .002    Update doc.
; 7/29/89   .003    Add RESIDENT flag.
; 7/30/89   .004    Update flag declaration, change name.
;                   Move flag=true to later position.
; 9/9/89    .005    Clean up.
; 9/25/89   .006    Move extrns.
; 1/5/90    .007    Change segment ordering.
; 9/18/91   .008    Modify for swapping.
;                   Store ID string.
; 9/20/91   .009    Leave original string unchanged.
; 9/20/91   .010    Add near call patch to swap init code.
; 9/23/91   .011    Change patch details, labels.
; 10/3/91   .012    Move resident flag set.
; 10/5/91   .013    Final patch iteration.
; 10/8/91   .014    Allow for swapping failure.
; 10/10/91  .015    Redo externs.
; 10/15/91  .016    Add STACK segment.
; 11/2/91   .017    Changed B$STOP call to B$CEND to work with STARTUP.ASM
;----------------------------------------------------------------------
PUBLIC  EndTsr      ;FAR, PDQ
PUBLIC  R$ENDTSR$1  ;LABEL

EXTRN   B$CEND:FAR  ;In PDQ.ASM

;======================================================================
; Externals.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EXTRN   R$ID:BYTE   ;In R$TSRDAT.ASM

RLHSEG      ENDS

;======================================================================
; End of program in memory.
;----------------------------------------------------------------------
PDQ_STACK       SEGMENT PARA    STACK   'STACK'
PDQ_STACK       ENDS

__TSR           SEGMENT PARA    PUBLIC  'STACK'
__TSR           ENDS

;======================================================================
; DGROUP addressing fixed by linker.  __TSR seg for internal use only.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,__TSR

DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU

EXTRN   P$PSPseg:WORD   ;In PDQDATA.ASM
EXTRN   P$TermCode:BYTE ;In PDQDATA.ASM
EXTRN   _RESIDENT:WORD  ;In PDQDATA.ASM

ERR$SWAPFAILURE EQU -1

DSEG            ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; EndTSR (PDQ)
;  Copyright (c) 1989-1991 Crescent Software
;  Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Makes the P.D.Q. program resident with the normal restrictions: no
;    DOS or BIOS calls without precautions.  No memory allocation.  No
;    SHELL or RUN.  No file activity without swapping PSPs and DTAs.
;    See manual for more information.
; 2. The length of the PSP block is specified.  Other memory allocated by
;    the program is kept automatically.
;----------------------------------------------------------------------
; Usage:
;       Call EndTSR(ID$)
; where:
;       ID$ = string, at least 8 chars, that uniquely identifies the program.
;----------------------------------------------------------------------
; Changes: Don't matter because it doesn't return
;----------------------------------------------------------------------
EndTsr          PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP
;----------------------------------------------------------------------
; Copy the ID string that is used to identify the program in memory to
; this segment, then alter it.  Original string is not changed.
;----------------------------------------------------------------------
                MOV     AX,RLHSEG               ;Destination seg
                MOV     ES,AX
        ASSUME  ES:RLHSEG
                MOV     DI,OFFSET RLHSEG:R$ID   ; and offset
;----------------------------------------------------------------------
; Point DS:SI to passed ID string.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BP+6]      ;Get ptr to string desc.
                MOV     CX,WORD PTR [SI]        ;Length of string
                CMP     CX,16
                JLE     ET_1

                MOV     CX,16                   ;Maximum 16 chars
ET_1:
                MOV     SI,WORD PTR [SI+2]      ;String offset
;----------------------------------------------------------------------
; Copy the string and modify the RLHSEG version.
;----------------------------------------------------------------------
                PUSH    DI
                REP     MOVSB
                POP     DI
                NOT     WORD PTR ES:[DI]

;----------------------------------------------------------------------
; Terminate and stay resident, specifying the amount of PSP-contiguous
; memory to keep.
;----------------------------------------------------------------------
                MOV     DX,__TSR                ;Paragraph end of program
                MOV     AX,WORD PTR [P$PSPseg]  ;Start of program
                SUB     DX,AX                   ;Length of code in paras
;----------------------------------------------------------------------
; Must say resident before next call so memory image has flag set.
;----------------------------------------------------------------------
                MOV     WORD PTR [_RESIDENT],TRUE ;Indicate residency
;----------------------------------------------------------------------
; If the process is not a swapping TSR, then the call simply goes to the
;   next line.  The return address on the stack is ignored.
; If swapping has been enabled, however, the call will have been patched
;   to invoke the initial swapping setup routine.
;----------------------------------------------------------------------
                CLC
                CALL    ET_2            ;Near call
R$ENDTSR$1  LABEL   BYTE
ET_2:
                JC  ET_3
;----------------------------------------------------------------------
; Go resident and terminate.
;----------------------------------------------------------------------
                MOV     AH,31H                   ;Terminate and stay resident
                MOV     AL,BYTE PTR [P$TermCode] ;Errorlevel for DOS
                INT     21H
;----------------------------------------------------------------------
; A swapping call failed. Cannot go TSR.
;----------------------------------------------------------------------
ET_3:
                MOV     BYTE PTR [P$TermCode],ERR$SWAPFAILURE
                JMP     B$CEND

EndTsr          ENDP

CSEG            ENDS
                END
