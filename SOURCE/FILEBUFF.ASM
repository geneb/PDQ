; FILEBUFF.ASM
;----------------------------------------------------------------------
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1/31/90   .000    Split out from R$DSKI.
; 2/1/90            Adjust EOF handling.
; 2/8/90    .001    Changed P$MAKETEMP request from 7FFFh to FFFDh
; 3/13/90   .002    Fix unget/next fgetch of first char in buffer.
; 3/13/90   .003    Fix returning null CR string.
; 3/19/90   .004    Check for end of file condition (EW, 2 places).
; 3/26/90   .005    Check for end of file condition (EW).
; 10/8/90   .006    Recognize ^Z as EOF, per Ethan.
; 10/18/90  .010    Add check for out of string space condition.
; 11/14/90  .011    Check for empty quotes, return a null string if so
; 4/23/91   .012    Check for single comma, return a null string if so
;----------------------------------------------------------------------
PUBLIC  FBUF_INIT
PUBLIC  FBUF_RELEASE
PUBLIC  FBUF_FIXLEFT
PUBLIC  FBUF_FIXRIGHT
PUBLIC  FBUF_CLOSE
PUBLIC  FGET_CH
PUBLIC  FUNGET_CH

EXTRN   ADJUST_STRING:NEAR      ;In R$ADJUST.ASM

EXTRN   P$MAKETEMP:FAR          ;In MAKETEMP.ASM
EXTRN   P$FREETEMP:FAR          ;In FREETEMP.ASM
EXTRN   P$DOERROR:FAR           ;In DOERROR.ASM

INCLUDE R$PDQ.EQU

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG, USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

EXTRN       INPUT_DESC:WORD                 ;In R$RDPTR.ASM

EXTRN       P$PRINTHANDLE:WORD              ;In PHANDLE.ASM

MAX_BYTES   EQU 256

DSEG        ENDS

;----------------------------------------------------------------------
; The left side of the string will always be left justified in the
;  buffer.
;----------------------------------------------------------------------
USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized

BUF_SIZE    DW  1 DUP(?)
BUF_START   DW  1 DUP(?)
BUF_END     DW  1 DUP(?)
STR_RIGHT   DW  1 DUP(?)

READ_LIMIT  DW  1 DUP(?)

CH_AVAIL    DW  1 DUP(?)
LOAD_POINT  DW  1 DUP(?)
LAST_CH     DW  1 DUP(?)
UNGOT_FIRST DB  1 DUP(?)
LEFT_FIXED  DB  1 DUP(?)

USEG        ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
    ASSUME  CS:CSEG

;======================================================================
; FBUF_INIT
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
FBUF_INIT   PROC    NEAR
    ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
; Allocate all string space in a single buffer.  This will force a
;  garbage collection and update all the internal parameters.
;----------------------------------------------------------------------
; P$MAKETEMP returns
;  BX = eraseable descriptor containing DI,CX
;  DI = offset of start of eraseable string
;  CX = max length of eraseable string <= requested length
;  ES = DS = DGROUP
;  CLD
;----------------------------------------------------------------------
            MOV     CX,0FFFDH   ;Ask for all but 2 bytes (for a back pointer)
            CALL    P$MAKETEMP  ;Make a string
            
            MOV     AX,14       ;assume out of string space
            JCXZ    FB_ERROR    ;we assumed correctly

            MOV     WORD PTR [INPUT_DESC],BX
            MOV     WORD PTR [BUF_SIZE],CX
            MOV     WORD PTR [BUF_START],DI
            MOV     WORD PTR [LOAD_POINT],DI
            MOV     SI,DI                       ;We claim SI
            DEC     SI
            MOV     DX,DI
            ADD     DI,CX
            MOV     WORD PTR [BUF_END],DI

            MOV     BYTE PTR [LEFT_FIXED],FALSE
            MOV     BYTE PTR [UNGOT_FIRST],FALSE
            MOV     WORD PTR [LAST_CH],0
;----------------------------------------------------------------------
; Determine the length of the maximum read by using MAX_BYTES or the
;  size of the buffer, whichever is smaller.
;----------------------------------------------------------------------
            CMP     CX,MAX_BYTES    ;Compare buffer size to max bytes
            JB      FB_1

            MOV     CX,MAX_BYTES
FB_1:
            MOV     WORD PTR [READ_LIMIT],CX
;----------------------------------------------------------------------
; Prime the buffer by reading one chunk of characters from the file.
;----------------------------------------------------------------------
            MOV     BX,WORD PTR [P$PRINTHANDLE]

            MOV     AH,3FH              ;Read from file/device
            INT     21H
            JC      FB_ERROR

            OR      AX,AX               ;End of file?
            JNZ     FB_2                ;(EW)
            MOV     AX,62               ;set an "Input past end" error
;----------------------------------------------------------------------
; CY indicates an error on the initial read.  Set the error code and
;  return to caller.
;----------------------------------------------------------------------
FB_ERROR:
            CALL    P$DOERROR
            STC
FB_EXIT:
            RET
;----------------------------------------------------------------------
; The read was successful.  AX contains the number of bytes actually
;  read from the file.
;----------------------------------------------------------------------
FB_2:
            MOV     WORD PTR [CH_AVAIL],AX
            ADD     WORD PTR [LOAD_POINT],AX

            JMP     FB_EXIT

FBUF_INIT   ENDP

;======================================================================
; FGET_CH
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1. Recognize ^Z as EOF, per Ethan.
;----------------------------------------------------------------------
; Exit:
;   NC - success, AL contains char
;   CY - fail, AL unchanged
;----------------------------------------------------------------------
; CHANGES: AL, BX
;----------------------------------------------------------------------
FGET_CH     PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
; If no characters are available in the buffer, read in some more.
;----------------------------------------------------------------------
FG_0:
            CMP     WORD PTR [CH_AVAIL],0
            JE      FG_1
;----------------------------------------------------------------------
; If we ungot the first char in the buffer, grab it now.
;----------------------------------------------------------------------
            CMP     BYTE PTR [UNGOT_FIRST],TRUE
            JNE     FG_0A

            MOV     BYTE PTR [UNGOT_FIRST],FALSE
            DEC     SI
FG_0A:
;----------------------------------------------------------------------
; Return the next character in the buffer
;----------------------------------------------------------------------
            CMP     BYTE PTR [SI+1],26
            JNE     FG_0B

            PUSH    AX
            JMP     SHORT FG_3C
FG_0B:
            INC     SI
            MOV     AL,BYTE PTR [SI]
            DEC     WORD PTR [CH_AVAIL]
            CLC
FG_EXIT:
            RET
;----------------------------------------------------------------------
; Refresh the buffer.
;
; If FBUF_FIXLEFT has no been called yet, none of the characters read
;  up till now have to be preserved.
;----------------------------------------------------------------------
FG_1:
            CMP     BYTE PTR [LEFT_FIXED],TRUE
            JE      FG_2
;----------------------------------------------------------------------
; Left is not fixed.
; Preserve the last char for wrap-around protection.
;----------------------------------------------------------------------
            MOV     BX,WORD PTR [BUF_START]

            MOV     SI,BX
            MOV     BYTE PTR [SI],AL

            INC     BX
            MOV     WORD PTR [LOAD_POINT],BX
;----------------------------------------------------------------------
; See if there's room for more chars in the buffer.
;----------------------------------------------------------------------
FG_2:
            MOV     CX,WORD PTR [BUF_END]
            MOV     DX,WORD PTR [LOAD_POINT]

            CMP     CX,DX
            JA      FG_3A
;----------------------------------------------------------------------
; We've run out of buffer.  Nothing more can be done.
;----------------------------------------------------------------------
;;;         STC     ; (note: JA = JNB = JNC, so carry flag is set.)
            JMP     FG_EXIT
;----------------------------------------------------------------------
; There's room to read in chars, figure out how much room.
;----------------------------------------------------------------------
FG_3A:
            SUB     CX,DX
            CMP     CX,WORD PTR [READ_LIMIT]
            JBE     FG_3B

            MOV     CX,WORD PTR [READ_LIMIT]
FG_3B:
;----------------------------------------------------------------------
; DOS read:
;  BX = handle
;  CX = bytes to read
;  DS:DX = DTA
;----------------------------------------------------------------------
            PUSH    AX

            MOV     AH,3FH              ;Read from file/device
            MOV     BX,WORD PTR [P$PRINTHANDLE]

            INT     21H
            JC      FG_ERROR

            OR      AX,AX               ;End of file?
            JNZ     FG_4                ;(EW)
FG_3C:
            MOV     AX,62               ;set an "Input past end" error
FG_ERROR:
            CALL    P$DOERROR
            POP     AX
            STC
            JMP     FG_EXIT             ;CY is set
;----------------------------------------------------------------------
; The read was successful. AX contains the number of characters read.
;  If no characters were read, don't keep looping.
;----------------------------------------------------------------------
FG_4:
            MOV     WORD PTR [CH_AVAIL],AX
            ADD     WORD PTR [LOAD_POINT],AX
            OR      AX,AX
            POP     AX
            JNZ     FG_0
            STC
            JMP     FG_EXIT

FGET_CH     ENDP

;======================================================================
; FUNGET_CH
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Put the current char back into the buffer and make the previous char
;  the current char.
; If can't unget, set a special flag to indicate that the first subsequent
;  fget_ch should re-return the current character.
;----------------------------------------------------------------------
; Changes SI
;----------------------------------------------------------------------
FUNGET_CH   PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            CMP     SI,WORD PTR [BUF_START]
            JNE     FUN_0

            CMP     BYTE PTR [UNGOT_FIRST],TRUE
            JE      FUN_2

            MOV     BYTE PTR [UNGOT_FIRST],TRUE
            JMP     SHORT FUN_1
FUN_0:
            DEC     SI
            MOV     AL,BYTE PTR [SI]
FUN_1:
            INC     WORD PTR [CH_AVAIL]
FUN_2:
            RET

FUNGET_CH   ENDP

;======================================================================
; FBUF_FIXLEFT
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Left-justify the buffer so that the current character is the first
;  char in the buffer.
; Don't call before FGETing at least one char.
;----------------------------------------------------------------------
; Entry:
;   SI -> current char
;----------------------------------------------------------------------
; Changes: CX, SI, DI
;----------------------------------------------------------------------
FBUF_FIXLEFT    PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP
;----------------------------------------------------------------------
; How many chars are we eliminating?  Adjust the next load point.
;----------------------------------------------------------------------
            MOV     DI,WORD PTR [BUF_START]
            MOV     CX,SI               ;Current char
            SUB     CX,DI               ; minus start = chars to kill
            JZ      FL_1
            SUB     WORD PTR [LOAD_POINT],CX
;----------------------------------------------------------------------
; Left justify the remaining chars.
;----------------------------------------------------------------------
            MOV     CX,WORD PTR [CH_AVAIL]
            INC     CX
            REP     MOVSB
            MOV     SI,WORD PTR [BUF_START] ;Reset pointer
FL_1:
            MOV     BYTE PTR [LEFT_FIXED],TRUE
            RET

FBUF_FIXLEFT    ENDP

;======================================================================
; FBUF_RELEASE
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Emergency release of the entire buffer space.
;----------------------------------------------------------------------
FBUF_RELEASE    PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            XOR     AX,AX                       ;Put a 0
            XCHG    AX,WORD PTR [INPUT_DESC]    ; in the descriptor
            PUSH    AX
            CALL    P$FREETEMP                  ;Erase the string

            RET

FBUF_RELEASE    ENDP

;======================================================================
; FBUF_FIXRIGHT
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1. Make the current character the end of the desired substring.
;----------------------------------------------------------------------
FBUF_FIXRIGHT   PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            MOV     WORD PTR [LAST_CH],SI
            RET

FBUF_FIXRIGHT   ENDP

;======================================================================
; FBUF_CLOSE
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1. Update the DOS file pointer to point to the next char.
; 2. Shrink the buffer to the size of the substring.
; 3. Return the descriptor in AX.
;----------------------------------------------------------------------
FBUF_CLOSE  PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            PUSH    DI
;----------------------------------------------------------------------
; Calculate how many unused chars remain in the buffer and back the
;  file pointer up.  If zero bytes are pending, we're done.
;----------------------------------------------------------------------
            MOV     CX,-1
            MOV     DX,WORD PTR [CH_AVAIL]
            NEG     DX
            JZ      FC_1                ;End of file, outa here (EW)
            
            MOV     BX,WORD PTR [P$PRINTHANDLE]

            MOV     AX,4201H
            INT     21H
            JNC     FC_1

            CALL    P$DOERROR
FC_1:
;----------------------------------------------------------------------
; Shrink the buffer to the size of the substring.
;----------------------------------------------------------------------
            MOV     BX,WORD PTR [INPUT_DESC]
            MOV     CX,WORD PTR [LAST_CH]
            MOV     DI,WORD PTR [BUF_START]
            SUB     CX,DI
            JNZ     FC_2B
            
            CMP     BYTE PTR [DI],QUOTE
            JE      FC_2A

            CMP     BYTE PTR [DI],COMMA
            JE      FC_2A

            CMP     BYTE PTR [DI],CR
            JNE     FC_2B
FC_2A:
            DEC     CX
FC_2B:
            INC     CX
            CALL    ADJUST_STRING
;----------------------------------------------------------------------
; Return the descriptor in AX.
;----------------------------------------------------------------------
            MOV     AX,BX

            POP     DI
            RET

FBUF_CLOSE  ENDP

CSEG        ENDS
            END
