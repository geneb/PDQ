; R$ENV05.ASM - Environment handling support routines and data.
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 8/14/89       .000    Initial.
; 8/15/89       .001    Save start of current string as well as next.
; 8/27/89       .002    Add GET_ENV_SEG test for ownership.
; 9/3/89        .003    Return ES=0 when invalid env.
; 9/10/89       .004    Update doc.
; 9/14/89       .005    Check for no parent case.
; 9/16/89       .006    Add pdqerr.
; 9/25/89       .007    Move extrns.
; 11/9/89       .008    Update comments. Remove DD ENVDES.
; 12/12/89      .009    Fix jump. Add parent handling options.
; 1/8/90        .010    Unified include file.
; 3/12/90       .011    Add call to P$DoError to check ON ERROR (EW)
; 4/8/90        .012    Fix location of parent environment.
; 8/5/90        .013    Modify to exclude bad current _RESIDENT environment
;----------------------------------------------------------------------
PUBLIC  GET_ENV_SEG     ;Proc, near
PUBLIC  GET_ENV_STR     ;Proc, near

PUBLIC  R$ENVSEG        ;Word, environment segment being used
PUBLIC  R$ENVSTRPTR     ;Word, offset (ES) of last string returned
PUBLIC  R$ENVSTRLEN     ;Word, length of last string returned
PUBLIC  R$ENVSTRNXT     ;Word, offset (ES) of next string to return
PUBLIC  R$ENVSW         ;Word, holds option bits for environment work

EXTRN P$DOERROR:FAR     ;this is in DOERROR.ASM

;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

    EXTRN   P$DosVer:Word           ;in PDQDATA.ASM
    EXTRN   P$PDQERR:WORD           ;in ERRDATA.ASM
    EXTRN   _RESIDENT:WORD          ;in PDQDATA.ASM
    EXTRN   P$PSPSeg:WORD           ;in PDQDATA.ASM

    ENV_NOT_FOUND   EQU     102     ;Error return code

    R$ENVSW         DW      0       ;Set by EnvOption routine

DSEG            ENDS
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'

    R$ENVSEG        DW      1 DUP(?)
    R$ENVSTRPTR     DW      1 DUP(?)
    R$ENVSTRLEN     DW      1 DUP(?)
    R$ENVSTRNXT     DW      1 DUP(?)

USEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG
;======================================================================
; GET_ENV_SEG (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;       switch = bit 0, return environment belonging to parent
;                bit 1, options relative to active process
; Exit:
;       CY - failure, all info invalid
;            ES = 0
;       NC - registers set as follows:
;            ES = environment segment requested
;            DW [R$ENVSEG] = environment segment requested
;            DW [R$ENVSTRNXT] = 0
;----------------------------------------------------------------------
; 1. To change the current env for yourself or a subsequent child, use 0.
; 2. To change the env of the program that spawned you (eg, DOS) use 1.
; 3. A TSR program should use the 2-bit option.  Option = 2 returns env of
;     the program that was active when you popped up.  3 returns env of
;     the parent of the active program.
; 4. The environment segment is checked to verify that it is still owned
;     by the PSP segment referencing it.  If not, failure.
;----------------------------------------------------------------------
; COMMAND Quirks:
;
; COMMAND does not provide a valid pointer for its parent; instead, it
;  lists its own PSP at PSP:16.  In most cases, this is okay, as you do
;  not want to back up beyond a copy of COMMAND.
;----------------------------------------------------------------------
; DOS Environment Quirks:
;
; 2.0 - 3.2 The pointer to the environment in the first copy of
;           COMMAND is set to 0.
; 3.3       The pointer to the environment in the first copy of
;           COMMAND is correct.
; 2.0 - 3.1 The pointer to the environment in a secondary copy of
;           COMMAND points to a minimized copy of the environment
;           of the parent.
; 3.2       The pointer to the environment in a secondary copy of
;           COMMAND points to a minimized copy of the environment
;           of the parent that is not used.  Instead, COMMAND creates
;           a full-size environment at the segment DW PSP:[C05].
; 3.3       The pointer to the environment in a secondary copy of
;           COMMAND points to a full-size environment.  The minimized
;           copy is still created, but not used.
;----------------------------------------------------------------------
; Changes ES
;----------------------------------------------------------------------
GET_ENV_SEG     PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    AX                      ;Save used registers
                PUSH    BX

;----------------------------------------------------------------------
; First, assume the PSP segment stored in the currently executing code
; is correct.
;----------------------------------------------------------------------
                MOV     ES,WORD PTR [P$PSPseg]  ;Assume this code's PSP

;----------------------------------------------------------------------
; If the resident option is on AND the current program is not resident,
;  ignore it.  Otherwise, use the PSP that was active when we got control.
;----------------------------------------------------------------------
                TEST    WORD PTR [R$ENVSW],2    ;Adjust for active process?
                JZ      GEP_1                   ; no

                CMP     WORD PTR [_RESIDENT],0  ;If 0, this copy not resident
                JE      GEP_1                   ; don't adjust
;----------------------------------------------------------------------
; Use the PSP that was resident when we got control, if valid.
;----------------------------------------------------------------------
                MOV     AX,WORD PTR [_RESIDENT] ;Use resident PSP seg
                CMP     AX,-1
                JE      GEP_ERR
                MOV     ES,AX
        ASSUME  ES:NOTHING

;----------------------------------------------------------------------
; Determine whether to use this env or the env of its parent.
;----------------------------------------------------------------------
GEP_1:
                TEST    WORD PTR [R$ENVSW],1    ;Bit on = use parent
                JZ      GEP_2                   ;Use this one

                MOV     AX,WORD PTR ES:[016H]   ;Get seg of parent PSP
                OR      AX,AX                   ;If no parent, error
                JNZ     GEP_1B
GEP_ERR:
                MOV     WORD PTR [P$PDQERR],ENV_NOT_FOUND
                CALL    P$DOERROR               ;check if ON ERROR is active
                XOR     BX,BX                   ;Set env to 0
                STC                             ;Indicate failure
                JMP     SHORT GEP_4
GEP_1B:
                MOV     ES,AX                   ;Point to parent PSP
        ASSUME  ES:NOTHING
;----------------------------------------------------------------------
; ES now contains the PSP that owns the environment we want to modify.
; Find the environment segment.
;----------------------------------------------------------------------
GEP_2:
                MOV     AX,ES                   ;Save PSP in AX
                PUSH    AX
                MOV     BX,2CH

                CMP     AX,WORD PTR ES:[16H]    ;PSP its own
                JNE     GEP_2A
;----------------------------------------------------------------------
; The PSP owned itself, ie, is COMMAND, and does not list it's
; environment. Use internal pointers to find environment where needed.
;----------------------------------------------------------------------
                MOV     AX,WORD PTR [P$DOSVER]
                XCHG    AH,AL

                CMP     AX,031EH                ;DOS 3.3 (3h.1Eh) or later
                JAE     GEP_2A

                MOV     BX,0B1CH
                CMP     AH,03H                  ;Prior to DOS 2.x
                JB      GEP_2A

                MOV     BX,0B69H
                CMP     AL,0AH                  ;Test for DOS 3.10 (3h.Ah)
                JB      GEP_2A                  ; DOS 3.0 is below

                MOV     BX,0BD3H                ;DOS 3.1
                JE      GEP_2A                  ; is equal

                MOV     BX,0C05H                ;DOS 3.2 is all that's left
GEP_2A:
                MOV     BX,WORD PTR ES:[BX]     ;Seg of Env
;----------------------------------------------------------------------
; If the block or ownership of the block is not valid, return CY.
;----------------------------------------------------------------------
                POP     AX

                DEC     BX                      ;MCB for env
                MOV     ES,BX                   ;Point ES to MCB
                CMP     WORD PTR ES:[1],AX      ;Owned okay?
                JNE     GEP_ERR
;----------------------------------------------------------------------
; Ownership okay.
;----------------------------------------------------------------------
        ASSUME  ES:NOTHING
GEP_3:
                INC     BX                      ;Point BX to env seg
                CLC                             ;Success
GEP_4:
                MOV     ES,BX                   ;Point ES to env seg
                MOV     WORD PTR [R$ENVSEG],BX  ;Save env seg
                MOV     WORD PTR [R$ENVSTRNXT],0;Initialize pointer

                POP     BX                      ;Restore registers
                POP     AX
                RET

GET_ENV_SEG     ENDP

;======================================================================
; GET_ENV_STR (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;       Assumes R$ENVSEG and R$ENVSTRPTR have been set by GET_ENV_SEG or
;       previous call to GET_ENV_STR.
; Exit:
;       CY = failure, no more entries found env table
;       NC = success, other registers as follows
;        ES:DI -> environment string "XX=yy"
;        CX = length of entire string, excluding terminating 0
;        DW [R$ENVSTRPTR] = Offset (ES relative) of current string
;        DW [R$ENVSTRLEN] = Length of current string
;        DW [R$ENVSTRNXT] = Offset (ES relative) of next string
;                         = [R$ENVSTRPTR] + [R$ENVSTRLEN] + 1
;----------------------------------------------------------------------
; Changes: CX DI ES
;----------------------------------------------------------------------
GET_ENV_STR     PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BX                      ;Save used register

                MOV     ES,WORD PTR [R$ENVSEG]  ;Point to environment
        ASSUME  ES:NOTHING

                MOV     DI,WORD PTR [R$ENVSTRNXT] ;Start of next string
                MOV     WORD PTR [R$ENVSTRPTR],DI ;Becomes start of current

                XOR     BX,BX                   ;Init length = 0
                XOR     CH,CH                   ;Use all of CX
;----------------------------------------------------------------------
; Search through the current string to determine the length.
;----------------------------------------------------------------------
GES_1:
                MOV     CL,BYTE PTR ES:[DI]     ;Load char into CL
                INC     DI                      ;Move pointer manually
                JCXZ    GES_2                   ;Zero byte found?

                INC     BX                      ;Increment length
                JMP     GES_1                   ;Scan next char
;----------------------------------------------------------------------
; End of entry as indicated by 0 byte.  0 length means no more entries.
;----------------------------------------------------------------------
GES_2:
                OR      BX,BX                   ;Check entry length
                JNZ     GES_3

                STC                             ;No entry found
GES_EXIT:
                POP     BX                      ;Restore used register
                RET
;----------------------------------------------------------------------
; Entry valid.
;----------------------------------------------------------------------
GES_3:
                XCHG    WORD PTR [R$ENVSTRNXT],DI ;Point to next string
                MOV     WORD PTR [R$ENVSTRLEN],BX ;Save length of current
                MOV     CX,BX                   ;Return in CX
                CLC                             ;Signal entry was found
                JMP     GES_EXIT

GET_ENV_STR     ENDP

CSEG            ENDS
                END
