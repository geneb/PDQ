; FILE: ENVIRON3.ASM
; ENVIRON statement: Set an environment string.
;       Copyright (c) 1989 Crescent Software
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 8/14/89       .000    Partial.
; 8/15/89       .001    Finds and removes strings.
;               .002    Find env free space.
; 8/17/89       .003    Fix length calculation.
;               .004    Calc free space.
; 8/20/89       .005    Skip string editing per Ethan.
; 8/27/89       .006    Use MATCH_ENV_STR proc. Finish insert string.
; 9/2/89        .007    Tweaking.
;               .008    Remove error if str not found. Document env problem.
; 9/3/89        .009    Split into isolated functions.
; 9/16/89       .010    Add pdqerr.
; 11/7/89       .011    Add code to delete incoming string if it was a temp.
; 11/9/89       .012    Update code for new string routines.
;----------------------------------------------------------------------
PUBLIC  B$SENV          ;ENVIRON "PATH=A:\"

EXTRN           PARSE_ENV_STR:NEAR  ;In R$ENV07.ASM
EXTRN           DEL_ENV_STR:NEAR    ;In R$ENV07.ASM
EXTRN           INS_ENV_STR:NEAR    ;In R$ENV07.ASM

EXTRN           P$FreeTemp:FAR      ;this is in FREETEMP.ASM
EXTRN           P$FixStr:FAR        ;this is in \VBDOS\FIXSTR.ASM
;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
EXTRN   P$PDQERR:WORD               ;In ERRDATA.ASM
DSEG            ENDS
;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
;======================================================================
; B$SENV (PDQ)
;       Copyright (c) 1989 Crescent Software
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Attempts to set a string of the form "var=arg" into the environment.
; 2. If var already exists, deletes it.
; 3. If no room exists for new string, returns out-of-memory error.
; 4. The current program environment will be used unless otherwise set by
;    EnvOption subroutine.
; 5. Var will be capitalized unless otherwise set by EnvOption subroutine.
; 6. If arg is null, string is just deleted.
;
; DIFFERENCES FROM BASIC
; 6. BASIC accepts a space as a seperator between param and arg, PDQ does not.
; 7. If the arg is a semicolon, BASIC will delete the var. PDQ will set
;    var to a semicolon. Use "var=" to delete an entry. This operation is
;    more consistent with COMMAND.COM.
; 8. BASIC will selectivly remove blanks in the passed string, PDQ will not.
;----------------------------------------------------------------------
; Entry: Stack = Descriptor pointer.
; Exit: none
;----------------------------------------------------------------------
B$SENV          PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP
                PUSH    SI                      ;Save used registers
                PUSH    DI
;----------------------------------------------------------------------
; Reset error level. Other procs will set if problem.
;----------------------------------------------------------------------
                MOV     WORD PTR [P$PDQERR],0
;----------------------------------------------------------------------
; Check for valid string (var=arg) and isolate the var.
; Returns DS:SI -> var, len cx
;         DS:DI -> arg, len dx
; Changes CX DX SI DI ES, No temp str activity
;----------------------------------------------------------------------
                Push [BP+06]    ;if a far string literal, make a near copy
                Call P$FixStr   ;
                Mov  [BP+06],AX ;

                MOV     BX,WORD PTR [BP+6]      ;Desc ptr in BX
                CALL    PARSE_ENV_STR
                JC      SENV_ERR
;----------------------------------------------------------------------
; Delete var at DS:SI len CX from environment. Uses temp strings, but
; preserves all registers.
;----------------------------------------------------------------------
                CALL    DEL_ENV_STR
                JC      SENV_ERR
;----------------------------------------------------------------------
; If new arg is null, we're done.
;----------------------------------------------------------------------
                OR      DX,DX                   ;Len of arg
                JZ      SENV_EXIT
;----------------------------------------------------------------------
; Insert the new string into the environment. BX = desc ptr.
; Returns CY if no room.
;----------------------------------------------------------------------
                CALL    INS_ENV_STR     ;Insert the string
                JNC     SENV_EXIT
;----------------------------------------------------------------------
; Errors are set directly by the subprograms.
;----------------------------------------------------------------------
SENV_ERR:
SENV_EXIT:
                PUSH    BX                      ;Incoming string ptr
                CALL    P$FreeTemp              ;Delete if a temp

                POP     DI                      ;Restore registers
                POP     SI
                POP     BP                      ;Erase stack frame
                RET     2                       ;Discard parameter

B$SENV          ENDP

CSEG            ENDS
                END
