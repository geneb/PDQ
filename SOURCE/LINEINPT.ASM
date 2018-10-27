; LINEINPT.ASM
;----------------------------------------------------------------------
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 2/1/90        .000    Pattern after R$INPP
; 2/18/90       .001    Skip the prompt and CRLF if inputting from a file
; 3/16/90       .002    Allow inputting fixed-length strings (Ethan)
;----------------------------------------------------------------------
PUBLIC      B$LNIN          ;NEAR
PUBLIC      R$LINEIN        ;WORD

EXTRN       B$PEOS:FAR              ;In R$PEOS.ASM
EXTRN       B$PSSD:FAR              ;In PRINT.ASM
EXTRN       B$PESD:FAR              ;In PRINT.ASM
EXTRN       P$MAKETEMP:FAR          ;In MAKETEMP.ASM
EXTRN       B$SASS:FAR              ;In ASSIGN$.ASM
EXTRN       B$ASSN:FAR              ;In ASSIGN.ASM

EXTRN       ADJUST_STRING:NEAR      ;In R$ADJUST.ASM

INCLUDE R$PDQ.EQU

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG, USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

EXTRN       P$PRINTHANDLE:WORD              ;In PHANDLE.ASM
R$LINEIN    DW  OFFSET CSEG:R$LINECON
NULL$       DW  0                           ;we only need 1/2 a descriptor
                                            ;(against Rob's better judgement)
DSEG        ENDS
;----------------------------------------------------------------------
USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized
USEG        ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
    ASSUME  CS:CSEG

;======================================================================
; B$LNIN
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Used by LINE INPUT [;] ["PROMPT";] stringvar
;
; 1. Contains the parser code that reads data from the console.
;----------------------------------------------------------------------
; Input:
;   BP+E    Offset of prompt string descriptor
;   BP+C    Segment of data pointer
;   BP+A    Offset of data pointer
;   BP+8    Unknown
;   BP+6    End-of-line flag.
;----------------------------------------------------------------------
B$LNIN      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

            PUSH    BP                  ;Create stack frame
            MOV     BP,SP

            PUSH    SI
            PUSH    DI
;----------------------------------------------------------------------
; Process the prompt string (if any) without a CRLF if console input.
;----------------------------------------------------------------------
            CMP     BYTE PTR [P$PRINTHANDLE],1  ;is this console input?
            JNE     LN_1                        ;no, do NOT print the prompt
                                                ;(use byte ptr for less code)
            PUSH    WORD PTR [BP+0EH]
            CALL    B$PSSD
;----------------------------------------------------------------------
; Call the appropriate routine to get the string descriptor in AX.
;----------------------------------------------------------------------
LN_1:
            CALL    WORD PTR [R$LINEIN]
            PUSH    AX

;----------------------------------------------------------------------
; Process the end-of-line option if console input.
; Bit 1 = 0 - Go to a new line after <enter>
;         1 - Stay on same line after <enter>
;----------------------------------------------------------------------
            TEST    WORD PTR [BP+6],2
            JNZ     LN_2
            CMP     BYTE PTR [P$PRINTHANDLE],1  ;skip CRLF if it's a file
            JNE     LN_2                       

            MOV     BX,OFFSET DGROUP:NULL$
            PUSH    BX
            CALL    B$PESD
LN_2:
;----------------------------------------------------------------------
; Assign the string to the passed parameter.
;----------------------------------------------------------------------
            POP     AX                      ;Retrieve inputted string desc.
            CMP     WORD PTR [BP+8],0       ;is the assignee fixed-length?
            JE      LN_3                    ;no, let B$SASS assign it

            PUSH    DS                      ;yes, pass the segmented source
            PUSH    AX                      ;  address to B$ASSN
            XOR     AX,AX                   ;the source is not fixed-length
            PUSH    AX

            PUSH    WORD PTR [BP+0CH]       ;and the assignee's segment
            PUSH    WORD PTR [BP+0AH]       ;  and address
            PUSH    WORD PTR [BP+8]         ;  and length
            CALL    B$ASSN                  ;this assigns fixed-length data
            JMP     SHORT LN_DONE           ;skip over
LN_3:
            PUSH    AX                      ;pass the inputted descriptor
            PUSH    WORD PTR [BP+0AH]       ;and the assignee
            CALL    B$SASS

;----------------------------------------------------------------------
; Reset the pointer to the console routine.
;----------------------------------------------------------------------
LN_DONE:
            MOV     WORD PTR [R$LINEIN],OFFSET CSEG:R$LINECON
            CALL    B$PEOS
;----------------------------------------------------------------------
; Exit.
;----------------------------------------------------------------------
            POP     DI
            POP     SI

            POP     BP
            RET     5 * 2               ;5 arguments

B$LNIN      ENDP


;======================================================================
; R$LINECON
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; This routine reads a string from the console with no delimiters.
;----------------------------------------------------------------------
R$LINECON   PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
; Create a string that will be used for input from the console.
;----------------------------------------------------------------------
; P$MAKETEMP returns
;  BX = eraseable descriptor containing DI,CX
;  DI = offset of start of eraseable string
;  CX = max length of eraseable string <= requested length
;  ES = DS = DGROUP
;  CLD
;----------------------------------------------------------------------
            MOV     CX,257
            CALL    P$MAKETEMP          ;Make a string
;----------------------------------------------------------------------
; Prepare the buffer for DOS.
; Byte 0 = max chars to read (including ending CR).
; Byte 1 = chars read (set by DOS)
;----------------------------------------------------------------------
            SUB     CX,2
            MOV     BYTE PTR [DI],CL
            MOV     DX,DI
;----------------------------------------------------------------------
; Use DOS to fill in the string.
;----------------------------------------------------------------------
            MOV     AH,0AH
            INT     21H
;----------------------------------------------------------------------
; Clean up the string and adjust its length as needed.
;----------------------------------------------------------------------
            XOR     CH,CH
            MOV     CL,BYTE PTR [DI][1]

            MOV     SI,DI
            ADD     SI,2

            PUSH    CX
            CLD
            REP     MOVSB
            POP     CX
;----------------------------------------------------------------------
; Adjust the string PDQ fashion.  Return descriptor in AX.
;----------------------------------------------------------------------
            CALL    ADJUST_STRING
            MOV     AX,BX

            RET

R$LINECON   ENDP

CSEG        ENDS
            END
