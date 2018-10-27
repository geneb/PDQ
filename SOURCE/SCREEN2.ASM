; SCREEN2.ASM
;
;   B$CSCN    PDQ:FAR
;   B$CGAUSED PDQ:Dummy
;   B$HRCUSED PDQ:Dummy
;   B$EGAUSED PDQ:Dummy
;   B$VGAUSED PDQ:Dummy
;   B$GRPUSED PDQ:Dummy
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 9/16/89       .000    Initial.
;               .001    Clean up labels.
; 11/10/89      .002    Change error 5 to -1 (gets translated by ERR.ASM)
; 11/25/89      .003    Update to accept new GET_VIDEO returns.
; 11/29/89      .004    Fix up DGROUP OFFSETs, register use
;               .005    Fail invalid screens, correct PDQ_SCRN numbers.
; 1/8/90        .006    Unified include file.
; 2/8/90        .007    Patch to include the Parameter Count in RET n (EW)
; 2/20/90       .008    Check if screen mode is illegally high (EW)
; 2/28/90       .009    Trap illegally high screen argument
; 3/13/90       .010    Add call to P$DoError at CSCN_ERR (Ethan)
; 11/10/91      .011    Add ccode to clear P$PDQErr on entry (Ethan)
;----------------------------------------------------------------------
PUBLIC  B$CSCN          ;SCREEN n

PUBLIC  B$CGAUSED       ;External references imbedded in program object
PUBLIC  B$HRCUSED
PUBLIC  B$EGAUSED
PUBLIC  B$VGAUSED
PUBLIC  B$GRPUSED

EXTRN   GET_VIDEO:NEAR  ;this is in R$VIDEO.ASM
EXTRN   P$DOERROR:FAR   ;this is in DOERROR.ASM
;----------------------------------------------------------------------
; Information on PDQ's Screen # vs BIOS video modes.
;----------------------------------------------------------------------
; PDQ  BIOS MDA EGA  CGA MCGA  EGA  VGA
; SCRN MODE     MONO          COLOR
;  0     7   Y   Y    -   -     -    -
;        1   -   -    Y   Y     Y    Y
;        3   -   -    Y   Y     Y    Y
;  1     4   -   -    Y   Y     Y    Y
;  2     6   -   -    Y   Y     Y    Y
;  7     D   -   -    -   -     Y    Y
;  8     E   -   -    -   -     Y    Y
;  9    10   -   -    -   -     Y    Y
; 10     F   -   Y    -   -     -    Y(1)
; 11    11   -   -    -   Y     -    Y
; 12    12   -   -    -   Y     -    Y
; 13    13   -   -    -   Y     -    Y
;
; (1) VGA can use this mode if it is the ONLY video adapter installed.
;     Note that the QB 4.5 README.DOC file warns that QB will not work
;     with a VGA card installed that also uses a second mono adapter.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG

DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE         R$PDQ.EQU

EXTRN           P$PDQERR:WORD       ;In ERRDATA.ASM
;----------------------------------------------------------------------
; This chart translates the current BIOS video mode (shown in HEX) to
; its corresponding PDQ Screen # (shown in DECIMAL).
; There are no Screens # 4, 5, or 6.
;
;    BIOS   0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F 10 11 12 13
;----------------------------------------------------------------------
PDQ_SCRN DB 0, 0, 0, 0, 1,-1, 2, 0,-1,-1,-1,-1,-1, 7, 8,10, 9,11,12,13

MAX_SCRN    EQU 13
MAX_BIOS    EQU 13H

;----------------------------------------------------------------------
; This chart shows what PDQ Screen #'s are valid for the various video
; hardware combinations.
;
; PDQ Screen #   0   1   2   3    7    8    9   10   11   12   13
;----------------------------------------------------------------------
_MDA    DB   7, -1, -1, -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1
_EGAM   DB   7, -1, -1, -1,  -1,  -1,  -1, 0FH,  -1,  -1,  -1
_HGC    DB   7, -1, -1, -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1

_CGA    DB   3,  4,  6, -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1
_MCGA   DB   3,  4,  6, -1,  -1,  -1,  -1,  -1, 11H, 12H, 13H

_EGAC   DB   3,  4,  6, -1, 0DH, 0EH, 10H,  -1,  -1,  -1,  -1
_VGA    DB   3,  4,  6, -1, 0DH, 0EH, 10H, 0FH, 11H, 12H, 13H

DSEG            ENDS

USEG            SEGMENT WORD    PUBLIC  'BSS'

EXTRN           VID_ACT:WORD            ;In R$VIDEO.ASM
EXTRN           VID_PAS_ADAP:BYTE       ;In R$VIDEO.ASM

B$CGAUSED       LABEL   WORD            ;Dummy references
B$HRCUSED       LABEL   WORD
B$EGAUSED       LABEL   WORD
B$VGAUSED       LABEL   WORD
B$GRPUSED       LABEL   WORD

USEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; B$CSCN (PDQ)
; Implement variable width and screen lines on EGA and VGA systems.
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Implements the PDQ SCREEN statement.
; 2. Only the first argument of the statement is used.
; 3. If the video mode requested is already the current mode, no action
;    is taken.
;----------------------------------------------------------------------
; This routine accepts variable arguments coded as follows:
; A. The last word pushed on the stack is the total number of words
;    passed, NOT including the count word.
; B. The list is then scanned from the front. A word of 0 indicates that
;    no parameter was specified, or follows.
; C. A word of 1 indicates that the value of the parameter follows.
;----------------------------------------------------------------------
B$CSCN          PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                MOV     WORD PTR [P$PDQErr],0   ;clear ERR (EW)
;----------------------------------------------------------------------
; Since this routine takes a variable number of arguments, patch the
; return instruction so it removes the correct number of bytes.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BP+6]      ;Total # of words pushed
                SHL     SI,1                    ;Convert to bytes
                MOV     WORD PTR CS:[CSCN_RET],SI
                ADD     WORD PTR CS:[CSCN_RET],2 ;include the count word
;----------------------------------------------------------------------
; If no screen arg is passed, return an error.
;----------------------------------------------------------------------
                CMP     WORD PTR [BP+6][SI],0   ;0 = no param = error
                JE      CSCN_ERR
;----------------------------------------------------------------------
; Retrieve the requested screen number.
;----------------------------------------------------------------------
                MOV     DX,WORD PTR [BP+6][SI-2] ;Fetch it
                CMP     DX,MAX_SCRN
                JA      CSCN_ERR        ;Illegally high
;----------------------------------------------------------------------
; Get the current BIOS video mode.
;----------------------------------------------------------------------
                MOV     AH,0FH          ;Get current video mode
                INT     10H
;----------------------------------------------------------------------
; If the BIOS mode is higher than we can accommodate, skip the comparison.
;----------------------------------------------------------------------
                CMP     AL,MAX_BIOS
                JA      CSCN_2
;----------------------------------------------------------------------
; Find the PDQ screen alias for this BIOS mode.
;----------------------------------------------------------------------
                MOV     BL,AL           ;Put mode in BL
                XOR     BH,BH           ;Convert to offset
                MOV     AH,BYTE PTR [PDQ_SCRN][BX] ;Translate
;----------------------------------------------------------------------
; If current screen = requested screen, no action taken.
;----------------------------------------------------------------------
                CMP     AH,AL
                JE      CSCN_EXIT
;----------------------------------------------------------------------
; A change of screen/mode is called for. Convert the PDQ mode to an
; index into the hardware mode tables.
;----------------------------------------------------------------------
CSCN_2:
                CMP     DL,3
                JBE     CSCN_3

                CMP     DL,7            ;Invalid modes
                JB      CSCN_ERR

                SUB     DL,3            ;Change 7 to 4, etc
CSCN_3:
;----------------------------------------------------------------------
; Find the video hardware that is active
; and determine if the requested mode is legal for that hardware.
;----------------------------------------------------------------------
                CALL    GET_VIDEO
                MOV     CX,WORD PTR [VID_ACT]
;----------------------------------------------------------------------
; Select the correct line in the mode permission table. No equipment = error.
;----------------------------------------------------------------------
                OR      CL,CL           ;0 = no equipment
                JZ      CSCN_ERR
;----------------------------------------------------------------------
; MDA and CGA are straightforward.
;----------------------------------------------------------------------
                MOV     BX,OFFSET DGROUP:_MDA
                DEC     CL
                JZ      CSCN_7

                MOV     BX,OFFSET DGROUP:_CGA
                DEC     CL
                JZ      CSCN_7
;----------------------------------------------------------------------
; For an EGA, we must determine if it is acting as a color or mono adapter.
;----------------------------------------------------------------------
                MOV     BX,OFFSET DGROUP:_EGAC
                DEC     CL
                JNZ     CSCN_4

                CMP     CH,MDA_MON
                JNE     CSCN_7

                MOV     BX,OFFSET DGROUP:_EGAM
                JMP     CSCN_7
CSCN_4:
;----------------------------------------------------------------------
; MCGA is straightforward.
;----------------------------------------------------------------------
                MOV     BX,OFFSET DGROUP:_MCGA
                DEC     CL
                JZ      CSCN_7
;----------------------------------------------------------------------
; VGA is fine unless PDQ mono mode 10 is requested and a mono monitor
; already exists in the system.
;----------------------------------------------------------------------
                MOV     BX,OFFSET DGROUP:_VGA
                DEC     CL
                JNZ     CSCN_6

                CMP     BYTE PTR [VID_PAS_ADAP],MDA
                JE      CSCN_5

                CMP     BYTE PTR [VID_PAS_ADAP],HGC
                JB      CSCN_7
CSCN_5:
                CMP     DL,10-3                 ;Adjusted PDQ mode, not hex
                JNE     CSCN_7
CSCN_ERR:
                MOV     WORD PTR [P$PDQErr],-1  ;this becomes 5 in ERR.ASM
                CALL    P$DOERROR               ;see if ON ERROR is active
CSCN_EXIT:
                POP     BP                      ;Erase stack frame
                RET     2                       ;Patch this argument
CSCN_RET        EQU     $-2
;----------------------------------------------------------------------
; All Herc cards are treated the same.
;----------------------------------------------------------------------
CSCN_6:
                MOV     BX,OFFSET DGROUP:_HGC
;----------------------------------------------------------------------
; Determine if this is a legal mode.
;----------------------------------------------------------------------
CSCN_7:
                ADD     BX,DX
                MOV     AL,BYTE PTR [BX]
                CMP     AL,-1
                JE      CSCN_ERR
;----------------------------------------------------------------------
; Set the mode.
;----------------------------------------------------------------------
                XOR     AH,AH           ;Set video mode
                INT     10H

                JMP     CSCN_EXIT

B$CSCN          ENDP

CSEG            ENDS
                END
