; FILE: ENVIRON2.ASM
; String implementation of the ENVIRON$ function.
;       Copyright (c) 1989 Cresceftware
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 8/13/89       .000    Initial.
; 8/14/89       .001    Use envdes as temp storage.
; 8/27/89       .002    Use MATCH_ENV_STR routine
; 9/16/89       .003    Add pdqerr.
; 9/25/89       .004    Fix seg declaration.
; 11/7/89       .005    Add code to delete incoming string if it was a temp.
; 11/9/89       .006    Shift code, update for P$FREETEMP
; 12/4/89       .007    Optimize.
;----------------------------------------------------------------------
PUBLIC  B$FEVS                  ;A$=ENVIRON$("PATH")

EXTRN   MATCH_ENV_STR:NEAR      ;In R$ENV06.ASM

EXTRN   P$MakeTemp:FAR          ;In MAKETEMP.ASM
EXTRN   P$FreeTemp:FAR          ;In FREETEMP.ASM
EXTRN   P$FixStr:FAR            ;In \VBDOS\FIXSTR.ASM
;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
EXTRN   P$PDQERR:WORD           ;this is in ERRDATA.ASM
DSEG            ENDS
;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
;======================================================================
; B$FEVS (PDQ)
;       Copyright (c) 1989 Crescent Software
;       Copyright (c) 1989 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Entry: Stack = pointer to string descriptor of env entry to match.
; 2. Exit: Returns string descriptor of matched string.
;----------------------------------------------------------------------
; DIFFERENCES FROM BASIC
; 3. BASIC returns an "Illegal function call" if the string argument has any
;    blanks in it.  This makes it impossible to retrieve the otherwise legal
;    environment variable "X ".  PDQ does not trim or check for blanks in
;    the string.
;----------------------------------------------------------------------
B$FEVS          PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP
                PUSH    SI                      ;Save used registers
                PUSH    DI
;----------------------------------------------------------------------
; Reset error to normal. Routines set error directly.
;----------------------------------------------------------------------
                MOV     WORD PTR [P$PDQERR],0
;----------------------------------------------------------------------
; Point DS:SI to the string to match. CX contains the length.
;----------------------------------------------------------------------
                Push [BP+06]    ;if a far string literal, make a near copy
                Call P$FixStr   ;
                Mov  [BP+06],AX ;

                MOV     SI,WORD PTR [BP+6]      ;ptr to str desc
                MOV     CX,WORD PTR [SI][0]     ;Length
                MOV     SI,WORD PTR [SI][2]     ;Offset

                CALL    MATCH_ENV_STR           ;NC if match
        ASSUME  ES:NOTHING
                JNC      FEVS_1
;----------------------------------------------------------------------
; String wasn't found. Return a null descriptor.
;----------------------------------------------------------------------
FEVS_0:
                XOR     CX,CX           ;Ask for zero bytes
                CALL    P$MakeTemp      ;Make the string
                JMP     SHORT FEVS_EXIT
;----------------------------------------------------------------------
; Copy the environment string to a PDQ string variable and return it.
;----------------------------------------------------------------------
FEVS_1:
                PUSH    DS          ;Save DGROUP
                PUSH    ES                      ;Save env segment
;----------------------------------------------------------------------
; P$MAKETEMP returns
;  BX = eraseable descriptor containing DI,CX
;  DI = offset of start of eraseable string
;  CX = max length of eraseable string
;  ES = DS = DGROUP
;  CLD
;----------------------------------------------------------------------
                CALL P$MakeTemp                 ;Ethan's routine
;----------------------------------------------------------------------
; Copy string from the environment (DS:SI) to the string pool (ES:DI)
;----------------------------------------------------------------------
                POP     DS                      ;Point DS to env
        ASSUME  DS:NOTHING
                REP     MOVSB                   ;Move CX bytes DS:SI->ES:DI

                POP     DS          ;Point DS to DGROUP
        ASSUME  DS:DGROUP
FEVS_EXIT:
                MOV     AX,BX                   ;Return desc ptr in AX

                PUSH    WORD PTR [BP+6]         ;Delete if temp string
                CALL    P$FreeTemp

                POP     DI                      ;Restore registers
                POP     SI
                POP     BP                      ;Erase stack frame
                RET     2                       ;Discard 1 param

B$FEVS          ENDP

CSEG            ENDS
                END
