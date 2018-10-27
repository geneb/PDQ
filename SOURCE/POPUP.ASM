;======================================================================
; POPUP.ASM
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/9/89    .000    Modify old routine and blend _TSR.
;           .001    Add hotkey detection.
; 7/11/89   .002    Make 9h alert only.  Popup on 8,28.
;           .003    Alpha version.
; 7/13/89   .004    Cull code.  Add STI before RET 2.  Fix INTBUSY test.
;                   Revise ASSUMEs.
; 7/14/89   .005    Add PSP swap, DTA save.
; 7/17/89   .006    Add error return.  (Still Crashes QB)
;           .007    Restore string after search.  Fix INT_8 reg balance.
;                   Force REQUEST flag OFF on popup.  (Okay in QB)
; 7/23/89   .008    Use standard routine to check install.
;           .009    Add simplified deinstall.  (not finished)
; 8/2/89    .010    Update args/rets from other procs.
;                   Make POPUP recognize resident flag.
;                   Use TsrFileOn/Off.
;           .011    Use ResetKeyboard proc.
; 8/5/89    .012    Remove unused error messages.  Change Int 28h routine
;                   to first call old int, then popup, then iret in prep
;                   for uninstall.
;           .013    Fill in PopDeinstall.  Add CSEG assume.
; 8/9/89    .014    Clean up deinstall.
; 8/13/89   .015    Data addressing problem. (8->66)
;           .016    Arg problems calling Restore_int. Clean stack. (8->66)
;           .017    Fix restore_int.  Change 66 back to 8.
;           .018    Make data uninitialized.
;           .019    Change use of res flag.  Save current PID.
; 9/9/89    .020    Update doc, segs.
; 9/14/89   .021    Update to set _RESIDENT flag.
; 9/25/89   .022    Move externs, add stack seg decl.
; 10/16/89  .023    Add key-wait exemption.
; 10/21/89  .024    Change MOV AX,CS to MOV AX,DS after label RI_3:
; 11/5/89   .025    Fix INT28 ISR.
; 1/8/90    .026    Unified include file.
; 2/27/90   .027    Prevent multiple stack swaps.
; 3/1/90    .028    Stack swap timing.
; 5/28/90   .029    Add support for multiple triggers. PARTIAL
; 6/21/90   .030    Fix DOS Int. 50h/51h Bug
; 6/21/90   .031    Finish multiple triggers.
; 6/23/90   .032    Set correct ticks in poprequest.
; 6/23/90   .032    Set correct ticks in poprequest.
; 6/27/90   .033    Add indirection to set PopRequest Flag = TRUE (Ethan)
;                   Also added CS: overrides
; 7/3/90    .034    Queue non-keyboard requests; fix PopRequest
; 10-26-90  .035    Change AL,10H to AH,10H in Int 16H handler (Ethan)
; 5/22/91   .036    Activate critical error detection and avoidance.
; 8/6/91    .037    Change timing of request cancel in 8 & 28.
;                   Remove int 28 generation in int 16 routine.
; 8/17/91   .038    Split off deinstall.
;           .039    Split out interrupt handlers, PopRequest, core.
; 9/17/91   .040    Modify for swapping
; 10/10/91  .041    Further mods.
;----------------------------------------------------------------------
PUBLIC  PopUpHere       ;PDQ
PUBLIC  PopDown         ;PDQ
PUBLIC  R$Popup         ;Internal
PUBLIC  SET_INT         ;Internal
PUBLIC  R$POPUPHERE$1   ;Patch point

;======================================================================
; Externals.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

EXTRN   TsrInstalled:FAR    ;In TSRINST.ASM
EXTRN   TsrFileOn:FAR       ;In TSRFILE.ASM
EXTRN   TsrFileOff:FAR      ;In TSRFILE.ASM
EXTRN   R$GETPSP:NEAR       ;In R$PSP.ASM

CSEG        ENDS

;======================================================================
; Externals.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'

EXTRN   INT_8:FAR       ;In R$CORE.ASM
EXTRN   INT_9:FAR
EXTRN   INT_10:FAR
EXTRN   INT_13:FAR
EXTRN   INT_14:FAR
EXTRN   INT_16:FAR
EXTRN   INT_17:FAR
EXTRN   INT_21:FAR
EXTRN   INT_25:FAR
EXTRN   INT_26:FAR
EXTRN   INT_28:FAR

EXTRN   pOLDINT8:DWORD      ;In R$CORE.ASM
EXTRN   pOLDINT9:DWORD
EXTRN   pOLDINT10:DWORD
EXTRN   pOLDINT13:DWORD
EXTRN   pOLDINT14:DWORD
EXTRN   pOLDINT16:DWORD
EXTRN   pOLDINT17:DWORD
EXTRN   pOLDINT21:DWORD
EXTRN   pOLDINT25:DWORD
EXTRN   pOLDINT26:DWORD
EXTRN   pOLDINT28:DWORD

EXTRN   REQ_FLAG_PTR:WORD   ;In R$CORE.ASM
EXTRN   HOTKEY:BYTE
EXTRN   SHIFTMASK:BYTE

EXTRN   pDOSCRIT:WORD       ;In R$CORE.ASM
EXTRN   pDOSBUSY:WORD
EXTRN   pDOSSEG:WORD

RLHSEG      ENDS

;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU

EXTRN   _RESIDENT:WORD          ;In PDQDATA.ASM
EXTRN   _SPSAVE:WORD            ;In PDQDATA.ASM
EXTRN   _SWAPPER:WORD           ;In PDQDATA.ASM
EXTRN   P$DOSVER:WORD           ;In PDQDATA.ASM
EXTRN   P$PDQERR:WORD           ;In ERRDATA.ASM

;----------------------------------------------------------------------
; Result returned in P$PDQErr.
;----------------------------------------------------------------------
INSTALL_SUCCESS         EQU     0
ALREADY_INSTALLED       EQU     111
ALREADY_CALLED          EQU     112

DSEG            ENDS

;======================================================================
; Uninitialized data.
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'

EXTRN   R$DOSCRIT:DWORD     ;In PDQ.ASM

USEG            ENDS

;======================================================================
; Reference the stack so the stack frame can be loaded.
;----------------------------------------------------------------------
PDQ_STACK       SEGMENT PARA    STACK   'STACK'

EXTRN   PDQ_STACK_HEAD:NEAR     ;In PDQ.ASM

PDQ_STACK       ENDS

;======================================================================
; Code to install and service interrupt procedures.
; 1. This data MUST stay in the code segment. Don't move it.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;----------------------------------------------------------------------
; Local data needed when DGROUP is not accessible.
;----------------------------------------------------------------------
pPDQPROC        DD      0
OLDSS           DW      0
OLDSP           DW      0

;======================================================================
; PopUpHere (PDQ)
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. A simplified TSR control system.  Applications can pop up on a hotkey,
;    perform a function, then exit.
; 2. Sorry, no DOS functions below 0DH can be used.  Make sure the routines
;    you use in the TSR portion of the code are marked TSR-compatible in
;    the manual.
; 3. See the other TSR routines for filters and system-level functions.
; 4. May only be called once.  Further calls are ignored.
; 5. ID string must be at least 8 chars.
; 6. Fails if program is already TSR.
;----------------------------------------------------------------------
; PopUpHere doesn't know where the interrupt routines that it is linking
;   to are located. They could be in R$SWAP or R$NOSWAP.
;----------------------------------------------------------------------
; Usage:
;       CALL PopUpHere(HotKey%,ID$)
; where
;       HotKey = 256 * ShiftMask + ScanCode
;       ID$ = Unique ident string
;----------------------------------------------------------------------
; 7/17/89   Put return code in P$PDQErr.
; 8/2/89    Different parameters from TsrInstalled
; 8/13/89   Update overrides.
; 9/17/91   Update for swapping.
;----------------------------------------------------------------------
PopUpHere       PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP
                PUSH    SI                      ;Save used registers
                PUSH    DI
;----------------------------------------------------------------------
; Check if already installed.
;----------------------------------------------------------------------
                MOV     SI,RLHSEG
                MOV     ES,SI
        ASSUME  ES:RLHSEG

                CMP     WORD PTR ES:[pOLDINT21][2],-1 ;If -1, not installed
                JE      HK_0

                MOV     WORD PTR [P$PDQErr],ALREADY_CALLED
                JMP     SHORT HK_EXIT
HK_0:
                PUSH    WORD PTR [BP+6]
                CALL    TsrInstalled

                MOV     WORD PTR [P$PDQErr],ALREADY_INSTALLED
                OR      AX,AX                   ;AX != 0 means a copy found
                JZ      HK_1
HK_EXIT:
                POP     DI                      ;Restore registers
                POP     SI
                POP     BP                      ;Remove stack frame
                RET     4                       ;Discard parameters
;----------------------------------------------------------------------
; Install can proceed.  Save hotkey and shift mask.
;----------------------------------------------------------------------
        ASSUME  CS:CSEG, DS:DGROUP, ES:RLHSEG, SS:DGROUP
HK_1:
                MOV     BX,WORD PTR [BP+8]      ;Get both and save them
                MOV     BX,WORD PTR [BX]
                MOV     BYTE PTR ES:[HOTKEY],BL
                MOV     BYTE PTR ES:[SHIFTMASK],BH
;----------------------------------------------------------------------
; Save the address of the PDQ routine that gets control when popping up.
;----------------------------------------------------------------------
                MOV     AX,WORD PTR [BP+4]      ;CS of BASIC int handler
                MOV     WORD PTR CS:[pPDQPROC][2],AX
                MOV     AX,WORD PTR [BP+2]      ;IP of instruction after CALL
                ADD     AX,3                    ; Skip GOTO
                MOV     WORD PTR CS:[pPDQPROC][0],AX
;----------------------------------------------------------------------
; VERY IMPORTANT: When DS=ES, all references to ES-relative data
; won't have an override, but they still address RLHSEG.
;----------------------------------------------------------------------
                PUSH    ES                      ;Make my life easier
                POP     DS                      ; by addressing same segment
        ASSUME  DS:RLHSEG
;----------------------------------------------------------------------
; Get a pointer to the DOS Busy Flag. Location is returned in ES:BX.
; Copy the DOS Critical Int Flag. Segment assumed to be the same as
; DOS Busy.
;----------------------------------------------------------------------
                MOV     AH,34H                  ;Get Interrupt Flag address
                INT     21H
        ASSUME  ES:NOTHING

                MOV     WORD PTR [pDOSBUSY],BX          ;offset
                MOV     WORD PTR [pDOSSEG],ES           ;segment

                MOV     BX,WORD PTR SS:[R$DOSCRIT][0]   ;offset
                MOV     WORD PTR [pDOSCRIT],BX
;----------------------------------------------------------------------
; Hook the keyboard interrupt 9h for the hot-key detection routine.
; Hook other interrupts to set busy flags.
; DS:DI points to DWORD destination for old address.
; DS:DX points to new interrupt address.  AX destroyed.
;----------------------------------------------------------------------
                MOV     AL,8H
                MOV     DI,OFFSET RLHSEG:pOLDINT8
                MOV     DX,OFFSET RLHSEG:INT_8
                CALL    SET_INT
    ASSUME  ES:NOTHING

                MOV     AL,10H
                MOV     DI,OFFSET RLHSEG:pOLDINT10
                MOV     DX,OFFSET RLHSEG:INT_10
                CALL    SET_INT

                MOV     AL,13H
                MOV     DI,OFFSET RLHSEG:pOLDINT13
                MOV     DX,OFFSET RLHSEG:INT_13
                CALL    SET_INT

                MOV     AL,14H
                MOV     DI,OFFSET RLHSEG:pOLDINT14
                MOV     DX,OFFSET RLHSEG:INT_14
                CALL    SET_INT

                MOV     AL,16H
                MOV     DI,OFFSET RLHSEG:pOLDINT16
                MOV     DX,OFFSET RLHSEG:INT_16
                CALL    SET_INT

                MOV     AL,17H
                MOV     DI,OFFSET RLHSEG:pOLDINT17
                MOV     DX,OFFSET RLHSEG:INT_17
                CALL    SET_INT

                MOV     AL,21H
                MOV     DI,OFFSET RLHSEG:pOLDINT21
                MOV     DX,OFFSET RLHSEG:INT_21
                CALL    SET_INT

                MOV     AL,25H
                MOV     DI,OFFSET RLHSEG:pOLDINT25
                MOV     DX,OFFSET RLHSEG:INT_25
                CALL    SET_INT

                MOV     AL,26H
                MOV     DI,OFFSET RLHSEG:pOLDINT26
                MOV     DX,OFFSET RLHSEG:INT_26
                CALL    SET_INT

                MOV     AL,28H
                MOV     DI,OFFSET RLHSEG:pOLDINT28
                MOV     DX,OFFSET RLHSEG:INT_28
                CALL    SET_INT

                MOV     AL,9
                MOV     DI,OFFSET RLHSEG:pOLDINT9
                MOV     DX,OFFSET RLHSEG:INT_9
                CALL    SET_INT
;----------------------------------------------------------------------
; If swapping is being used, this gets patched to a near call to hook
; in the Int AAh intercept.
;----------------------------------------------------------------------
        DB  3 DUP (90h)
R$POPUPHERE$1   LABEL   BYTE
;----------------------------------------------------------------------
; Return to PDQ.
;----------------------------------------------------------------------
                PUSH    SS                      ;Restore DS
                POP     DS
        ASSUME  DS:DGROUP

                MOV     WORD PTR [P$PDQErr],INSTALL_SUCCESS
                JMP     HK_EXIT

PopUpHere       ENDP

;======================================================================
; POPUP (internal)
; PopDown (PDQ)
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Set the environment for the PDQ program and transfer control.
;----------------------------------------------------------------------
; 7/14/89   (My birthday) Save/swap PID,DTA.
; 8/2/89    PID, DTA in external proc.  Use _RESIDENT flag.
; 8/18/91   Add R$POPUP alias for PUBLIC access.
; 9/17/91   Modify for swapping. Make FAR.
;----------------------------------------------------------------------
R$POPUP     PROC    FAR
        ASSUME  CS:CSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                STI                                 ;Interrupts on
                PUSHF                               ;Save all registers
                PUSH    AX
                PUSH    BX
                PUSH    CX
                PUSH    DX
                PUSH    BP
                PUSH    SI
                PUSH    DI
                PUSH    DS
                PUSH    ES
;----------------------------------------------------------------------
; Set registers for PDQ operation.
;----------------------------------------------------------------------
                MOV     AX,DGROUP               ;BASIC data segment
                MOV     DS,AX                   ; in DS
        ASSUME  DS:DGROUP
;----------------------------------------------------------------------
; Can only pop up if we've gone resident.
;----------------------------------------------------------------------
                CMP     WORD PTR [_RESIDENT],0 ;0 if not resident
                JE      PD_1
;----------------------------------------------------------------------
; Program is resident.  Stack may have already been swapped by a
; discrete interrupt handler.  If that's the case don't do it again.
;----------------------------------------------------------------------
                CLI                                     ;Swap stacks
                CMP     WORD PTR [_SWAPPER], 0          ;0 = not swapped
                JNE     PU_1
;----------------------------------------------------------------------
; Save the old SS:SP and change to the P.D.Q. stack.  Set a flag to
; indicate to other interrupts that the stack has already been swapped.
; A special code is used so that the code can determine which interrupt
; has to restore the original stack on exit.
;----------------------------------------------------------------------
                MOV     WORD PTR CS:[OLDSS],SS          ;Save current SS:SP
                MOV     WORD PTR CS:[OLDSP],SP          ; for stack switch

                MOV     SS,AX
        ASSUME  SS:DGROUP
                MOV     SP,WORD PTR [_SPSAVE]           ;Set offset
                MOV     WORD PTR [_SWAPPER],3FFFH       ;Say it has control
                STI
;----------------------------------------------------------------------
; Make the PSP of the current process available.
;----------------------------------------------------------------------
                CALL    R$GETPSP
                MOV     WORD PTR [_RESIDENT],BX
;----------------------------------------------------------------------
; Set BP to proper value for stack frame in main program.
;----------------------------------------------------------------------
PU_1:
                STI
                MOV     BP,OFFSET DGROUP:PDQ_STACK_HEAD ;Set stack frame
;----------------------------------------------------------------------
; Get and save the current DTA address.  Save the old PSP.
; Make the PDQ program the active process.
;----------------------------------------------------------------------
                CALL    TsrFileOn
;----------------------------------------------------------------------
; Let the program know which request is being serviced.
;----------------------------------------------------------------------
                MOV     AX,RLHSEG
                MOV     ES,AX
        ASSUME  ES:RLHSEG

                CMP     WORD PTR ES:[REQ_FLAG_PTR],0
                JE      PU_2

                MOV     BX,WORD PTR ES:[REQ_FLAG_PTR];get address of the flag
                MOV     WORD PTR [BX],TRUE      ;assign Flag = -1
PU_2:
;----------------------------------------------------------------------
; Use a jump (instead of call) because PDQ returns by CALLing, not RETing.
;----------------------------------------------------------------------
                JMP     DWORD PTR CS:[pPDQPROC]
;----------------------------------------------------------------------
; Enter here by calling the PopDown routine from PDQ.
;----------------------------------------------------------------------
POPDOWN         PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                ADD     SP,4                    ;Discard return address
;----------------------------------------------------------------------
; Restore original DTA, PID.
;----------------------------------------------------------------------
                CALL    TsrFileOff
;----------------------------------------------------------------------
; If the _SWAPPER word contains the number of this interrupt then we're
; responsible for restoring the stack.
;----------------------------------------------------------------------
                CMP     WORD PTR [_SWAPPER],3FFFH   ;if we are stack manager
                JNE     PD_1

                CLI
                MOV     SS,WORD PTR CS:[OLDSS]  ;Restore old stack
        ASSUME  SS:NOTHING
                MOV     SP,WORD PTR CS:[OLDSP]
                STI

                MOV     WORD PTR [_SWAPPER],0
;----------------------------------------------------------------------
; Restore registers and return to foreground.
;----------------------------------------------------------------------
PD_1:
                POP     ES                      ;Restore registers
        ASSUME  ES:NOTHING
                POP     DS
        ASSUME  DS:NOTHING
                POP     DI
                POP     SI
                POP     BP
                POP     DX
                POP     CX
                POP     BX
                POP     AX
                POPF

POPDOWN         ENDP

                RET

R$POPUP     ENDP

;======================================================================
; SETINT (internal)
;   Copyright (c) 1989-1991 Crescent Software
;   Copyright (c) 1989-1991 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Get/Save/Set the interrupt vector.  AL contains vector number.
;----------------------------------------------------------------------
; Entry:
;       DS:DI -> DWORD destination for old address.
;       DS:DX -> new interrupt address.
;----------------------------------------------------------------------
; Changes: AX BX ES
;----------------------------------------------------------------------
SET_INT         PROC    NEAR
                ASSUME  CS:CSEG, DS:NOTHING, ES:NOTHING, SS:DGROUP

                PUSH    AX                      ;Save vector # in AL

                MOV     AH,35H                  ;Get address function
                INT     21H                     ;Thru DOS
        ASSUME  ES:NOTHING

                MOV     WORD PTR DS:[DI+0],BX      ;Save address in DS:DI
                MOV     WORD PTR DS:[DI+2],ES

                POP     AX                      ;Get AL back

                MOV     AH,25H                  ;Set new address to DS:DX
                INT     21H                     ;Thru DOS

                RET

SET_INT         ENDP

CSEG            ENDS
                END
