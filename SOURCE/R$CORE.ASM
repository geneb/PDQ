;======================================================================
; R$CORE.ASM
;  Copyright (c) 1989-1994 Crescent Software
;  Copyright (c) 1989-1994 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; STANDARD TSR RESTRICTIONS
; 1. You can't allocate memory once you are resident.
; 2. You can't use discrete interrupt handlers or PopRequest.
; 3. You shouldn't change interrupt vectors or other portions
;    of memory.
; 4. High memory that's linked into the allocation chain is okay, but
;    you can't load into unlinked high memory and expect this to work.
;----------------------------------------------------------------------
; 8/18/91       .000    Create from POPUP.037, combine ENDTSR.
; 9/2/91        .001    Redo Int8. Add indirection. Change segment
; 9/17/91       .002    Remove ENDTSR.
; 9/18/91       .003    Crossreference DGROUP/RLHSEG
;               .004    Trim data. Hook swapper.
; 9/21/91       .005    Add MCB table.
; 9/23/91       .006    Remove unreferenced data. Change labels.
; 10/4/91       .007    Bring ResetKeyboard internal
; 10/10/91      .008    Clean externals.
; 10/11/91      .009    Add deinstall flags.
; 10/13/91      .010    Rename R$SWAPIN to R$SWAP
; 10/15/91      .011    Move R$SWAP to avoid override.
;               .012    Add STACK segment.
; 3/5/92        .013    Redo Int 21 & 8. Eliminate lo fn bypass.
; 7/3/94        .014    Gut 21 to improve speed. Comment out unused
;                       code from 8. Remove Int 16h call from 9.
;======================================================================

;----------------------------------------------------------------------
; These are the old interrupt vectors. They're public to allow PopUpHere
; to save the old values and for deinstalling.
;----------------------------------------------------------------------
PUBLIC  pOLDINT8
PUBLIC  pOLDINT9
PUBLIC  pOLDINT10
PUBLIC  pOLDINT13
PUBLIC  pOLDINT14
PUBLIC  pOLDINT16
PUBLIC  pOLDINT17
PUBLIC  pOLDINT21
PUBLIC  pOLDINT25
PUBLIC  pOLDINT26
PUBLIC  pOLDINT28
;----------------------------------------------------------------------
; These are the offsets of the new interrupt handlers that are in this
; procedure. PopUpHere links them into the interrupt chain.
;----------------------------------------------------------------------
PUBLIC  INT_8
PUBLIC  INT_9
PUBLIC  INT_10
PUBLIC  INT_13
PUBLIC  INT_14
PUBLIC  INT_16
PUBLIC  INT_17
PUBLIC  INT_21
PUBLIC  INT_25
PUBLIC  INT_26
PUBLIC  INT_28
PUBLIC  R$IRET
;----------------------------------------------------------------------
; These are used by TsrInstalled() and DeinstallTSR().
;----------------------------------------------------------------------
PUBLIC  R$RLHSEG
PUBLIC  R$SWAP$1
;----------------------------------------------------------------------
; These items are initialized by other procs.
;----------------------------------------------------------------------
PUBLIC  pDOSSEG
PUBLIC  pDOSCRIT
PUBLIC  pDOSBUSY
PUBLIC  HOTKEY
PUBLIC  SHIFTMASK
;----------------------------------------------------------------------
; Miscellaneous.
;----------------------------------------------------------------------
PUBLIC  REQ_FLAG_PTR
PUBLIC  ACTIVE
PUBLIC  REQ_TIMER

PUBLIC  R$SWAPCODE
PUBLIC  R$SWAPFLAG
PUBLIC  R$REMOVEFLAG

;======================================================================
; Externals.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'

EXTRN   R$POPUP:FAR         ;In POPUP.ASM

CSEG        ENDS

;======================================================================
; This segment is declared initially in PDQ.ASM. Its attributes force
; it to be the last segment in the link order. It is used, therefore,
; to define the end of the program in memory.
;----------------------------------------------------------------------
PDQ_STACK       SEGMENT PARA    STACK   'STACK'
PDQ_STACK       ENDS

__TSR           SEGMENT PARA    PUBLIC  'STACK'
__TSR           ENDS

;======================================================================
; DSEG is initialized data and part of DGROUP.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG
DSEG            SEGMENT WORD    PUBLIC  'DATA'

INCLUDE R$PDQ.EQU               ;Standard includes
;----------------------------------------------------------------------
; TCONST tells how long the TSR should wait for a free moment before
; it pops up.
;----------------------------------------------------------------------
TCONST          EQU     1 * 18  ;Try for 1 second

R$RLHSEG    DW  RLHSEG          ;Allows foreign program to find

DSEG            ENDS

;======================================================================
; The combination of name and class force this code segment to be the
; first segment in memory when the program is linked with the correct
; stub file.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'
        ASSUME  CS:RLHSEG

;----------------------------------------------------------------------
; This data must always be resident with the core module.
; Some are intialized by other procs.
;----------------------------------------------------------------------
        EVEN
pDOSBUSY        DW      0   ;pDOSSEG:pDOSBUSY points to INDOS
pDOSCRIT        DW      0   ;pDOSSEG:pDOSBUSY points to CritErr Flag
pDOSSEG         DW      0   ;Common segment

HOTKEY          DB      0   ;The scan code for the hotkey
SHIFTMASK       DB      0   ;The shiftkeys for the hotkey

FLAG25          DW      0   ;Nonzero if inside int
FLAG26          DW      0   ;Nonzero if inside int

REQ_FLAG_PTR    DW      0   ;Value indicates who requested the popup
REQ_TIMER       DW      0   ;Nonzero indicates a request pending

R$SWAPCODE      DW      0   ;Command code passed to resident program

R$SWAPFLAG      DB      FALSE   ;True if swapping enabled
R$REMOVEFLAG    DB      FALSE   ;True if POPDOWN should remove from memory

ACTIVE          DB      FALSE   ;TRUE if a popup is initiated
LOFNFLAG        DB      FALSE   ;Allows popup inside DOS keyboard I/O
INT8_BUSY       DB      0
INTBUSY         DB      0       ;Nonzero if unpoppable

;======================================================================
; R$SWAP (internal)
;   Copyright (c) 1991-1994 Crescent Software
;   Copyright (c) 1991-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. If swapping is not enabled, this routine simply transfers control
;    to the normal popup code.
; 2. The FAR CALL to here puts the correct return address on the stack.
; 3. Note that at this point, NO REGISTERS HAVE BEEN SAVED.
;----------------------------------------------------------------------
; 9/17/91   Initial dummy routine.
;----------------------------------------------------------------------
R$SWAP      PROC    FAR
    ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

R$SWAP$1    LABEL   BYTE
        JMP R$POPUP         ;Far jump to CSEG

R$SWAP      ENDP

;======================================================================
; INT_8 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Hardware timer tick.  Used to service pop-up request. See also
;    INT_28.
; 2. Counts down when request is pending.
;----------------------------------------------------------------------
; 7/17/89       Fix push/pop stutter on DOSCRIT.
; 5/22/91       Check for critical error.
; 8/5/91        Cancel request AFTER calling old int 8.
;----------------------------------------------------------------------
INT_8           PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING
;----------------------------------------------------------------------
; Don't re-enter if this ISR is already active.
;----------------------------------------------------------------------
                CMP     BYTE PTR CS:[INT8_BUSY],0   ;If busy, quit
                JE      INT8_0
INT8_EXIT:
                JMPFAR
pOLDINT8        DD      -1
;----------------------------------------------------------------------
; Set the flag so we don't re-enter.
;----------------------------------------------------------------------
INT8_0:
                INC     BYTE PTR CS:[INT8_BUSY]     ;Don't re-enter

                CMP     WORD PTR CS:[REQ_TIMER],0   ;If no request, exit
                JE      INT8_4
;----------------------------------------------------------------------
; 1. If not active, continue to process request.
; 2. If currently active and the request is NOT from the keyboard, then
;    skip this timer tick, but don't cancel the request.
; 3. If currently active and the request is from the keyboard, cancel it.
;----------------------------------------------------------------------
                CMP     BYTE PTR CS:[ACTIVE],TRUE   ;If active
                JNE     INT8_1

                CMP     WORD PTR CS:[REQ_FLAG_PTR],0    ;from KBD
                JNE     INT8_4

                MOV     WORD PTR CS:[REQ_TIMER],0   ;Cancel request
                JMP     SHORT INT8_4
;----------------------------------------------------------------------
; Not currently active. Assess ability to pop up.
; If this tick interrupts a system function (interrupt), skip this tick.
;----------------------------------------------------------------------
INT8_1:
                CMP     BYTE PTR CS:[INTBUSY],0 ;Can't popup if any INT busy
                JNE     INT8_3
;----------------------------------------------------------------------
; No interrupts (except possibly 21h) busy. First, point DS:BX to DOS
; Critical Flag. If this is non-zero, we cannot pop up.
;----------------------------------------------------------------------
                PUSH    DS                      ;Save used registers
                PUSH    BX

                LDS     BX,DWORD PTR CS:[pDOSCRIT]
        ASSUME DS:NOTHING
                CMP     BYTE PTR DS:[BX],0      ;Non-zero = danger

                POP     BX                      ;Clean off registers
                POP     DS
        ASSUME DS:NOTHING
                JNE     INT8_3
;----------------------------------------------------------------------
; Not in a critical interrupt, now check if the DOS Busy Flag is set.
;----------------------------------------------------------------------
                PUSH    DS                      ;Save used registers
                PUSH    BX

                MOV     DS,WORD PTR CS:[pDOSSEG]
        ASSUME  DS:NOTHING
                MOV     BX,WORD PTR CS:[pDOSBUSY]

                CMP     BYTE PTR DS:[BX],1      ;Nonzero=busy

                POP     BX                      ;Clean off registers
                POP     DS
        ASSUME DS:NOTHING
;----------------------------------------------------------------------
; If DOS isn't busy, go ahead and pop up.
;----------------------------------------------------------------------
        JAE INT8_3  ;;; skip lo fn test

;----------------------------------------------------------------------
;       JB      INT8_2                  ;jump if DOSBUSY=0
;----------------------------------------------------------------------
; DOSBUSY flag was set. If >1, DOS is really busy, don't interrupt.
;----------------------------------------------------------------------
;             JA      INT8_3                  ;If DOSBUSY > 1, jump
;----------------------------------------------------------------------
; DOS is busy. If a low-number DOS 21h function, we can pop up.
;----------------------------------------------------------------------
;             CMP     CS:[LOFNFLAG],TRUE
;             JNE     INT8_3
;----------------------------------------------------------------------

;----------------------------------------------------------------------
; Okay to pop up. Service interrupt, then transfer control.
;----------------------------------------------------------------------
INT8_2:
                STI
                PUSHF                                ;Simulate INT

                CLI
                CALL    DWORD PTR CS:[pOLDINT8]      ;Service old interrupt

                CLI
                MOV     BYTE PTR CS:[ACTIVE],TRUE    ;Don't call again
                MOV     WORD PTR CS:[REQ_TIMER],0    ;Cancel the request
;----------------------------------------------------------------------
; If a normal TSR, this instruction will transfer control to the POPUP
; routine, which is always in memory. If swapping is enabled, this
; call transfers control to the routine that swaps the program into
; memory and then gives it control. When it finally comes back, it just
; IRETs to the original interrupt issuer.
;----------------------------------------------------------------------
                CALL    R$SWAP

                CLI
                MOV     BYTE PTR CS:[ACTIVE],FALSE  ;Ready once again
                DEC     BYTE PTR CS:[INT8_BUSY]
R$IRET:
                IRET                                ;Return to orginal INT
;----------------------------------------------------------------------
; Couldn't pop up this tick. Decrement counter. Transfer control to
; original interrupt handler.
;----------------------------------------------------------------------
INT8_3:
                DEC     WORD PTR CS:[REQ_TIMER]     ;Time runs out
INT8_4:
                CLI
                DEC     BYTE PTR CS:[INT8_BUSY]
                JMP     INT8_EXIT

INT_8           ENDP

;======================================================================
; INT_21 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. DOS Int 21h intercept.   Set flag while uninterruptable.
; 2. Keeps pop-up from taking control of the machine when doing so would
;    cause a crash.
;----------------------------------------------------------------------
; 7/9/89        Initial.
; 7/17/89       Modify flag save/restore.
;----------------------------------------------------------------------
INT_21          PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

;                PUSHF                  ;Save current flags
;                CMP     AH,0CH         ;DOS functions call under 0DH
;                JBE     INT21_2
;----------------------------------------------------------------------
; This is a high-number DOS function.
;----------------------------------------------------------------------
;INT21_1:
;                MOV     CS:[LOFNFLAG],FALSE
;                POPF

                JMPFAR                  ;Jump to original routine
pOLDINT21       DD      -1
;----------------------------------------------------------------------
; If this is function 0, simply continue.
;----------------------------------------------------------------------
;INT21_2:
;                CMP     AH,0
;                JE  INT21_1
;----------------------------------------------------------------------
; This is a low-number DOS function. Report this condition.
; 1. Refresh the flags
; 2. Call the old int - simulate an interrupt
; 3. Return and remove old flags
;----------------------------------------------------------------------
;                MOV     CS:[LOFNFLAG],TRUE
;
;               POPF                        ;Refresh flags
;               STI                         ;interrupts on
;
;               PUSHF
;               CALL    DWORD PTR CS:[pOLDINT21]    ;Simulate interrupt
;
;               MOV     CS:[LOFNFLAG],FALSE         ;Wipe out flags.
;
;               STI
;               RET     2                           ;discard old flags

INT_21          ENDP

;======================================================================
; INT_9 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. New Interrupt 9 routine.  Invoked each key-press.
; 2. Test to see if our key combination has been typed.
;----------------------------------------------------------------------
; 7/17/89       Stable.
;----------------------------------------------------------------------
INT_9           PROC    FAR
                ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                STI                             ;Allow interrupts
                PUSH    AX                      ;Save used register

                IN      AL,60H                  ;Get key scan code
                CMP     AL,BYTE PTR CS:[HOTKEY] ;Check if hot-key

                JNE     PROCESS_KEY             ;If not, continue on
;----------------------------------------------------------------------
;                MOV     AH,2                    ;Get shift status fn
;                INT     16H                     ;Thru BIOS
;----------------------------------------------------------------------
        PUSH    DS          ;Save register
        SUB AX,AX           ;Zero
        MOV DS,AX           ;Point to lomem
    ASSUME  DS:NOTHING
        MOV AL,DS:[417H]        ;Get shift status
        POP DS          ;Restore register
;----------------------------------------------------------------------
                AND     AL,0FH                  ;Test only for 'shift' keys
                CMP     AL,BYTE PTR CS:[SHIFTMASK] ;If they match
                JE      OUR_KEY                 ;then is our signal
PROCESS_KEY:
                POP     AX                      ;Restore register

                CLI
                JMPFAR
pOLDINT9        DD      -1
;----------------------------------------------------------------------
;  Reset the keyboard interrupt controller (forget the key stroke)
;----------------------------------------------------------------------
OUR_KEY:
                IN      AL,61H                  ;These instructions reset
                MOV     AH,AL                   ; the keyboard.
                OR      AL,80H
                OUT     61H,AL
                MOV     AL,AH
                JMP     SHORT $+2               ;I/O delay
                OUT     61H,AL
                CLI                             ;Disable interrupts and
                MOV     AL,20H                  ;reset the int controller
                OUT     20H,AL
                STI                             ;Allow interrupts

                MOV     WORD PTR CS:[REQ_TIMER],TCONST  ;Request popup
                SUB     AX,AX
                MOV     WORD PTR CS:[REQ_FLAG_PTR],AX   ;from Kbd
                MOV     WORD PTR CS:[R$SWAPCODE],AX     ;no code

                POP     AX                      ;Restore register
                IRET                            ;Go back where we came from

INT_9           ENDP

;======================================================================
; INT_10 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Monitor BIOS video interrupt.
;----------------------------------------------------------------------
INT_10          PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                PUSHF                           ;Preserve flags
                INC     BYTE PTR CS:[INTBUSY]   ;Say we're in INT

                CALLFAR                         ;Call the old int
pOLDINT10       DD      -1

                JMP     SHORT INT_EXIT

;======================================================================
; INT_13 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Monitor BIOS disk interrupt.
;----------------------------------------------------------------------
INT_13          PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                PUSHF
                INC     BYTE PTR CS:[INTBUSY]

                CALLFAR
pOLDINT13       DD      -1

                JMP     SHORT INT_EXIT

;======================================================================
; INT_14 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Monitor BIOS serial communications interrupt.
;----------------------------------------------------------------------
INT_14          PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                PUSHF
                INC     BYTE PTR CS:[INTBUSY]

                CALLFAR
pOLDINT14       DD      -1

                JMP     SHORT INT_EXIT

;======================================================================
; INT_17 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Monitor BIOS printer interrupt.
;----------------------------------------------------------------------
INT_17          PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                PUSHF
                INC     BYTE PTR CS:[INTBUSY]

                CALLFAR
pOLDINT17       DD      -1

INT_EXIT:
                PUSHF
                DEC     BYTE PTR CS:[INTBUSY]
                POPF
                STI
                RET     2

INT_17          ENDP
INT_14          ENDP
INT_13          ENDP
INT_10          ENDP

;======================================================================
; INT_16 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Monitor BIOS keyboard interrupt.
;----------------------------------------------------------------------
; Remove INT 28h generation. Causes problems when some higher DOS
; functions call BIOS keyboard input.
;----------------------------------------------------------------------
INT_16          PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                PUSHF                           ;Save entry flags with
                                                ; INTs disabled
                TEST    AH,0EFH                 ;11101111
                JNZ     INT16_2
INT16_1:
                STI                             ;Allow interrupts

                PUSH    AX                      ;Save original call

                INC     AH                      ;Change to 1 or 11h
                INC     BYTE PTR CS:[INTBUSY]   ;Don't interrupt

                PUSHF                           ;Simulate INT 16h

                CALLFAR
pOLDINT16       DD      -1

                PUSHF                           ;Save return flags
                DEC     BYTE PTR CS:[INTBUSY]   ;Remove restriction
                POPF                            ;Restore flags

                POP     AX                      ;Get original function
                JZ      INT16_1                 ;If key not ready, loop
INT16_2:
                CLI                             ;No interrupts
                INC     BYTE PTR CS:[INTBUSY]
                CALL    DWORD PTR CS:[pOLDINT16]

                PUSHF
                DEC     BYTE PTR CS:[INTBUSY]
                POPF

                STI
                RET     2

INT_16          ENDP

;======================================================================
; INT_25 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Monitor DOS read sector interrupt.
;----------------------------------------------------------------------
; 7/13/89       Add flag saving procedure.
; 7/17/89       Remove unbalanced push (temp code).
;----------------------------------------------------------------------
INT_25          PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                PUSHF
                INC     BYTE PTR CS:[INTBUSY]

                CALLFAR
pOLDINT25       DD      -1

                PUSHF
                POP     WORD PTR CS:[FLAG25]

                ADD     SP,2                    ;Remove flags we pushed
                DEC     BYTE PTR CS:[INTBUSY]   ; say we're not using Int

                PUSH    WORD PTR CS:[FLAG25]
                POPF

                RET                             ;Return, leave flags on stack

INT_25          ENDP

;======================================================================
; INT_26 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Monitor DOS write sector interrupt.
;----------------------------------------------------------------------
; 7/13/89       Add flag saving procedure.
;----------------------------------------------------------------------
INT_26          PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                PUSHF                           ;Push to simulate Int

                INC     BYTE PTR CS:[INTBUSY]   ;Say we're busy

                CALLFAR
pOLDINT26       DD      -1

                PUSHF                           ;Move flags
                POP     WORD PTR CS:[FLAG26]    ; to storage

                ADD     SP,2                    ;Remove flags we pushed
                DEC     BYTE PTR CS:[INTBUSY]   ; say we're not using Int

                PUSH    WORD PTR CS:[FLAG26]
                POPF

                RET                             ;Return, leave flags on stack

INT_26          ENDP

;======================================================================
; INT_28 (internal)
;   Copyright (c) 1989-1994 Crescent Software
;   Copyright (c) 1989-1994 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. DOS idle interrupt.  Gets control when it's okay to pop up.
;    This interrupt is issued by DOS while waiting for completion of a
;    character I/O function 1 - Ch.
; 2. DOS issues INT 28h only if a character I/O function has not yet
;    completed, but does not issue it if the critical error handler is
;    running.
; 3. On entry, all segment registers point to DOS. SS:SP points to the
;    top of the DOS I/O stack.
; 4. This handler cannot call functions 1 - Ch unless the critical
;    error flag is set to 1. Otherwise, DOS will crash.
;----------------------------------------------------------------------
; 7/17/89       Add request cancel on popup.
; 8/5/89        Change behavior to match INT_8.
; 11/5/89       Don't pop up if already active.
; 5/22/91       Check DOS critical error activity.
;----------------------------------------------------------------------
INT_28          PROC    FAR
        ASSUME  CS:RLHSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING
;----------------------------------------------------------------------
; If a request to pop up is not pending, jump directly to the old ISR.
;----------------------------------------------------------------------
                CMP     WORD PTR CS:[REQ_TIMER],0 ;Not 0 = popup
                JNE     INT28_2
INT28_1:
                JMPFAR
pOLDINT28       DD      -1
;----------------------------------------------------------------------
; If already active, ignore the request.
;----------------------------------------------------------------------
INT28_2:
                STI                             ;Allow interrupts
                CMP     BYTE PTR CS:[ACTIVE],TRUE
                JE      INT28_1
;----------------------------------------------------------------------
; If handling a critical error, don't pop up.
; (This code shouldn't be needed.)
;----------------------------------------------------------------------
                PUSH    DS                      ;Save used registers
                PUSH    BX

                LDS     BX,DWORD PTR CS:[pDOSCRIT]
        ASSUME DS:NOTHING
                CMP     BYTE PTR DS:[BX],0      ;Non-zero = danger

                POP     BX                      ;Clean off registers
                POP     DS
        ASSUME DS:NOTHING
                JNE     INT28_1
;----------------------------------------------------------------------
; Service interrupt, then pop up.
;----------------------------------------------------------------------
                PUSHF                               ;Service original ISR
                CALL    DWORD PTR CS:[pOLDINT28]

                CLI
                MOV     WORD PTR CS:[REQ_TIMER],0   ;Cancel the request
                STI

                MOV     BYTE PTR CS:[ACTIVE],TRUE   ;Don't call again
                CALL    R$SWAP
                MOV     BYTE PTR CS:[ACTIVE],FALSE

                IRET

INT_28          ENDP

RLHSEG          ENDS
                END
