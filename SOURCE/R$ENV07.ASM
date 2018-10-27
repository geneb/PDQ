; R$ENV07.ASM
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 9/3/89        .000    Create parse, del.
; 9/14/89       .001    Add GET_ENV_SIZE.
;               .002    Add INS_ENV_STR. Fix DEL_ENV_STR.  Combine DEL_ENTRY.
; 9/15/89       .003    Fix del movsb.
;               .004    Modify INS.
;               .005    Add pdqerr.
; 9/16/89       .005    Fix caps routine.
; 9/25/89       .006    Move extrn definitions.
; 11/9/89       .007    Update for new string functions.
; 1/8/90        .008    Unified include file.
; 2/28/90       .009    Delete temporary string we create
; 3/12/90       .011    Add call to P$DoError to check ON ERROR (EW)
; 4/19/91       .012    Fix INS_ENV_STR
;----------------------------------------------------------------------
PUBLIC  PARSE_ENV_STR
PUBLIC  DEL_ENV_STR
PUBLIC  INS_ENV_STR

EXTRN   MATCH_ENV_STR:NEAR  ;this is in R$ENV06.ASM
EXTRN   B$UCAS:FAR          ;this is in UCASE$.ASM
EXTRN   P$MakeTemp:FAR      ;In MAKETEMP.ASM
EXTRN   P$FreeTemp:FAR      ;In FREETEMP.ASM
EXTRN   P$DoError:FAR       ;In DOERROR.ASM

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'
EXTRN   R$ENVSW:WORD            ;this is in R$ENV05.ASM
EXTRN   P$PDQERR:WORD           ;this is in ERRDATA.ASM
EXTRN   P$DOSVER:WORD           ;this is in PDQDATA.ASM

ENV_STR_INVALID EQU     103
STR_POOL_SHORT  EQU     104
NO_ENV_SPACE    EQU     105

INCLUDE R$PDQ.EQU
DSEG            ENDS
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'
ENVSIZE         DW      1 DUP(?)
EXTRN   R$ENVSEG:WORD           ;these are in R$ENV05.ASM
EXTRN   R$ENVSTRPTR:WORD
EXTRN   R$ENVSTRNXT:WORD
USEG            ENDS
;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; PARSE_ENV_STR (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;---------------------------------------------------------------------- 
; Passed string must be in the form "xx=" or "xx=yy" (var=arg).
; Search for the = delimiter.
;----------------------------------------------------------------------
; Entry:
;       DS = DGROUP
;       BX = offset of desc ptr for string
; Exit:
;       CY - string has invalid format
;
;       NC - string okay
;       SI = offset of var in DS
;       CX = length of var
;       DI = offset of arg in DS
;       DX = length of arg
;----------------------------------------------------------------------
; Changes: CX DX SI DI ES
;----------------------------------------------------------------------
PARSE_ENV_STR   PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    AX                      ;Save used registers
                PUSH    ES

                MOV     CX,WORD PTR [BX][0]     ;Str len in CX

                PUSH    DS                      ;Point ES to DGROUP
                POP     ES
        ASSUME  ES:DGROUP

                MOV     AL,"="                  ;Search for this
                MOV     DI,WORD PTR [BX][2]     ;Offset of original string
                MOV     SI,DI                   ;(Save offset in SI)

                REPNE   SCASB                   ;Scan ES:DI until match AL
                JE      PES_1
;----------------------------------------------------------------------
; String invalid, return error.
;----------------------------------------------------------------------
                MOV     WORD PTR [P$PDQERR],ENV_STR_INVALID
                CALL    P$DOERROR
                STC                             ;Error
PES_EXIT:
                POP     ES                      ;Restore registers
                POP     AX
                RET
;----------------------------------------------------------------------
; DI now points to arg.
;----------------------------------------------------------------------
PES_1:
                MOV     CX,DI                   ;End of var=
                SUB     CX,SI                   ; minus start = varlen + 1
                MOV     DX,WORD PTR [BX][0]     ;Length of entire string
                SUB     DX,CX                   ; yields len of arg
                DEC     CX                      ;Len of var in CX

                CLC                             ;Success
                JMP     PES_EXIT

PARSE_ENV_STR   ENDP

;======================================================================
; DEL_ENV_STR (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Entry:
;       DS:SI = points to var
;       CX = len of var
; Exit:
;       CY - error occured
;       NC - string deleted
;----------------------------------------------------------------------
; Changes: none
;----------------------------------------------------------------------
; 9/14/89       Add register saves.  Fix exit.  Combine DEL_ENTRY.
; 11/9/89       Use P$MAKETEMP.
;----------------------------------------------------------------------
DEL_ENV_STR     PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    AX                      ;Save used registers
                PUSH    BX
                PUSH    CX
                PUSH    SI
                PUSH    DI
                PUSH    ES
;----------------------------------------------------------------------
; Create a temporary string to hold a copy of the var.
;----------------------------------------------------------------------
                MOV     AX,CX                   ;Save requested len
;----------------------------------------------------------------------
; P$MAKETEMP returns
;  BX = eraseable descriptor containing DI,CX
;  DI = offset of start of eraseable string
;  CX = max length of eraseable string
;  ES = DS = DGROUP
;  CLD
;----------------------------------------------------------------------
                CALL    P$MakeTemp
        ASSUME  ES:DGROUP
;----------------------------------------------------------------------
; Not enough string space will cause a failure.
;----------------------------------------------------------------------
                CMP     CX,AX                   ;If not enough space, error
                JNB     DES_1

                MOV     WORD PTR [P$PDQERR],STR_POOL_SHORT
                CALL    P$DOERROR
                JMP     SHORT DES_ERR
;----------------------------------------------------------------------
; Copy the var of the environment string (var=arg) to the temporary string.
; Copy DS:SI->ES:DI.
;----------------------------------------------------------------------
DES_1:
                REP     MOVSB                   ;Transfer var to string
;----------------------------------------------------------------------
; Normally, uppercase the string.  If no-tamper switch on, don't.
;----------------------------------------------------------------------
                MOV     AX,BX                   ;Put desc ptr in AX

                TEST    WORD PTR [R$ENVSW],2    ;If on, don't tamper
                JNZ     DES_2

                PUSH    BX                      ;Pass descriptor
                CALL    B$UCAS                  ;Ret AX = new desc ptr
;----------------------------------------------------------------------
; Locate the var in the environment.
;----------------------------------------------------------------------
DES_2:
                MOV     BX,AX                   ;Desc ptr in BX for addressing
                MOV     CX,WORD PTR [BX][0]     ;Get length
                MOV     SI,WORD PTR [BX][2]     ; and offset
;----------------------------------------------------------------------
; If NC, match found.
; If CY, either string not found or invalid environment requested.
;----------------------------------------------------------------------
                CALL    MATCH_ENV_STR           ;Change ES,CX,SI
        ASSUME  ES:NOTHING
                JNC     DES_3                   ;String found

                CMP     WORD PTR [R$ENVSEG],0   ;non-zero if valid env
                JNE     DES_SUCCESS             ;Env valid, no string
;----------------------------------------------------------------------
; Return with error.
;----------------------------------------------------------------------
DES_ERR:
                STC
                JMP     SHORT DES_EXIT          ;Env invalid
;----------------------------------------------------------------------
; Env was valid.  Env variable was found.  Delete entry specified in
; R$ENVSTR variables.
;----------------------------------------------------------------------
; ES = Environment
; DS:[R$ENVSTRPTR] = offset (ES relative) of string to delete
; DS:[R$ENVSTRLEN] = size of string to delete.
;----------------------------------------------------------------------
DES_3:
                CALL    GET_ENV_SIZE                ;AX,DI,ES
;----------------------------------------------------------------------
; Delete the entry and compress the env table.
;----------------------------------------------------------------------
; R$ENVSEG      =       environment segment
; R$ENVSTRPTR   =       offset of matched entry
; R$ENVSTRLEN   =       length of entire entry
;----------------------------------------------------------------------
                MOV     ES,WORD PTR [R$ENVSEG]      ;Point ES to env seg
        ASSUME  ES:NOTHING

                MOV     DI,WORD PTR [R$ENVSTRPTR]   ;Start of string
                MOV     SI,WORD PTR [R$ENVSTRNXT]   ;Start of next string
;----------------------------------------------------------------------
; Calculate the number of bytes to move.
;----------------------------------------------------------------------
                MOV     CX,WORD PTR [ENVSIZE]
                SUB     CX,SI

                PUSH    DS                      ;Point DS:SI and ES:DI
                PUSH    ES                      ; to environment block
                POP     DS
        ASSUME  DS:NOTHING

                CMP     SI,DI                   ;If nothing to move,skip it
                JE      SENV_3B

                PUSH    DI                      ;Start of string to remove
                REP     MOVSB                   ;Move 'em
                POP     SI                      ; is place to start scan
SENV_3B:
                POP     DS                      ;Restore register
        ASSUME  DS:DGROUP
;----------------------------------------------------------------------
; Routine exit point.
;----------------------------------------------------------------------
        ASSUME  ES:NOTHING
DES_SUCCESS:
                CLC
DES_EXIT:
;----------------------------------------------------------------------
; Delete the temporary string we created or that was returned by UCASE.
;----------------------------------------------------------------------
                PUSH    BX
                CALL    P$FREETEMP

                POP     ES
        ASSUME  ES:NOTHING
                POP     DI
                POP     SI
                POP     CX
                POP     BX
                POP     AX
                RET

DEL_ENV_STR     ENDP

;======================================================================
; INS_ENV_STR (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Insert a string into the environment.
;----------------------------------------------------------------------
; Entry:
;       BX = pointer to string descriptor
;----------------------------------------------------------------------
; Changes: AX CX DX SI DI ES
;----------------------------------------------------------------------

INS_ENV_STR     PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP
;----------------------------------------------------------------------
; First, there must be sufficient room for the new string.
;----------------------------------------------------------------------
                CALL    GET_ENV_SIZE            ;Get size in AX
                                                ; insertion point in DI
                DEC     AX                      ;Allow for ending zero
                CMP     AX,WORD PTR [BX]        ;Room for string?
                JA      IES_1
IES_ERR:
                MOV     WORD PTR [P$PDQERR],NO_ENV_SPACE
                CALL    P$DOERROR
                STC
IES_EXIT:
                RET
;----------------------------------------------------------------------
; Make a hole for the new string by moving the other data forward.
; Move from the end of the environment to the insertion point.
;----------------------------------------------------------------------
IES_1:
                MOV     DX,DI                   ;Save ins pt

                MOV     ES,WORD PTR [R$ENVSEG]  ;Env segment
        ASSUME  ES:NOTHING

                MOV     DI,WORD PTR [ENVSIZE]   ;Total bytes
                DEC     DI                      ;Offset of last byte

                MOV     SI,DI                   ;Last byte
                SUB     SI,WORD PTR [BX]        ; sub length = source
                DEC     SI

                MOV     CX,SI
                SUB     CX,DX
                INC     CX

                PUSH    DS
                MOV     DS,WORD PTR [R$ENVSEG]
        ASSUME  DS:NOTHING

                STD                             ;Move backward
                REP     MOVSB
                CLD

                POP     DS
        ASSUME  DS:DGROUP
                MOV     DI,DX
;----------------------------------------------------------------------
; DI = insertion point in environment.
; If necessary, capitalize the string while inserting.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BX][2]     ;Offset of string
                MOV     CX,WORD PTR [BX]        ;Size of string
IES_2:
                LODSB                           ;AL = DS:[SI++]
                CMP     AL,"="                  ;If equals, copy remainder
                JE      IES_4

                TEST    WORD PTR [R$ENVSW],2    ;If on, don't tamper
                JNZ     IES_3

                CMP     AL,"a"
                JB      IES_3
                CMP     AL,"z"
                JA      IES_3
                AND     AL,(NOT 20H)            ;Make uppercase
IES_3:
                STOSB                           ;ES:[DI++]=AL
                LOOP    IES_2
;----------------------------------------------------------------------
; Add the argument.
;----------------------------------------------------------------------
IES_4:
                DEC     SI
                REP     MOVSB

                XOR     AL,AL
                STOSB

                CLC
                JMP     IES_EXIT

INS_ENV_STR     ENDP

;======================================================================
; GET_ENV_SIZE (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Determines environment size, bytes free, and insertion point.
; 2. Automatically allows for program pathname tail when present.
; 3. If PSP that owns env is known, and it is it's own parent, then
;    DOS 2.x will have no env tail.  Easier to count.
;----------------------------------------------------------------------
; Entry:
;       [R$ENVSEG] is assumed valid
; Exit:
;       AX = bytes free in environment for new strings
;       DI = insertion point for new string in environment
;----------------------------------------------------------------------
; Changes: AX DI ES
;----------------------------------------------------------------------
GET_ENV_SIZE    PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BX
                PUSH    CX
                PUSH    SI
;----------------------------------------------------------------------
; Find the size of the environment block.
; Note: Can be up to 32K bytes if set by the config.sys shell command.
;----------------------------------------------------------------------
                MOV     AX,WORD PTR [R$ENVSEG]  ;Env segment
                DEC     AX                      ;Point to MCB
                MOV     ES,AX                   ;Address in ES
        ASSUME  ES:NOTHING

                MOV     AX,WORD PTR ES:[3]      ;Length of block in paras
                MOV     CL,4                    ; * 16
                SHL     AX,CL                   ;Convert to bytes
                MOV     WORD PTR [ENVSIZE],AX   ;Save the size
;----------------------------------------------------------------------
; Find end of environment table as indicated by null entry.  Scan table
; two bytes at a time, but overlap the scan.
;----------------------------------------------------------------------
                MOV     ES,WORD PTR [R$ENVSEG]
        ASSUME  ES:NOTHING
                XOR     SI,SI                   ;Scan from start of table

                MOV     CX,AX                   ;Scan this many words
                DEC     CX                      ;Less the last one
GES_1:
                CMP     WORD PTR ES:[SI],0      ;If zero word, end of table
                JE      GES_2

                INC     SI                      ;Move one byte
                LOOP    GES_1
;----------------------------------------------------------------------
; Found end of table.  Point SI past zero word.
;----------------------------------------------------------------------
GES_2:
                INC     SI                      ;Point past string 0
                MOV     DI,SI                   ;Insertion point
                INC     SI                      ;Move past null entry
;----------------------------------------------------------------------
; Calculate number of bytes that are not in main table.
;----------------------------------------------------------------------
                SUB     AX,DI                   ;Non-table bytes
;----------------------------------------------------------------------
; If this environment doesn't have a pathname tail, return the above values.
;----------------------------------------------------------------------
                CMP     BYTE PTR [P$DOSVER],3
                JA      GES_3
GES_EXIT:
                POP     SI
                POP     CX
                POP     BX
                RET
;----------------------------------------------------------------------
; Environment COULD have a pathname tail, but doesn't necessarily.
; If it does, SI points to a word that tells how many entries.
; For a quick check, can't have more entries than 1/2 bytes remaining.
;----------------------------------------------------------------------
GES_3:
                MOV     CX,AX                   ;"free" bytes
                INC     CX                      ;round up
                SHR     CX,1                    ;Divide by 2
                CMP     CX,WORD PTR ES:[SI]     ;Can't be less than words
                JB      GES_EXIT
;----------------------------------------------------------------------
; Verify that the correct number of entries exist.
;----------------------------------------------------------------------
                MOV     CX,WORD PTR [ENVSIZE]   ;Change size to 0-base
                DEC     CX                      ; for maximum SI

                MOV     BX,WORD PTR ES:[SI]     ;Number strings to find
;----------------------------------------------------------------------
; Count off the strings.
;----------------------------------------------------------------------
                INC     SI                      ;Skip half of word then...
GES_4:
                INC     SI                      ;...Advance pointer
                CMP     SI,CX                   ;If > CX, out of env
                JA      GES_EXIT

                CMP     BYTE PTR ES:[SI],0      ;End of string?
                JNE     GES_4

                DEC     BX                      ;Found string
                JNZ     GES_4
;----------------------------------------------------------------------
; If here, found the specified number of strings without running out of
; environment space, so assume the tail strings are valid.
;----------------------------------------------------------------------
                MOV     AX,CX
                SUB     AX,SI
                JMP     GES_EXIT

GET_ENV_SIZE    ENDP

CSEG            ENDS
                END
