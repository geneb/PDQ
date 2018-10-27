; SHELL.ASM
;  B$SSHL PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/4/89        .000    Initial.
; 7/8/89        .001    SHELL Argument checking.
;               .002    Add /c switch. Fix FCB size.
;               .003    Expand cmdtail area. Add parsing.
; 7/17/89       .004    Change to unitialized data. Save context for 2.x.
;                       Return error to PDQ.
; 9/9/89        .005    Update doc. Use err code 101.
; 9/25/89       .006    Move extrns.
; 1/8/90        .007    Unified include file.
; 3/6/90        .008    Add call to P$FreeTemp to erase arg if needed (EW)
; 3/13/90       .009    Add P$DoError
; 11/3/92       .010    Add far string support (Thomas G. Hanlin III)
;----------------------------------------------------------------------
PUBLIC  B$SSHL
EXTRN   P$FixStr:FAR    ;this is in FIXSTR.ASM
EXTRN   P$DOERROR:FAR   ;this is in DOERROR.ASM
EXTRN   P$FREETEMP:FAR  ;this is in FREETEMP.ASM

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG, USEG

DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE \PDQ\SOURCE\R$PDQ.EQU

EXTRN   P$PDQERR:WORD   ;this is in ERRDATA.ASM
EXTRN   P$PSPSEG:WORD   ;this is in PDQ.ASM

COMSPEC         DB      "COMSPEC="

EPB             LABEL   BYTE
 pENV           DW      0                       ;Environment segment
 pCMDTAIL       DW      0                       ;Far pointer to command tail
                DW      DGROUP
 pFCB1          DW      0 ;OFFSET DGROUP:FCB1   ;Far pointer to first FCB
                DW      DGROUP
 pFCB2          DW      0 ;OFFSET DGROUP:FCB2   ;Far pointer to second FCB
                DW      DGROUP

DSEG            ENDS

USEG            SEGMENT WORD    PUBLIC  'BSS'

FCB1            DB      37 DUP(?)
FCB2            DB      37 DUP(?)
PROGSPEC        DB      384 DUP(?)

INIT_LEN        EQU     37+37+384

USEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

COMPSEC_NOT_FOUND       EQU     101

SSSAVE                  DW      0
SPSAVE                  DW      0

;======================================================================
; B$SSHL (PDQ)
; Shell routine for PDQ.
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. The COMSPEC could be as long as 127 bytes long.
; 2. The command tail could also be 127 bytes long.
; 3. Although the DOS command line is limited to 127 bytes, an EXEC'd
;    command line can be 255 bytes long. -rlh
; 4. Uses the DOS EXEC function.
; 5. The environment of the PDQ parent is duplicated for the child.
;----------------------------------------------------------------------
;       SHELL   ["command tail"]
;----------------------------------------------------------------------
B$SSHL          PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                PUSH    SI
                PUSH    DI
;----------------------------------------------------------------------
; Preparatory work.
;----------------------------------------------------------------------
                PUSH    [BP+6]      ;Ptr to string ptr
                CALL    P$FixStr    ;convert to near string if far literal
                MOV     [BP+6],AX   ;stuff back on stack

                CLD                             ;String moves forward

                PUSH    DS
                POP     ES
        ASSUME  ES:DGROUP

                XOR     AX,AX                   ;Zero
                MOV     WORD PTR [P$PDQErr],AX  ;In error word
                MOV     WORD PTR [pENV],AX      ; and env ptr

                MOV     DI,OFFSET DGROUP:FCB1   ;Start of data block
                MOV     CX,INIT_LEN             ;Number of bytes
                REP     STOSB                   ;Fill with zeros

                MOV     AL,20H                  ;Space char
                MOV     DI,OFFSET DGROUP:FCB1   ;Address of FCB1
                MOV     WORD PTR [pFCB1],DI     ; save ptr
                INC     DI                      ;Advance byte
                MOV     CX,11                   ;Write 11 spaces
                REP     STOSB
                MOV     DI,OFFSET DGROUP:FCB2   ;Ditto for FCB2
                MOV     WORD PTR [pFCB2],DI
                INC     DI
                MOV     CX,11
                REP     STOSB
;----------------------------------------------------------------------
; Search the environment for "COMSPEC=" string to locate the system shell.
;----------------------------------------------------------------------
                MOV     AX,WORD PTR [P$PSPSEG]  ;Segment of PSP
                MOV     ES,AX                   ; in ES
        ASSUME  ES:NOTHING
                MOV     AX,WORD PTR ES:[2CH]    ;Segment of environment
                MOV     ES,AX
                MOV     DI,0                    ;Point ES:DI to env
SHELL_1:
                MOV     SI,OFFSET DGROUP:COMSPEC    ;Point DS:SI to COMSPEC=
                CMP     BYTE PTR ES:[DI],0      ;End of env?
                JNE     SHELL_2
;----------------------------------------------------------------------
; Reached end of environment without finding COMSPEC. Someone's in
; serious trouble here. And we fail.
;----------------------------------------------------------------------
                MOV     WORD PTR [P$PDQErr],COMPSEC_NOT_FOUND
                CALL    P$DOERROR               ;see if ON ERROR is active
                JMP     SHELL_EXIT
;----------------------------------------------------------------------
; See if this string is "COMSPEC=".
;----------------------------------------------------------------------
SHELL_2:
                MOV     CX,8                    ;Length to compare
                REPE    CMPSB                   ;Compare strings
                JE      SHELL_3
;----------------------------------------------------------------------
; Strings weren't equal. Position to next string.
;----------------------------------------------------------------------
                MOV     CX,0FFFEH               ;Scan a lot of bytes
                XOR     AL,AL                   ;Look for a zero
                REPNE   SCASB
                JMP     SHELL_1                 ;Pointing to next string
;----------------------------------------------------------------------
; ES:DI now points to the COMPSEC.  Copy the COMSPEC variable into the
; PROGSPEC including the trailing zero.
;----------------------------------------------------------------------
SHELL_3:
                MOV     SI,OFFSET DGROUP:PROGSPEC       ;Copy to here
SHELL_4:
                MOV     AL,BYTE PTR ES:[DI]     ;Load a char
                INC     DI                      ; inc ptr
                MOV     BYTE PTR DS:[SI],AL     ;Save a char
                INC     SI                      ; inc ptr
                OR      AL,AL                   ;If 0, end of copy
                JNZ     SHELL_4                 ; else continue
;----------------------------------------------------------------------
; The command tail is placed right after the progspec.
;----------------------------------------------------------------------
                MOV     WORD PTR [pCMDTAIL],SI  ;Set pointer
                MOV     DI,SI                   ; and in DI
;----------------------------------------------------------------------
; Point ES to DGROUP.
;----------------------------------------------------------------------
                PUSH    DS                      ;Set ES=DGROUP
                POP     ES
        ASSUME  ES:DGROUP
;----------------------------------------------------------------------
; Check for an argument to the SHELL command.
; If length of 0, then no argument to SHELL was provided.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BP+6]      ;Ptr to string ptr
                CMP     WORD PTR [SI],0         ;Is length zero?
                JNE     SHELL_5
;----------------------------------------------------------------------
; No argument is provided.  Just load COMSPEC with no args.
;----------------------------------------------------------------------
                MOV     WORD PTR [DI],0D00H     ;Count byte = 0,CR
                JMP     SHORT SHELL_6
;----------------------------------------------------------------------
; There is a command tail associated with this shell.
; First, insert a space as the first character of the command tail as
; recommended by Microsoft. This is because SOME programs always (and
; incorrectly) assume a space will be the first char of a command tail.
;----------------------------------------------------------------------
SHELL_5:
                MOV     CX,WORD PTR [SI]        ;Length of string

                MOV     AH,20H                  ;Space char
                MOV     AL,CL
                ADD     AL,4                    ;We're adding 4 chars
                STOSW

                MOV     AX,0432FH               ; "/C"
                STOSW
                MOV     AL,20H                  ; " "
                STOSB
;----------------------------------------------------------------------
; Now, copy the command tail into the buffer area, and delete it if needed.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [SI+2]      ;Pointer to string
                REP     MOVSB                   ;Copy the string
                MOV     BYTE PTR [DI],0DH       ;Terminate with CR

                PUSH    [BP+06]
                CALL    P$FREETEMP
;----------------------------------------------------------------------
; For compatibility, the FCBs must be initialized.
; AH=29h
; AL=parsing control
;  Bit 0 = 1, scan off white space
;  Bit 1 = 0, add default drive if none specified
;  Bit 2 = 0, set filename to blanks if not specified
;  Bit 3 = 0, set extension to blanks if not specified
;  other bits = 0
; DS:SI -> string to parse
; ES:DI -> buffer for unopened FCB
;----------------------------------------------------------------------
                MOV     AX,2901H
                MOV     DI,OFFSET DGROUP:FCB1
                MOV     SI,[pCMDTAIL]
                ADD     SI,5                    ;Point past junk
                INT     21H

                MOV     AX,2901H
                MOV     DI,OFFSET DGROUP:FCB2
                INT     21H
;----------------------------------------------------------------------
; Under DOS 2.x, on return, all registers except CS:IP may be destroyed.
; Save the context so we can restore it later.
;----------------------------------------------------------------------
SHELL_6:
                PUSH    DS
                PUSH    BP

                MOV     WORD PTR CS:[SSSAVE],SS
                MOV     WORD PTR CS:[SPSAVE],SP
;----------------------------------------------------------------------
; Using EXEC, run the command SHELL.
; DS:DX -> program spec
; ES:BX -> EPB
;----------------------------------------------------------------------
                MOV     AX,4B00H
                MOV     DX,OFFSET DGROUP:PROGSPEC
                MOV     BX,OFFSET DGROUP:EPB
                INT     21H
;----------------------------------------------------------------------
; Restore context after call.
;----------------------------------------------------------------------
                CLI
                MOV     SS,WORD PTR CS:[SSSAVE]
                MOV     SP,WORD PTR CS:[SPSAVE]
                STI

                POP     BP
                POP     DS
;----------------------------------------------------------------------
; On return, if carry is clear, call succeeded. If carry set, error code
; is in AX.
;----------------------------------------------------------------------
                JNC     SHELL_EXIT
                MOV     WORD PTR [P$PDQErr],AX
;----------------------------------------------------------------------
; Single exit point.
;----------------------------------------------------------------------
SHELL_EXIT:
                CLD
                POP     DI
                POP     SI
                POP     BP
                RET     2

B$SSHL          ENDP

CSEG            ENDS
                END
