; WIDTH.ASM
;  B$WIDT   PDQ:FAR
;  SET_MODE Local:NEAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 9/16/89       .001    Major overhaul.
; 9/16/89       .002    Split from support routines.
; 11/21/89      .003    Modify for new GET_VIDEO returns.
; 11/28/89      .004    Rewrite based on state table.
; 11/29/89              Fix up DGROUP-relative OFFSETs
;               .005    Add 43-line graphics support.
; 12/30/89      .006    Reset to 400 lines for VGA.
; 1/8/90        .007    Unified include file.
; 3/13/90       .008    Added P$DoError (Ethan).
;----------------------------------------------------------------------
PUBLIC  B$WIDT

EXTRN   GET_VIDEO:NEAR      ;In R$VIDEO.ASM
EXTRN   P$DOERROR:FAR       ;In DOERROR.ASM
;----------------------------------------------------------------------
; DGROUP addressing fixed by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU

EXTRN   P$PDQErr:WORD   ;In ERRDATA.ASM

;----------------------------------------------------------------------
; Video state table. A -1 indicates an illegal state transition.
;
;    Current    Mode required to accomodate the WIDTH command
;   BIOS Mode   80,25   40,25   80,43   40,43   80,50   40,50
;
; The offsets are as follows (in binary)
;       000 001 010 011 100 101
; Note that this lets the following mapping occur:
;   Bit 0 = 0 80 cols
;           1 40 cols
;     1,2 = 00 25 rows
;           01 43 rows
;           10 50 rows
;----------------------------------------------------------------------
VENTRIES    EQU 12          ;# initial states in table
VLEN        EQU 6

VSTATE  LABEL   BYTE
DB  1,  3,  1,  3,  1,  3,  1
DB  3,  3,  1,  3,  1,  3,  1
DB  4,  6,  4,  3,  1,  3,  1
DB  6,  6,  4,  3,  1,  3,  1
DB  7,  7,  -1, 7,  -1, 7,  -1
DB  0DH,    0EH,    0DH,    3,  1,  3,  1
DB  0EH,    0EH,    0DH,    3,  1,  3,  1
DB  0FH,    0FH,    -1, 0FH,    -1, 7,  -1
;               ÚQB supports this in BIOS mode 10H
DB  10H,    10H,    0DH,    10H,    1,  3,  1
;DB 10H,    10H,    0DH,    3,  1,  3,  1

DB  11H,    3,  1,  3,  1,  3,  1
DB  12H,    3,  1,  3,  1,  3,  1
DB  13H,    3,  13H,    3,  1,  3,  1

DSEG            ENDS
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'

EXTRN   VID_ACT:WORD                ;In R$VIDEO.ASM
EXTRN   VID_ACT_ADAP:BYTE           ;In R$VIDEO.ASM
EXTRN   VID_ACT_MON:BYTE            ;In R$VIDEO.ASM
EXTRN   VID_PAS_ADAP:BYTE           ;In R$VIDEO.ASM

VGA_LINES   DB  1 DUP(?)

USEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

;======================================================================
; B$WIDT (PDQ)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Implement the PDQ WIDTH statement.
; 1. Used to set the number of rows and columns on the screen.
; 2. Works in either text or graphics modes.
;----------------------------------------------------------------------
; Possibilities for active monitor:
;
; Adapt Mon     40      80      25      43      50
;
; VGA   (any)   x       x       x       x       x
;
; EGA   EGA     x       x       x       x
;
; EGA   CGA     x       x       x
; CGA   CGA     x       x       x
;
; EGA   MONO            x       x
; MDA   MONO            x       x
;----------------------------------------------------------------------
; Usage:
;       WIDTH [columns][,rows]
; where
;       columns = 40, 80
;       rows = 25, 43, 50 as allowed by hardware.
;
; Note: If rows is not specified, it will be assumed to be 25
;----------------------------------------------------------------------
B$WIDT          PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                  ;Create stack frame
                MOV     BP,SP
                PUSH    SI                  ;Save used registers
;----------------------------------------------------------------------
; Get the requested columns and rows as passed. If not specified, fill
; in defaults.
;----------------------------------------------------------------------
                MOV     WORD PTR P$PDQERR,0 ;assume no errors
                
                MOV     DH,BYTE PTR [BP+8]  ;Columns
                MOV     DL,BYTE PTR [BP+6]  ;Rows

                MOV     AH,0FH          ;Get AH=COLS,AL=MODE
                INT     10H             ; Thru BIOS

                CMP     DL,-1           ;If rows not passed
                JNE     W_1
                MOV     DL,25           ; default to 25
W_1:
                CMP     DH,-1           ;If cols not passed
                JNE     W_2
                MOV     DH,AH           ; used BIOS value
W_2:
;----------------------------------------------------------------------
; Turn the requested width and height into an index for the state table.
;----------------------------------------------------------------------
                XOR     BX,BX           ;Index

                CMP     DH,80           ;Columns
                JE      W_3
                INC     BX

                CMP     DH,40           ;Columns
                JNE     W_ERR
W_3:
                CMP     DL,25           ;Rows
                JE      W_4

                ADD     BL,2
                CMP     DL,43           ;Rows
                JE      W_4

                ADD     BL,2
                CMP     DL,50           ;Rows
                JNE     W_ERR
W_4:
;----------------------------------------------------------------------
; See if the requested state change is legal.
;----------------------------------------------------------------------
                MOV     SI,OFFSET DGROUP:VSTATE
                MOV     CX,VENTRIES     ;Entries to check
                MOV     AH,AL           ;Current mode in AH
W_5:
                LODSB                   ;Get mode in AL

                CMP     AH,AL           ;Do modes match?
                JE      W_6

                ADD     SI,VLEN         ;Try next entry
                LOOP    W_5
W_ERR:
                MOV     WORD PTR [P$PDQErr],-1  ;gets changed to 5 in ERR.ASM
                CALL    P$DOERROR               ;handle if ON ERROR is active
                JMP     SHORT W_EXIT
W_6:
;----------------------------------------------------------------------
; Determine if this state transistion is allowed.
;  If yes, change the video mode. If no, exit with error.
;----------------------------------------------------------------------
                MOV     AL,BYTE PTR [SI][BX]    ;New mode
                CMP     AL,-1
                JE      W_ERR

;----------------------------------------------------------------------
; Determine the type of installed equipment. If a VGA is present, the
;  number of scan lines must be set. First, assume 400 lines will be
;  used.
;----------------------------------------------------------------------
                CALL    GET_VIDEO       ;Identify equipment

                MOV     BYTE PTR [VGA_LINES],LINES400

;----------------------------------------------------------------------
; If ROW = 25, no additional work is required.
;----------------------------------------------------------------------
                CMP     DL,25
                JNE     W_6A

                CALL    SET_MODE
                JMP     SHORT W_EXIT
W_6A:
;----------------------------------------------------------------------
; ROWS <> 25 is only for:
; 1. An EGA adapter + EGA color monitor.
; 2. A VGA adapter + color monitor.
; 3. A VGA adapter + mono monitor when it is the only adapter installed.
;
; Determine the video hardware installed.
;----------------------------------------------------------------------
                CMP     WORD PTR [VID_ACT],(EGA_MON SHL 8) + EGA
                JE      W_9

                CMP     BYTE PTR [VID_ACT_ADAP],VGA
                JNE     W_ERR

                CMP     BYTE PTR [VID_ACT_MON],PS2_CO
                JE      W_7

                CMP     WORD PTR [VID_PAS_ADAP],0
                JNE     W_ERR
W_7:
;----------------------------------------------------------------------
; VGA requires setting the number of scan lines before loading the
; 8-line font:
;  AL = 1, 350 scan lines for 43 lines (350/8 = 43)
;  AL = 2, 400 scan lines for 50 lines (400/8 = 50)
; Note: the scan line change takes effect on the NEXT mode change.
;----------------------------------------------------------------------
                CMP     DL,43           ;Rows
                JNE     W_10

                MOV     BYTE PTR [VGA_LINES],LINES350

                JMP     SHORT W_10
;----------------------------------------------------------------------
; EGA options.
;----------------------------------------------------------------------
W_9:
                CMP     DL,43                   ;Only EGA option.
                JNE     W_ERR
;----------------------------------------------------------------------
; Change the video mode after setting the scan lines for the VGA but
; before loading the new font for EGA or VGA.
;----------------------------------------------------------------------
W_10:
                CALL    SET_MODE
;----------------------------------------------------------------------
; Now load the correct font. A different call is used to accomodate
; Screen 9 Width 80,43.
;----------------------------------------------------------------------
                CMP     AL,10H
                MOV     AX,1123H        ;Load graphics font
                MOV     BL,3            ; for 43 lines
                JE      W_11

                MOV     AX,1112H        ;Load 8x8 ROM text set
                MOV     BL,0            ; into block 0
W_11:
                INT     10H
;----------------------------------------------------------------------
; Fix up cursor on EGA only.
;----------------------------------------------------------------------
                CMP     BYTE PTR [VID_ACT_ADAP],EGA
                JNE     W_EXIT

                XOR     AX,AX
                MOV     ES,AX
    ASSUME  ES:NOTHING
                MOV     DX,WORD PTR ES:[463H]   ;Get CRTC address (3D4)
                MOV     AX,060AH

                OUT     DX,AX
                MOV     AX,0BH
                OUT     DX,AX
;----------------------------------------------------------------------
; Exit the procedure.
;----------------------------------------------------------------------
W_EXIT:
                POP     SI          ;Restore registers
                POP     BP          ;Erase stack frame
                RET     2 * 2

B$WIDT          ENDP

;======================================================================
;
;----------------------------------------------------------------------
SET_MODE    PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                CMP     BYTE PTR [VID_ACT_ADAP],VGA
                JNE     SM_EXIT

                PUSH    AX

                MOV     AH,12H
                MOV     AL,BYTE PTR [VGA_LINES]
                MOV     BL,30H                  ;Set scan lines fn
                INT     10H

                POP     AX
SM_EXIT:
                XOR     AH,AH                   ;Set video mode fn
                INT     10H
                RET

SET_MODE        ENDP

CSEG            ENDS
                END
