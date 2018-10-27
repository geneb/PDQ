;======================================================================
; READ.ASM
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 12/3/89       .000    Initial version.
; 1/3/90        .001    General rewrite.  Change include file.
; 2/11/90       .002    Fix scanning of tail.
; 3/13/90       .003    Add call to P$DoError (all .003 patches by Ethan)
;                       Added SS: override just above label GD_2:
; 5/14/90       .004    Fix null strings
; 9/22/90       .005    Partial...
; 10/3/90       .006    Support independent READ/DATA in seperate OBJ modules
; 10/7/90       .007    Excise common code.
;----------------------------------------------------------------------
PUBLIC      R$READDATA  ;NEAR

EXTRN   P$MAKETEMP:FAR      ;this is in MAKETEMP.ASM
EXTRN   P$DOERROR:FAR       ;this is in DOERROR.ASM
EXTRN   R$FIND_DATA:NEAR    ;In FINDDATA.ASM

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG, USEG

DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

INCLUDE R$PDQ.EQU

EXTRN       P$PDQERR:WORD

OUT_OF_DATA_ERR EQU     -2

DSEG            ENDS

;----------------------------------------------------------------------
; SAVERR saves any errors because P$MakeTemp calls P$TempStr which in
; turn clears P$PDQErr.
;----------------------------------------------------------------------
USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized
 DELIM      DB  1 DUP(?)
 SAVERR     DW  1 DUP(?)
USEG        ENDS

;======================================================================
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; R$READDATA
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1. This routine reads the next entry from the DATA statements and
;    returns it as a string.
; 2. An unquoted string cannot contain commas, colons, or significant
;    leading or trailing BLANKs.  The compiler will eat the commas and
;    colon.  This routine will eat the leading or trailing BLANKs.
; 3. DATA statements are global within a single source code file and
;    local to that file.  That is, they cannot be read from another file.
;----------------------------------------------------------------------
; Returns:
;   CF = CY - read failed. Out of data, most likely.
;        NC - read was successful. (NOT IMPLEMENTED)
;   AX - contains string pointer.
;----------------------------------------------------------------------
; Data from DATA statements is stored in DGROUP in the following format:
;
;   DW  internal line number
;   DB  ASCIIZ literal of the source line following "DATA"
;   ... (repeats for each DATA statement in the file)
;   DW  -1
;   DB  1
;   ... (entire block repeats for each OBJ module)
;----------------------------------------------------------------------
; Changes: AX BX CX ES
;----------------------------------------------------------------------
R$READDATA  PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

        PUSH    SI                      ;Save used registers
        PUSH    DI
;----------------------------------------------------------------------
; Initializations.
;----------------------------------------------------------------------
        CLD                             ;String moves forward, please
        MOV     WORD PTR [SAVERR],0     ;Initialize to no error
        MOV     BYTE PTR [DELIM],COMMA  ;Set delimiter
;----------------------------------------------------------------------
; Find the data pointers.
;----------------------------------------------------------------------
        CALL    R$FIND_DATA
    ASSUME  ES:NOTHING

        CMP     WORD PTR [BX],0         ;0 means never been read
        JNE     GD_0

        MOV     WORD PTR [BX],1         ;Set used/new line flags
;----------------------------------------------------------------------
; The compiler sets the pointer at DS:[C] to point past the first line
; number. Since my routines expect that number to be present, its easier
; to modify THEIR pointer than MY code. (Take THAT Mr. Gates).
;----------------------------------------------------------------------
        MOV     AX,WORD PTR ES:[0CH]    ;Get QB pointer
        SUB     AX,2                    ; modify it
        MOV     WORD PTR [BX+2],AX      ; and put in scratch area
GD_0:
        MOV     SI,WORD PTR [BX+2]      ;Point to next read posn
;----------------------------------------------------------------------
; If we're on a new line, we must queue up the pointer (SI).
;----------------------------------------------------------------------
        TEST    WORD PTR [BX],2         ;Queue new line?
        JNZ     GD_3

        OR      WORD PTR [BX],2         ;Turn request off
GD_1:
        LODSW                           ;Read the line number

        CMP     AX,-1                   ;-1 = end of data
        JNE     GD_3
;----------------------------------------------------------------------
; READ out of DATA.
;----------------------------------------------------------------------
        MOV     WORD PTR [SAVERR],OUT_OF_DATA_ERR
;----------------------------------------------------------------------
; We deal with this by returning a null string.
;----------------------------------------------------------------------
GD_2:
        XOR     CX,CX                   ;Request a null string
        CALL    P$MAKETEMP
        MOV     AX,BX

        JMP     GD_EXIT
;----------------------------------------------------------------------
; Find the first non-blank character in the substring.
;----------------------------------------------------------------------
GD_3:
        LODSB                           ;Get char 
        CMP     AL,BLANK                ;Ignore leading blanks
        JE      GD_3
;----------------------------------------------------------------------
; If the first non-blank is a 0, the string is null.
; If the first non-blank is the delimiter, then the substring is null.
;----------------------------------------------------------------------
        OR      AL,AL                   ;End of data line?
        JNZ     GD_4A

        AND     WORD PTR [BX],NOT 2     ;Newline ON
        JMP     SHORT GD_4B
GD_4A:
        CMP     AL,BYTE PTR [DELIM]
        JNE     GD_5A
GD_4B:
        MOV     WORD PTR [BX+2],SI      ;Save current pointer
GD_4C:
        JMP     GD_2
;----------------------------------------------------------------------
; The string is now guaranteed NOT to be null.  It may, however, still
;  be a null QUOTED string.
;----------------------------------------------------------------------
GD_5A:
        DEC     SI                      ;Point to first char
        CMP     AL,QUOTE                ;If char not quote, skip
        JNE     GD_5B

        MOV     BYTE PTR [DELIM],AL     ;Change delim to quote
        INC     SI                      ;Point past quote
GD_5B:
;----------------------------------------------------------------------
; Now SI points to the first non-blank, non-comma, non-quote char.
;----------------------------------------------------------------------
        MOV     DI,SI                   ;Save start of string
;----------------------------------------------------------------------
; Find the end of the substring by reading for either an occurrence of
;  the delimiter or the end of the line of data (a 0 byte).
; NOTE: We assume an open-quote situation will be caught by the compiler.
;----------------------------------------------------------------------
GD_6A:
        LODSB                           ;Fetch a char in AL

        CMP     AL,BYTE PTR [DELIM]     ;Was it the delimiter?
        JE      GD_6B                   ; yes

        OR      AL,AL                   ;End of line?
        JNZ     GD_6A                   ; no, keep scanning

        AND     WORD PTR [BX],NOT 2     ;Next guy must queue
GD_6B:
;----------------------------------------------------------------------
; If the delimiter was changed to accommodate a quoted string, additional
;  characters may have to be scanned off to have the pointer ready for
;  the next READ.
;----------------------------------------------------------------------
        MOV     WORD PTR [BX+2],SI      ;Update pointer

        CMP     BYTE PTR [DELIM],COMMA
        JE      GD_7C
;----------------------------------------------------------------------
; Scan off all characters after the closing quote, up to a comma or
;  end-of-data 0.
;----------------------------------------------------------------------
        MOV     CX,SI
        DEC     CX
        DEC     CX
        MOV     BYTE PTR [DELIM],COMMA
GD_7A:
        LODSB                           ;Get a char

        CMP     AL,BYTE PTR [DELIM] ;If delim, we're ok
        JE      GD_7B

        OR      AL,AL                   ;End of data line?
        JNZ     GD_7A

        AND     WORD PTR [BX],NOT 2     ;Next guy must queue
GD_7B:
        MOV     WORD PTR [BX+2],SI      ;Advance pointer some more
        MOV     SI,CX                   ;Restore for length calc
        JMP     SHORT GD_7F
;----------------------------------------------------------------------
; Strip off any trailing blanks from non-quoted strings.
;----------------------------------------------------------------------
GD_7C:
        DEC     SI
        CMP     BYTE PTR [SI],0         ;Remove trailing zero
        JNE     GD_7C1
        
        DEC     SI
GD_7C1:
        CMP     BYTE PTR [SI],COMMA
        JNE     GD_7E
GD_7D:
        DEC     SI
GD_7E:
        CMP     BYTE PTR [SI],BLANK
        JE      GD_7D
GD_7F:
;----------------------------------------------------------------------
; Figure out the length of the substring.
; If the string length-1 = 0 and the character at DI is a quote, then
; we have a null quotes.
;----------------------------------------------------------------------
        XCHG    SI,DI
        SUB     DI,SI
        JNZ     GD_8A

        CMP     BYTE PTR [SI],QUOTE
        JE      GD_8B
GD_8A:
        INC     DI
        JZ      GD_4C
GD_8B:
        MOV     CX,DI
;----------------------------------------------------------------------
; Create a string to copy the characters into.  Note that we lose the
;  pointer (ES) to the calling code segment, but we're done with it.
;----------------------------------------------------------------------
; P$MAKETEMP returns
;  BX = eraseable descriptor containing DI,CX
;  DI = offset of start of eraseable string
;  CX = max length of eraseable string
;  ES = DS = DGROUP
;  CLD
;----------------------------------------------------------------------
GD_8C:
        PUSH    CX
        CALL    P$MAKETEMP
    ASSUME  ES:DGROUP
        POP     AX

        JCXZ    GD_9B
        REP     MOVSB               ;DS:SI -> ES:DI
GD_9B:
;----------------------------------------------------------------------
; Return pointer to the temp string.
;----------------------------------------------------------------------
        MOV     AX,BX
;----------------------------------------------------------------------
; Exit here.
;----------------------------------------------------------------------
GD_EXIT:
        MOV     DX,SAVERR           ;copy the saved error to P$PDQErr
        MOV     P$PDQERR,DX         ;assign the success/failure of READ
        OR      DX,DX               ;was there in fact an error?
        JZ      NOERROR             ;no, skip over
        CALL    P$DOERROR           ;yes, see if ON ERROR is in effect
NOERROR:
        POP     DI
        POP     SI

        RET

R$READDATA  ENDP

CSEG        ENDS
        END
