;======================================================================
; TSRINST.ASM
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Comments from self-appointed experts not-withstanding, this is a
;    tried and true method of locating TSRs and is preferred over the
;    "tack my function to an interrupt" method.
; 2. As long as the memory is hooked into the memory control block
;    chain, this routine will find it.
;----------------------------------------------------------------------
; 7/22/89   Initial. Adapt from INSTALL_CHECK.
; 7/29/89   Remove string length check.  Make work within TSR.
;           .000    Split into file TSR1.
; 7/30/89   .001    Change res flag name.
; 8/13/89   .002    Modify use of _RESIDENT flag.
; 9/9/89    .003    Update doc.
; 9/10/89   .004    Move extrn to segs.  Use MCB function.
; 1/8/90    .005    Unified include file.
; 9/18/91   .006    Preserve ES for internal calls.
; 9/20/91   .007    Modify to use RLHSEG.
; 9/21/91   .008    New search method.
; 10/10/91  .009    Fix externals.
;----------------------------------------------------------------------
PUBLIC  TsrInstalled

;======================================================================
; Externals.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

EXTRN   FIND_FIRST_MCB:NEAR
EXTRN   FIND_NEXT_MCB:NEAR

CSEG        ENDS

;======================================================================
;
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EXTRN   R$ID:BYTE           ;these are in R$TSRDAT.ASM
EXTRN   R$DGROUP:WORD

RLHSEG      ENDS

;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU
EXTRN   _RESIDENT:WORD
EXTRN   P$PSPSEG:WORD

DSEG            ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; TsrInstalled (PDQ)
; Routine to find previous resident copy of a PDQ TSR.
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Scan the memory blocks sequentially (from low to high) and find
;    an occurance of the altered ID string.
; 2. If the only match found is in the current copy (as determined by
;    DGROUP), return a 0.
;----------------------------------------------------------------------
; Usage:
;       RESULT% = TsrInstalled%(ID$)
; where
;       ID$ = unique ID string that is > 7 chars. No longer restricted
;             to first string in the program. May move around. Not changed
;             in place.
;       RESULT% = 0000 - Distinct copy of program not found in memory
;                 xxxx - DGROUP segment of other resident copy.
;----------------------------------------------------------------------
TsrInstalled    PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                PUSH    SI                      ;Save used registers
                PUSH    DI
                PUSH    ES
;----------------------------------------------------------------------
; Determine the offset of RLHSEG with respect to the program's PSP.
; Both segments are paragraph aligned, so the subtraction is exact.
;----------------------------------------------------------------------
                MOV     DI,RLHSEG
                SUB     DI,P$PSPSEG             ;Paragraph seperation
                INC     DI                      ;Account for MCB header
                MOV     CL,4
                SHL     DI,CL                   ;Convert to bytes
                ADD     DI,OFFSET RLHSEG:R$ID   ;Final offset
;----------------------------------------------------------------------
; The passed ID string is used to find the resident one. It must be
; altered to do so.
;----------------------------------------------------------------------
                MOV     BX,WORD PTR [BP+6]      ;Get pointer to str desc
                MOV     SI,WORD PTR [BX+2]      ;Offset of string
                NOT     WORD PTR [SI]           ;Match the RLHSEG version

                MOV     CX,WORD PTR [BX]        ;Length of string
                CMP     CX,16
                JLE     IC_1

                MOV     CX,16                   ;Compare 16 chars max
IC_1:
;----------------------------------------------------------------------
; 1. Find a MCB.
; 2. Compare up to 16 chars of the ID string to the area of memory where
;    the RLHSEG version would be.
; 3. If match found, return DGROUP of that copy.
; 4. If match not found (or this version is resident), return 0.
;
; DS:SI -> DGROUP:[ID$]
; ES:DI -> RLHSEG:[R$ID]
;----------------------------------------------------------------------
                CALL    FIND_FIRST_MCB          ;Return MCB header in AX
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
IC_2:
                MOV ES,AX           ;Point ES to block
        ASSUME  ES:NOTHING

                PUSH    SI
                PUSH    DI
                PUSH    CX

                REPE    CMPSB           ;See if strings match

                POP     CX
                POP     DI
                POP     SI

                JNE     IC_3
;----------------------------------------------------------------------
; Match was found. If the match is THIS copy, ignore it.
;----------------------------------------------------------------------
                INC     AX          ;Convert to PSP seg
                CMP     AX,P$PSPSEG
                JE      IC_3
;----------------------------------------------------------------------
; Not this copy. Get the resident DGROUP and return it.
;----------------------------------------------------------------------
                SUB     DI,OFFSET RLHSEG:R$ID
                ADD     DI,OFFSET RLHSEG:R$DGROUP
                MOV     AX,WORD PTR ES:[DI]

                JMP     SHORT IC_EXIT
;----------------------------------------------------------------------
; No valid match. Check the next segment.
;----------------------------------------------------------------------
IC_3:
                CALL    FIND_NEXT_MCB
                JNC     IC_2

                SUB     AX,AX           ;Return 0
;----------------------------------------------------------------------
; Repair the string and exit.
;----------------------------------------------------------------------
IC_EXIT:
                NOT     WORD PTR [SI]

                POP     ES
                POP     DI                      ;Restore registers
                POP     SI
                POP     BP                      ;Erase stack frame
                RET     2                       ;Discard 1 arg

TsrInstalled    ENDP

CSEG            ENDS
                END
