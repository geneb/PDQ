; R$VIDEO.ASM
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 9/16/89       .000    Split.
;               .001    Add reg saves.
; 11/10/89      .002    Update comments.
; 11/25/89      .003    Rewrite and include Herc detection.
; 11/26/89              Remove bad comments, add test equates. Fix SHL.
; 12/28/89      .004    Fix PS2 active/passive swap.
; 1/8/90        .005    Unified include file.
;----------------------------------------------------------------------
PUBLIC  GET_VIDEO       ;NEAR PROC
PUBLIC  VID_ACT         ;WORD
PUBLIC  VID_ACT_ADAP    ;BYTE
PUBLIC  VID_ACT_MON     ;BYTE

PUBLIC  VID_PAS         ;WORD
PUBLIC  VID_PAS_ADAP    ;BYTE
PUBLIC  VID_PAS_MON     ;BYTE

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU

PS2_TABLE       DB      0,0             ;0 None installed
                DB      MDA,MDA_MON     ;1
                DB      CGA,CGA_MON     ;2
                DB      0,0             ;3 Reserved
                DB      EGA,EGA_MON     ;4
                DB      EGA,MDA_MON     ;5
                DB      0,0     ;6 PGA
                DB      VGA,PS2_BW      ;7
                DB      VGA,PS2_CO      ;8
                DB      0,0             ;9 Reserved
                DB      MCGA,EGA_MON    ;A Not in IBM docs
                DB      MCGA,PS2_BW     ;B
                DB      MCGA,PS2_CO     ;C
HIGHEST_TYPE    EQU 0CH

DSEG            ENDS
;----------------------------------------------------------------------
; Do not rearrange order of data elements.
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'

VID_ACT         LABEL   WORD
VID_ACT_ADAP    DB      1 DUP(?)
VID_ACT_MON     DB      1 DUP(?)

VID_PAS         LABEL   WORD
VID_PAS_ADAP    DB      1 DUP(?)
VID_PAS_MON     DB      1 DUP(?)

VID_TEST        DB      1 DUP(?)
MDA_TEST        EQU     1
CGA_TEST        EQU     2
EGA_TEST        EQU     4

USEG            ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG
;======================================================================
; GET_VIDEO (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Determine the adapter type and type of connected display in the video
;    subsystem.
; 2. Returns the video status at the time called.
; 3. Most of the video detection logic for these routines has been
;    borrowed from the excellent book "Programmer's Guide to PC & PS/2
;    Video Systems" by Richard Wilton.  1987, Microsoft Press.
;----------------------------------------------------------------------
; Entry: none
; Exit:
;  The currently active video adapter is returned in [VID_ACT_ADAP].
;  If present, the currently inactive adapter is returned in [VID_PAS_ADAP].
;  The active display is returned in [VID_ACT_MON]
;  The inactive display is returned in [VID_PAS_MON]
;  Encoding is in file R$VIDEO.EQU.
;----------------------------------------------------------------------
; Changes: None
;----------------------------------------------------------------------
GET_VIDEO       PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    AX          ;Save used registers
                PUSH    BX
                PUSH    CX
                PUSH    DX
                PUSH    BP              ;Some videos destroy BP
                PUSH    ES
;----------------------------------------------------------------------
; Initialize return variables.
;----------------------------------------------------------------------
                XOR     AX,AX           ;AX = 0
                MOV     WORD PTR [VID_ACT],AX
                MOV     WORD PTR [VID_PAS],AX

                MOV     BYTE PTR [VID_TEST],MDA_TEST+CGA_TEST+EGA_TEST
;----------------------------------------------------------------------
; Routines are now called to identify the equipment installed.  The PS/2
; (or VGA adapter) BIOS returns information on both adapters if present.
;----------------------------------------------------------------------
                CALL    FIND_PS2
;----------------------------------------------------------------------
; Test for an EGA BIOS.  If present, will return info on the display
; attached to the EGA.  Details on a color system are returned in the
; active area, monochrome in the passive, even if that's not correct,
; and it gets straightened out later.
;----------------------------------------------------------------------
                TEST    BYTE PTR [VID_TEST],EGA_TEST
                JZ      GV_1

                CALL    FIND_EGA
;----------------------------------------------------------------------
; If no color system has been detected so far, test for a CGA.
;----------------------------------------------------------------------
GV_1:
                TEST    BYTE PTR [VID_TEST],CGA_TEST
                JZ      GV_2

                CALL    FIND_CGA
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
GV_2:
                TEST    BYTE PTR [VID_TEST],MDA_TEST
                JZ      GV_3

                CALL    FIND_MDA
;----------------------------------------------------------------------
; Now adjust the active display if needed.  Except for PS/2, assumed
; color system was active, mono was passive.
;----------------------------------------------------------------------
GV_3:
                CMP     BYTE PTR [VID_TEST],0
                JE      GV_EXIT

                XOR     AX,AX                   ;Point ES to low memory
                MOV     ES,AX
        ASSUME  ES:NOTHING

                CMP     WORD PTR ES:[463H],3D4H ;Check for active CRTC
                JE      GV_EXIT

                XCHG    AX,WORD PTR [VID_ACT]   ;Swap
                XCHG    AX,WORD PTR [VID_PAS]
                XCHG    AX,WORD PTR [VID_ACT]
GV_EXIT:
                POP     ES
                POP     BP
                POP     DX
                POP     CX
                POP     BX
                POP     AX
                RET

GET_VIDEO       ENDP

;======================================================================
; FIND_PS2 (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Works for IBM PS/2 line or VGA adapters by using a BIOS function.
;----------------------------------------------------------------------
FIND_PS2        PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
; The VGA returns a signature if it is present.
;----------------------------------------------------------------------
                MOV     AX,1A00H                ;Read display combo code
                INT     10H                     ; Thru BIOS

                CMP     AL,1AH                  ;AL = 1Ah if PS2 or VGA
                JNE     PS2_EXIT
;----------------------------------------------------------------------
; The function returns BL = code for active display, BH = code for
; inactive display.
; Put the color system in CX and the mono in DX.
;----------------------------------------------------------------------
PS2_1:
                PUSH    BX                      ;Save info from function

                XOR     CX,CX                   ;Save results in regs
                XOR     DX,DX

                CMP     BH,HIGHEST_TYPE         ;If inactive unknown, skip
                JA      PS2_2

                XCHG    BL,BH                   ;Convert byte to word
                XOR     BH,BH

                ADD     BX,BX                   ;Offset * 2 for table

                MOV     DX,WORD PTR [PS2_TABLE][BX]     ;Assume mono
;----------------------------------------------------------------------
; Decode active video system.
;----------------------------------------------------------------------
PS2_2:
                POP     BX                      ;Get active system
                XOR     BH,BH                   ; in BX

                ADD     BX,BX                   ;Offset * 2 for table

                MOV     AX,WORD PTR [PS2_TABLE][BX]     ;Retrieve
;----------------------------------------------------------------------
; If a monochrome monitor was detected, we still have to perform a test
; for the herc.
;----------------------------------------------------------------------
                MOV     BYTE PTR [VID_TEST],MDA

                CMP     AL,MDA
                JE      PS2_4

                CMP     DL,MDA
                JE      PS2_4

                MOV     BYTE PTR [VID_TEST],0
;----------------------------------------------------------------------
; Always put color in the active word and mono in the passive.
;----------------------------------------------------------------------
PS2_4:
                CMP     AH,MDA_MON      ;If mono in DX, skip
                JNE     PS2_5

                XCHG    AX,DX
PS2_5:
                MOV     WORD PTR [VID_ACT],AX
                MOV     WORD PTR [VID_PAS],DX
PS2_EXIT:
                RET

FIND_PS2        ENDP

;======================================================================
; FIND_EGA (internal)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Works by using and EGA BIOS function not present in CGA or MDA.
;----------------------------------------------------------------------
FIND_EGA        PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

;----------------------------------------------------------------------
; Like the VGA, the EGA also has a distinctive signature.  If an EGA is
; present, BL will be changed and CL will contain the switch settings.
;----------------------------------------------------------------------
                MOV     AH,12H                  ;Alternate select
                MOV     BL,10H                  ;Return EGA info
                INT     10H

                CMP     BL,10H                  ;Unchanged if not present
                JE      EGA_EXIT
;----------------------------------------------------------------------
; An EGA adapter is present.  CL contains the switch settings from the 
; rear of the card that indicate what display is attached.
;
; 0000,0001,0110,0111 = Color Graphics Display
; 0010,0011,1000,1001 = Enhanced Graphics Display
; 0100,0101,1010,1011 = Monochrome Display
;
; Shift the switches right one bit to eliminate redundancy.
;----------------------------------------------------------------------
                MOV     AH,EGA          ;Assume EGA
                MOV     AL,CGA_MON      ; and CGA monitor

                SHR     CL,1            ;Divide
                CMP     CL,3            ;0-2 are okay
                JB      EGA_0

                SUB     CL,3            ;Convert to 0-2 values
EGA_0:
                CMP     CL,1            ;EGA if equal
                JB      EGA_1           ;CGA if below
                JA      EGA_2           ;MDA if above
;----------------------------------------------------------------------
; EGA is installed as a color subsystem.
;----------------------------------------------------------------------
                MOV     AL,EGA_MON              ;Has EGA monitor
EGA_1:
                AND     BYTE PTR [VID_TEST],NOT CGA_TEST ;Don't look for CGA
                MOV     WORD PTR [VID_ACT],AX   ;Set as active monitor
                JMP     SHORT EGA_EXIT
;----------------------------------------------------------------------
; EGA is installed as a monochrome subsystem.
;----------------------------------------------------------------------
EGA_2:
                MOV     AL,MDA_MON              ;Has mono monitor
                AND     BYTE PTR [VID_TEST],NOT MDA_TEST
                MOV     WORD PTR [VID_PAS],AX   ;Set as passive monitor
EGA_EXIT:
                RET

FIND_EGA        ENDP

;=====================================================================
; FIND_CGA
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Works by looking for the CGA's CRTC.
; 2. If found, place in active slot and fix later if needed.
;----------------------------------------------------------------------
FIND_CGA        PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                MOV     DX,3D4H         ;Color CRTC address
                CALL    CRTC_TEST
                JC      CGA_EXIT

                MOV     WORD PTR [VID_ACT],(CGA_MON SHL 8) + CGA
CGA_EXIT:
                RET

FIND_CGA        ENDP

;=====================================================================
; FIND_MDA
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Works by looking for the MDA's CRTC.
; 2. If found, place in passive slot and fix later if needed.
; 3. If found, identify Hercules by monitoring bit 7 of the CRT status
;    byte which changes for Hercs but not for MDAs.
; 4. Herc adapters are differentiated by bits 4-6 of the CRT status value.
;    000 = HGC, 001 = HGC+, 101 = InColor.
;----------------------------------------------------------------------
FIND_MDA        PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                MOV     DX,3B4H
                CALL    CRTC_TEST
                JC      MDA_EXIT
;----------------------------------------------------------------------
; Check status port.
;----------------------------------------------------------------------
                MOV     DL,0BAH         ;Status port
                IN      AL,DX
                AND     AL,80H
                MOV     AH,AL           ;Save bit 7 in AH

                MOV     CX,8000H        ;Test 32768 times
MDA_1:
                IN      AL,DX
                AND     AL,80H          ;Isolate bit 7
                CMP     AH,AL           ;Exit if changed
                LOOPE   MDA_1
                JNE     MDA_2
;----------------------------------------------------------------------
; Bit 7 didn't change, so system is MDA.
;----------------------------------------------------------------------
                MOV     BX,(MDA_MON SHL 8) + MDA
                JMP     SHORT MDA_3
;----------------------------------------------------------------------
; Identify type of Herc card.
;----------------------------------------------------------------------
MDA_2:
                IN      AL,DX
                MOV     DL,AL

                MOV     BX,(MDA_MON SHL 8) + HGC

                AND     DL,70H          ;Get bits 4-6
                JZ      MDA_3

                MOV     BX,(MDA_MON SHL 8) + HGCPLUS
                AND     DL,10H
                JZ      MDA_3

                MOV     WORD PTR [VID_ACT],(EGA_MON SHL 8) + INCOLOR
                JMP     SHORT MDA_EXIT
MDA_3:
                MOV     WORD PTR [VID_PAS],BX
MDA_EXIT:
                RET

FIND_MDA        ENDP

;======================================================================
; CRTC_TEST
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; Enter
;   DX = CRTC address to test
; Exit
;   NC = CRTC found
;   CY = CRTC not found
;----------------------------------------------------------------------
CRTC_TEST       PROC    NEAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                MOV     AL,0FH
                OUT     DX,AL
                INC     DX

                IN      AL,DX
                MOV     AH,AL
                MOV     AL,66H
                OUT     DX,AL

                JMP     SHORT $+2

                IN      AL,DX
                XCHG    AH,AL
                OUT     DX,AL

                CMP     AH,66H
                JE      CRTC_1

                STC                     ;No CRTC found
                JMP     SHORT CRTC_EXIT
CRTC_1:
                CLC                     ;CRTC found
CRTC_EXIT:
                RET

CRTC_TEST       ENDP

CSEG            ENDS
                END
