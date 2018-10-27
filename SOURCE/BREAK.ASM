; BREAK.ASM
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
;  BreakOff PDQ:FAR
;  BreakOn  PDQ:FAR
;  BreakHit PDQ:FAR
;  Break9   Local:FAR
;  Break1B  Local:FAR
;----------------------------------------------------------------------
; GENERAL NOTES:
;
; 1. The Ctrl-Break key combination is detected by the BIOS and an INT
;    1Bh is generated.  Normally, DOS points this routine to itself and
;    converts it to an INT 23h.
; 2. This routine hooks INT 1Bh directly and either passes it to the
;    default routine or cancels it.  But rather than intercept 23h, which
;    leaves a ^C on the screen, it grabs INT 9 and heads off the Ctrl-C
;    combination.
; 4. If the BreakOff routine is used, the BreakOn routine MUST be called
;    before the program terminates or the PC will crash.  This is because
;    the break routine will be left pointing to the PDQ handler even after
;    the code has been overwritten by the next program.
; 5. These routines may be called from within a TSR program.  Comment 4
;    also applies to TSRs.
;----------------------------------------------------------------------
; 7/4/89        .000    Original
; 7/10/89       .001    Modify self-patch.
; 7/23/89       .002    Add 1Bh, TSR support. Remove self-patch.
; 9/9/89        .003    Preserve flags for subsequent INTs.
; 10/21/89      .004    Fix breaker routine.
; 12/27/89      .005    Per request, replace int 23 with int 9.
; 1/8/90        .006    Unified include file.
; 7/19/90       .007    Make safe for multiple on/off calls
;----------------------------------------------------------------------
PUBLIC  BreakOff        ;Subroutine
PUBLIC  BreakOn         ;Subroutine
PUBLIC  BreakHit        ;Function

EXTRN   RESETKEYBOARD:FAR
;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU
DSEG            ENDS

;----------------------------------------------------------------------
; Code begins.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

BREAKCOUNT      DW      0                       ;Count the number of breaks
USE_ORIG_BREAK  DW      TRUE                    ;Break works if TRUE
pINT9           DD      0                       ;Store old vector here
pINT1B          DD      0                       ;Store old vector here

;======================================================================
; BreakOff (PDQ)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Turns off the effect of the CTRL-Break and CTRL-C key combinations.
; 2. Reset the BreakHit count to 0.
;----------------------------------------------------------------------
; Usage:
;       CALL BreakOff
;----------------------------------------------------------------------
; Changes AX BX ES
;----------------------------------------------------------------------
BreakOff        PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
; Can only turn Break off if Break is on.
;----------------------------------------------------------------------
                CMP     WORD PTR CS:[USE_ORIG_BREAK],TRUE
                JNE     BOFF_EXIT
;----------------------------------------------------------------------
; Get and save the original Int 9 and Int 1B vectors.
;----------------------------------------------------------------------
                PUSH    DS

                XOR     AX,AX                       ;Point to low memory
                MOV     ES,AX
        ASSUME  ES:NOTHING

                LDS     AX,DWORD PTR ES:[9*4]
        ASSUME  DS:NOTHING
                MOV     WORD PTR CS:[pINT9][0],AX   ;Offset
                MOV     WORD PTR CS:[pINT9][2],DS   ;Segment

                LDS     AX,DWORD PTR ES:[1BH*4]
        ASSUME  DS:NOTHING
                MOV     WORD PTR CS:[pINT1B][0],AX  ;Offset
                MOV     WORD PTR CS:[pINT1B][2],DS  ;Segment

;----------------------------------------------------------------------
; Point the interrupt to our handler.  Segment (is CSEG) in DS, offset
;  (relative to CSEG) in DX.
;----------------------------------------------------------------------
                MOV     AX,OFFSET CS:BREAK1B    ;New service routine
                MOV     CX,OFFSET CS:BREAK9     ;New service routine
                MOV     BX,CS

                CLI
                MOV     WORD PTR ES:[1BH*4][0],AX   ;Offset
                MOV     WORD PTR ES:[1BH*4][2],BX   ;Segment

                MOV     WORD PTR ES:[9*4][0],CX     ;Offset
                MOV     WORD PTR ES:[9*4][2],BX     ;Segment

                NOT     WORD PTR CS:[USE_ORIG_BREAK]    ;Break action off
                MOV     WORD PTR CS:[BREAKCOUNT],0      ;Reset hit count

                STI
                POP     DS

BOFF_EXIT:
                RET                                         ;Return to BASIC

BreakOff        ENDP

;======================================================================
; BreakOn (PDQ)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Turns on the CTRL-Break and CTRL-C key combinations.
;----------------------------------------------------------------------
; Usage:
;       CALL BreakOn
;----------------------------------------------------------------------
; Changes AX BX CX DX ES
;----------------------------------------------------------------------
BreakOn         PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
; Can only turn Break on if Break is off.
;----------------------------------------------------------------------
                CMP     WORD PTR CS:[USE_ORIG_BREAK],FALSE
                JNE     BON_EXIT
;----------------------------------------------------------------------
; Restore the original interrupt vectors in low memory.
;----------------------------------------------------------------------
                PUSH    DS

                NOT     WORD PTR CS:[USE_ORIG_BREAK] ;Break action on

                XOR     AX,AX                        ;Point to low memory
                MOV     ES,AX
        ASSUME  ES:NOTHING

                LDS     AX,DWORD PTR CS:[pINT9]
                MOV     BX,DS

                LDS     CX,DWORD PTR CS:[pINT1B]

                CLI

                MOV     WORD PTR ES:[9*4][0],AX       ;Offset
                MOV     WORD PTR ES:[9*4][2],BX       ;Segment

                MOV     WORD PTR ES:[1BH*4][0],CX     ;Offset
                MOV     WORD PTR ES:[1BH*4][2],DS     ;Segment

                STI
                POP     DS

BON_EXIT:
                RET                                     ;Return to BASIC

BreakOn         ENDP

;======================================================================
; BreakHit (PDQ)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Returns the number of times BREAK was generated since the last call
;    to either BreakOff or BreakHit.
; 2. Resets BreakHit count to 0.
;----------------------------------------------------------------------
; Usage:
;       DECLARE FUNCTION BreakHit%
;       NumberHits% = BreakHit%
;----------------------------------------------------------------------
; 7/4/89        Initial.
;----------------------------------------------------------------------
; Changes AX
;----------------------------------------------------------------------
BreakHit        PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                XOR     AX,AX
                XCHG    AX,WORD PTR CS:[BREAKCOUNT]     ;Break
                RET

BreakHit        ENDP

;======================================================================
; BREAKXX (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. An internal routine that receives control when Ctrl-Break is pressed.
; 2. If Break is enabled (Break On), the keystroke is passed on to the
;    original handler.
; 3. If Break is off, the keystroke is counted, then ignored.
;----------------------------------------------------------------------
; 7/4/89        Initial.
; 9/9/89        Preserve flags for subsequent ints.
; 10/21/89      Fix pass-along for two ints.
;----------------------------------------------------------------------
; Changes: None
;----------------------------------------------------------------------
BREAK9          PROC    FAR
        ASSUME  CS:CSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

;----------------------------------------------------------------------
; It's more likely that the key is not Ctrl-C than that it is, but break
;  is off.
;----------------------------------------------------------------------
                PUSHF
                PUSH    AX
                PUSH    ES

                XOR     AX,AX
                MOV     ES,AX                   ;Point to low memory
        ASSUME  ES:NOTHING

                TEST    BYTE PTR ES:[417H],4    ;Is Ctrl pressed?
                JZ      BREAK9_1                ;Zero if no

                IN      AL,60H                  ;Get scan code

                CMP     AL,2EH                  ;Is it "C" ?
                JNE     BREAK9_1
;----------------------------------------------------------------------
; Ctrl-C was pressed. Kill if break is off, otherwise, let it pass.
;----------------------------------------------------------------------
                CMP     WORD PTR CS:[USE_ORIG_BREAK],TRUE
                JE      BREAK9_1
;----------------------------------------------------------------------
; Ignore the keystroke by reseting the interrupt controller.
;----------------------------------------------------------------------
                CALL    RESETKEYBOARD
                INC     WORD PTR CS:[BREAKCOUNT]

                POP     ES
                POP     AX
                POPF
                IRET
;----------------------------------------------------------------------
; Wasn't Ctrl-C, so pass on to the original handler.
;----------------------------------------------------------------------
BREAK9_1:
                POP     ES
                POP     AX
                POPF
                JMP     DWORD PTR CS:[pINT9]

BREAK9          ENDP

;======================================================================
;
;----------------------------------------------------------------------
BREAK1B         PROC    FAR
        ASSUME  CS:CSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                PUSHF

                CMP     WORD PTR CS:[USE_ORIG_BREAK],FALSE
                JE      BREAK1B_1

                POPF
                JMP     DWORD PTR CS:[pINT1B]
BREAK1B_1:
                INC     WORD PTR CS:[BREAKCOUNT]

                POPF
                IRET

BREAK1B         ENDP

CSEG            ENDS
                END
