; R$DSKI.ASM
;   B$DSKI (PDQ:FAR)
;   R$READFILE (Internal:NEAR)
;----------------------------------------------------------------------
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1/6/90    .000    First working version.
; 1/8/90    .001    Add file back-up after overscan.  New EQU file.
; 1/30/90   .002    Remove ADJUST_STRING.
; 1/31/90   .003    Use centralized temp desc.  Fix scanning.
;           .004    Split buffer routines out.
; 2/1/90    .005    Add support for LINE INPUT #.
; 5/14/90   .006    Fix read when EOF encountered.
; 6/24/90   .007    Add code to strip one LF after terminating CR.
; 7/19/90   .008    Rework code to stop on the first CRLF
; 10/8/90   .009    Recognize ^Z as EOF, per Ethan.
; 10/18/90  .010    Add checks for out of string space condition.
; 6-15-91   .011    Add support for lines ending with CHR$(13) only (no LF)
;----------------------------------------------------------------------
PUBLIC  B$DSKI ;FAR

EXTRN   FBUF_INIT:NEAR      ;In FILEBUFF.ASM
EXTRN   FBUF_RELEASE:NEAR   ;In FILEBUFF.ASM
EXTRN   FBUF_FIXLEFT:NEAR   ;In FILEBUFF.ASM
EXTRN   FBUF_FIXRIGHT:NEAR  ;In FILEBUFF.ASM
EXTRN   FBUF_CLOSE:NEAR     ;In FILEBUFF.ASM
EXTRN   FGET_CH:NEAR        ;In FILEBUFF.ASM
EXTRN   FUNGET_CH:NEAR      ;In FILEBUFF.ASM

EXTRN   P$NUM2HANDLE:FAR    ;In NUM2HNDL.ASM
EXTRN   P$MAKETEMP:FAR      ;In MAKETEMP.ASM
EXTRN   B$SASS:FAR          ;In ASSIGN$.ASM

INCLUDE R$PDQ.EQU

;======================================================================
; Data segments.
;----------------------------------------------------------------------
DGROUP      GROUP   DSEG, USEG
DSEG        SEGMENT WORD    PUBLIC  'DATA'  ;Initialized

    EXTRN   R$LINEIN:WORD       ;In R$LNIN  (B$DSKI)

    EXTRN   R$PARSESTR:WORD     ;In R$RDPTR.ASM (B$DSKI)
    EXTRN   P$PRINTHANDLE:WORD  ;In PHANDLE.ASM (B$DSKI)

    EXTRN   INPUT_DESC:WORD     ;In R$RDPTR.ASM (R$READFILE)
    EXTRN   P$PDQERR:WORD       ;in ERRDATA.ASM (R$READFILE)

DSEG        ENDS

;----------------------------------------------------------------------
USEG        SEGMENT WORD    PUBLIC  'BSS'   ;Uninitialized

    EXTRN   TARGET_TYPE:BYTE                ;In R$RDPTR.ASM (R$READFILE)

    QUOTE_FLAG  DB  1 DUP(?)

USEG        ENDS

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; B$DSKI
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Used by INPUT #<filenum>, <varlist>
;
; 1. Contains the parser code that reads data from a disk file.
;----------------------------------------------------------------------
B$DSKI      PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

            PUSH    BP                  ;Create stack frame
            MOV     BP,SP
;----------------------------------------------------------------------
; Tell the data input routines to read from a disk file.
;----------------------------------------------------------------------
            LEA     AX,CSEG:R$READFILE
            MOV     WORD PTR [R$PARSESTR],AX

            LEA     AX,CSEG:R$LINEFILE
            MOV     WORD PTR [R$LINEIN],AX
;----------------------------------------------------------------------
; Translate the file number into a file handle.
;----------------------------------------------------------------------
            MOV     BX,WORD PTR [BP+6]
            CALL    P$NUM2HANDLE
            MOV     WORD PTR [P$PRINTHANDLE],BX

            POP     BP
            RET     1 * 2               ;1 argument

B$DSKI      ENDP


;======================================================================
; R$LINEFILE
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1. This routine is called by B$LNIN through the near pointer
;    R$LINEIN.  It returns a string descriptor in AX
; 2. This routine reads all characters in the sequential file up to
;    a carriage return.
; 3. It then skips over the CR-LF sequence.
; 4. The next LINE INPUT # reads all characters up to the next CR.
;
; Will not read past a ^Z in the file.
;----------------------------------------------------------------------
R$LINEFILE  PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            PUSH    SI                  ;Save used registers
            PUSH    DI
;----------------------------------------------------------------------
; Initialize variables.
;----------------------------------------------------------------------
            MOV     WORD PTR [P$PDQERR],0 ;Assume no error
;----------------------------------------------------------------------
; Initialize the DOS file buffer routine.
;----------------------------------------------------------------------
            CALL    FBUF_INIT
            JC      RL_0                ;out of string space

            CALL    FGET_CH             ;Get a char from the file
            JNC     RL_1
;----------------------------------------------------------------------
; If FGET_CH returns a CY, it means that no more chars were available
;  or that a file error occured.  Since we've scanned no valid chars up
;  till now, return a null string.
;----------------------------------------------------------------------
RL_ABORT:
            CALL    FBUF_RELEASE        ;Destroy the buffer

RL_0:

            XOR     CX,CX               ;Zero length string
            CALL    P$MAKETEMP
            MOV     AX,BX               ;Desc in AX
;----------------------------------------------------------------------
; Exit the routine.
;----------------------------------------------------------------------
RL_EXIT:
            POP     DI
            POP     SI
            RET
;----------------------------------------------------------------------
; A valid char was read.  Fix the left.
;----------------------------------------------------------------------
RL_1:
            CALL    FBUF_FIXLEFT

            CALL    FUNGET_CH
;----------------------------------------------------------------------
; Scan up to a CR
;----------------------------------------------------------------------
RL_2A:
            CALL    FGET_CH
            JNC     RL_2B

            CALL    FBUF_FIXRIGHT
            JMP     SHORT RL_2C
RL_2B:
            CMP     AL,CR
            JNE     RL_2A

            CALL    FUNGET_CH
            CALL    FBUF_FIXRIGHT
            CALL    FGET_CH

            CALL    FGET_CH
            JC      RL_2C           ;revision .011 by Dave Cleary 6-15-91

            CMP     AL,LF
            JE      RL_2C

            CALL    FUNGET_CH
RL_2C:
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
            CALL    FBUF_CLOSE
            JMP     RL_EXIT

R$LINEFILE  ENDP

;======================================================================
; R$READFILE
;   Copyright (c) 1990 Crescent Software
;   Copyright (c) 1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 0. This routine is called indirectly through the near pointer
;    R$PARSESTR.  It should return a string descriptor in AX.
; 1. This routine scans a single data item at a time from a disk file
;    and then returns it as a string.
; 2. It will read from the file as directed by a call from the parsing
;    routine B$RD??.  Each time it is entered, it is expected to return
;    a single parsed item.
; 3. Futher, an item will be automatically truncated if there is not
;    enough string space available to hold it.
;----------------------------------------------------------------------
; RULES FOR SCANNING:
;
; NUMBERS:
;
;  Leading spaces, returns and line feeds are ignored.  The first
;   character that is not a space, return or line feed is assumed to be
;   the start of a number.
;  A number terminates on a space, line feed, return or comma.
;  If terminated on a CR, one and only one LF is scanned off if present.
;
; STRINGS:
;
; If scanning for a string, leading spaces will be ignored.
; A string terminates on a line feed, return or comma.
; If terminated on a CR, one and only one LF is scanned off if present.
;
; A quoted string terminates on a closing quote.
;
; BOTH:
;
; If EOF is reached during input, the item is terminated.
;----------------------------------------------------------------------
; Entry:
;   ES = DGROUP (set by compiler before calling B$RD??)
; Exit:
;   AX - contains string pointer.
;----------------------------------------------------------------------
R$READFILE  PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:DGROUP, SS:DGROUP

            PUSH    SI                  ;Save used registers
            PUSH    DI
;----------------------------------------------------------------------
; Initialize variables.
;----------------------------------------------------------------------
            CLD                           ;String moves forward
            MOV     WORD PTR [P$PDQERR],0 ;Assume no error

;----------------------------------------------------------------------
; Initialize the DOS file buffer routine.
;----------------------------------------------------------------------
            CALL    FBUF_INIT
            JC      RF_10               ;Out of string space

;----------------------------------------------------------------------
; Scan the string to ignore leading consumables: CR, LF and BLANK.
;----------------------------------------------------------------------
RF_1A:
            CALL    FGET_CH             ;Get a char from the file
            JNC     RF_1B
;----------------------------------------------------------------------
; If FGET_CH returns a CY, it means that no more chars were available
;  or that a file error occured.  Since we've scanned no valid chars up
;  till now, return a null string.
;----------------------------------------------------------------------
RF_ABORT:
            CALL    FBUF_RELEASE        ;Destroy the buffer

RF_10:
            XOR     CX,CX               ;Zero length string
            CALL    P$MAKETEMP
            MOV     AX,BX               ;Desc in AX
;----------------------------------------------------------------------
; Exit the routine.
;----------------------------------------------------------------------
RF_EXIT:
            POP     DI
            POP     SI
            RET
;----------------------------------------------------------------------
; A valid char was read.  If white space, ignore it and continue reading.
;----------------------------------------------------------------------
RF_1B:
            CMP     AL,BLANK
            JE      RF_1A
;----------------------------------------------------------------------
; A non-white char was found.  If it was a quote, then set the flag for
;  scanning a quoted string and skip the quote.
;----------------------------------------------------------------------
            XOR     AH,AH               ;AH = 0

            CMP     AL,QUOTE
            JNE     RF_2

            NOT     AH                  ;AH = FF

            CALL    FGET_CH             ;Skip the quote
            JC      RF_ABORT
RF_2:
            MOV     BYTE PTR [QUOTE_FLAG],AH

;----------------------------------------------------------------------
; The current character is the first character of the string.  Fix the
;  left part of the string in the buffer so it won't get over-written.
;----------------------------------------------------------------------
            CALL    FBUF_FIXLEFT
            JMP     SHORT RF_3B

;----------------------------------------------------------------------
; Find the end of the item by scanning for a delimiter.  A number ends
;  on BLANK, COMMA, LF, CR or EOF.  A string ends on a COMMA, LF, CR, or
;  EOF unless it started with a quote, in which case it ends with a quote.
;----------------------------------------------------------------------
; If FGET_CH returns CY, then assume it hit an EOF.  The current character
;  is the last valid character in the buffer.
;----------------------------------------------------------------------
RF_3A:
            CALL    FGET_CH
            JNC     RF_3B
            CALL    FBUF_FIXRIGHT
            JMP     SHORT RF_4D

;----------------------------------------------------------------------
; If scanning a quoted string, only a closing quote is a delimiter.
;----------------------------------------------------------------------
RF_3B:
            OR      AH,AH               ;IF not quoted, jump
            JZ      RF_3C

            CMP     AL,QUOTE            ;Closing quote?
            JNE     RF_3A

            JMP     SHORT RF_3D

;----------------------------------------------------------------------
; Scanning an unquoted string or a number.
;----------------------------------------------------------------------
RF_3C:
            CMP     AL,COMMA            ;Ends both
            JE      RF_3D

            CMP     AL,CR               ;Ends both
            JE      RF_3D

            CMP     AL,LF               ;Ends both
            JE      RF_3D

            CMP     BYTE PTR [TARGET_TYPE],_NUMERIC
            JNE     RF_3A

            CMP     AL,BLANK            ;Ends only a number
            JNE     RF_3A

;----------------------------------------------------------------------
; The last char read was the delimiter.  Temporarily unget it and fix
;  the right side of the string.
;----------------------------------------------------------------------
RF_3D:
            CALL    FUNGET_CH
            CALL    FBUF_FIXRIGHT

;----------------------------------------------------------------------
; Clean-up.
; This routine scans off trailing white space/delimiters to position the
;  file for the next read.  The first character it gets is the one that
;  stopped the scan.
;----------------------------------------------------------------------
RF_4A:
            CALL    FGET_CH
            JC      RF_4D
            CMP     AL,BLANK            ;Scan off blanks
            JE      RF_4A

;----------------------------------------------------------------------
; If quoted string, scan off one quote (the closing one we backed up
;  over), then turn it off.
;----------------------------------------------------------------------
            OR      AH,AH
            JE      RF_4B

            XOR     AH,AH               ;Turn off quote flag
            JMP     RF_4A
RF_4B:
            CMP     AL,COMMA            ;Stop if comma
            JE      RF_4D

;---------------------------------------------------------------------- 
; If a CR is scanned, check for a following LF.
;----------------------------------------------------------------------
            CMP     AL,CR               ;If CR
            JNE     RF_4C

            CALL    FGET_CH     ; get next char
            JC      RF_4D
RF_4C:
            CMP     AL,LF               ; or LF
            JE      RF_4D
;----------------------------------------------------------------------
; We've scanned a non-white, non-delimiter.  Put it back and we're done.
;  The file will be positioned to make the next character to be read the
;  next character in the file.
;----------------------------------------------------------------------
            CALL    FUNGET_CH
RF_4D:
;----------------------------------------------------------------------
; This function:
; 1. updates the pointer
; 2. shrinks the buffer
; 3. returns the string descriptor in AX
;----------------------------------------------------------------------
            CALL    FBUF_CLOSE

;----------------------------------------------------------------------
; Exit the routine.
;----------------------------------------------------------------------
            POP     DI
            POP     SI

            RET

R$READFILE  ENDP

CSEG        ENDS
            END
