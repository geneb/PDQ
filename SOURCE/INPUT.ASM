; INPUT.ASM
;   B$INPP (PDQ:FAR)
;   R$READCON (Internal:NEAR)
;----------------------------------------------------------------------
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1/30/90   .000    Pattern after b$dski.
; 1/31/90   .001    Fix quoted scanning.
;           .002    Add end-of-line option.
;           .003    Used central temp desc.
;----------------------------------------------------------------------
PUBLIC      B$INPP ;FAR
PUBLIC      R$READCON ;NEAR

EXTRN       B$PSSD:FAR              ;In PRINT.ASM
EXTRN       B$PESD:FAR              ;In PRINT.ASM
EXTRN       P$MAKETEMP:FAR          ;In MAKETEMP.ASM

EXTRN       ADJUST_STRING:NEAR      ;In R$ADJUST.ASM

INCLUDE R$PDQ.EQU

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG, USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

EXTRN       R$PARSESTR:WORD                 ;In R$RDPTR.ASM
EXTRN       INPUT_DESC:WORD                 ;In R$RDPTR.ASM

Q_MARK$     DB  "?"
Q_MARK      DW  1,OFFSET DGROUP:Q_MARK$

NULL$       DW  0,0

DSEG        ENDS

;----------------------------------------------------------------------
USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized

EXTRN       TARGET_TYPE:BYTE                ;In R$RDPTR.ASM

BYTES_LEFT  DW  1 DUP(?)
QUOTE_FLAG  DB  1 DUP(?)

USEG        ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; B$INPP
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Used by INPUT [;] ["PROMPT" {;|,}] [varlist]
;
; 1. Contains the parser code that reads data from the console.
;----------------------------------------------------------------------
; Input:
;   BP+A    Offset of prompt string descriptor
;   BP+8    Segment of data pointer
;   BP+6    Offset of data pointer
;----------------------------------------------------------------------
B$INPP      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

            PUSH    BP                  ;Create stack frame
            MOV     BP,SP

            PUSH    SI
            PUSH    DI
;----------------------------------------------------------------------
; Process the prompt string (if any) without a CRLF.
;----------------------------------------------------------------------
            PUSH    WORD PTR [BP+0AH]
            CALL    B$PSSD
;----------------------------------------------------------------------
; Check the flag byte to see if a question mark should be printed after
;  the prompt.
; Bit 0 = 0 - Print question mark at end of the prompt
;         1 - Do not print a question mark at the end of the prompt
;----------------------------------------------------------------------
            PUSH    WORD PTR [BP+8]
            POP     ES
            MOV     BX,WORD PTR [BP+6]

            TEST    BYTE PTR ES:[BX][2],1
            JNZ     BIN_1

            MOV     AX,OFFSET DGROUP:Q_MARK
            PUSH    AX
            CALL    B$PSSD
BIN_1:
;----------------------------------------------------------------------
; Now, create a string that will be used for input from the console.
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

            MOV     WORD PTR [INPUT_DESC],BX
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
; Adjust the string PDQ fashion.
;----------------------------------------------------------------------
            MOV     WORD PTR [BYTES_LEFT],CX
            CALL    ADJUST_STRING

;----------------------------------------------------------------------
; Process the end-of-line option.
; Bit 1 = 0 - Go to a new line after <enter>
;         1 - Stay on same line after <enter>
;----------------------------------------------------------------------
            PUSH    WORD PTR [BP+8]
            POP     ES
            MOV     BX,WORD PTR [BP+6]

            TEST    BYTE PTR ES:[BX][2],2
            JNZ     BIN_2

            MOV     AX,OFFSET DGROUP:NULL$
            PUSH    AX
            CALL    B$PESD
BIN_2:
;----------------------------------------------------------------------
; Tell the data input routines to read from an internal string.
;----------------------------------------------------------------------
            LEA     AX,CSEG:R$READCON
            MOV     WORD PTR [R$PARSESTR],AX
;----------------------------------------------------------------------
; Exit the routine.
;----------------------------------------------------------------------
            POP     DI
            POP     SI

            POP     BP
            RET     3 * 2               ;1 argument

B$INPP      ENDP


;======================================================================
; R$READCON
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 0. This routine is called indirectly through the near pointer
;    R$PARSESTR.  It returns a string descriptor in AX.
; 1. Scan items from a string read in from the console.
; 2. Duplicates a lot of code in R$READDATA that will be combined later.
; 3. If there is no more input on the line, a null string will be returned.
;----------------------------------------------------------------------
R$READCON   PROC    NEAR

            CLD
            PUSH    SI
            PUSH    DI

;----------------------------------------------------------------------
; Get current state of source string.
;----------------------------------------------------------------------
            MOV     BX,WORD PTR [INPUT_DESC]

            MOV     CX,WORD PTR [BX]        ;String length
            MOV     SI,WORD PTR [BX][2]     ;String offset

            ADD     SI,CX                   ;Point SI

            MOV     CX,WORD PTR [BYTES_LEFT]
            JCXZ    RC_1

            SUB     SI,CX                   ; to next char
            JMP     SHORT RC_2A

;----------------------------------------------------------------------
; P$MAKETEMP returns
;  BX = eraseable descriptor containing DI,CX
;  DI = offset of start of eraseable string
;  CX = max length of eraseable string <= requested length
;  ES = DS = DGROUP
;  CLD
;----------------------------------------------------------------------
RC_1:
            CALL    P$MAKETEMP
            MOV     AX,BX
            JMP     SHORT RC_EXIT

;----------------------------------------------------------------------
; String is guaranteed to contain at least one character.
; Position SI to point to the first non-blank character in the string.
;----------------------------------------------------------------------
RC_2A:
            LODSB                   ;Get char in AL

            CMP     AL,BLANK
            JNE     RC_3A

            LOOP    RC_2A           ;DEC CX
;----------------------------------------------------------------------
; If we get here, we hit the end of the string without finding any non-
;  blank characters.  CX=0.  Return a null string.
;----------------------------------------------------------------------
RC_2B:
            MOV     WORD PTR [BYTES_LEFT],CX
            JMP     RC_1

;----------------------------------------------------------------------
; The last char read was a non-blank at SI-1.
; If character was a quote, set the flag and decrease the bytes left
;  count.  If no more characters, return a null string.
; If not a quote, back up.
;----------------------------------------------------------------------
RC_3A:
            XOR     AH,AH               ;AH = 0 (Flag OFF)

            CMP     AL,QUOTE
            JNE     RC_3B

            DEC     CX                  ;Remove quote from count
            JCXZ    RC_2B               ;No bytes left?

            NOT     AH                  ;AH = FF (Flag ON)
            INC     SI                  ;Cancel next instruction
RC_3B:
            DEC     SI                  ;Back up SI
            MOV     DX,SI               ;Save start of string


;======================================================================
; Find the end of the item by scanning for a delimiter.
;
; 1. SI -> first non-blank character in string.
; 2. CX = number bytes in string.  Must be > 0
;----------------------------------------------------------------------
; A number ends on a BLANK or a COMMA.
; A non-quoted string ends on a COMMA.
; A quoted string ends with a quote.
;----------------------------------------------------------------------
RC_5A:
            LODSB                       ;Get a char in AL

            OR      AH,AH               ;IF not quoted, jump
            JZ      RC_5B

            CMP     AL,QUOTE            ;Closing quote?
            JNE     RC_5C

            MOV     DI,SI               ;Point DI to
            DEC     DI                  ; char before quote
            DEC     DI
            DEC     CX                  ;Subtract quote
            JMP     SHORT RC_5E
RC_5B:
            CMP     AL,COMMA            ;Comma ends scan
            JE      RC_5D

            CMP     BYTE PTR [TARGET_TYPE],_STRING
            JE      RC_5C

            CMP     AL,BLANK            ;Blank ends non-string
            JE      RC_5D
RC_5C:
            LOOP    RC_5A
;----------------------------------------------------------------------
; We've read the last character in the string without finding an ending
;  delimiter.
;
; 1. If numeric or non-quoted string, this is acceptable.
; 2. If quoted string, the ending quote was missing -- ignore it.
;----------------------------------------------------------------------
            DEC     SI
            MOV     DI,SI
            JMP     SHORT RC_6D

;----------------------------------------------------------------------
; The scan was ended by a delimiter at [SI-1].
; If CX is 0, there aren't any characters that need to be cleaned up at
;  the end of the string.  Go directly to the copy section.
;----------------------------------------------------------------------
RC_5D:
            DEC     SI                  ;Point SI to delimiter again

            MOV     DI,SI               ;Point DI to char before delim
            DEC     DI
RC_5E:


;======================================================================
; Clean-up.
; Scan for a proper delimiter or end of string.
;----------------------------------------------------------------------
RC_6B:
            LODSB

            CMP     AL,COMMA
            JE      RC_6C

            LOOP    RC_6B
            INC     CX                  ;Cancel next instruction
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
RC_6C:
            DEC     CX
RC_6D:
            MOV     WORD PTR [BYTES_LEFT],CX


;======================================================================
; Find the length of the string.
;----------------------------------------------------------------------
            MOV     SI,DX               ;Start in SI
            MOV     CX,DI               ;End in CX
            SUB     CX,SI
            INC     CX                  ;Length of string

;----------------------------------------------------------------------
; Copy the string to a new temporary string.
; Copy DX characters from DS:SI.
;----------------------------------------------------------------------
            CALL    P$MAKETEMP

            REP     MOVSB
            MOV     AX,BX
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
RC_EXIT:
            POP     DI
            POP     SI

            RET

R$READCON   ENDP

CSEG        ENDS
            END
