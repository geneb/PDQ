; POINTINT.ASM
;  PointIntHere PDQ:FAR
;  IntEntry1    PDQ:FAR
;  IntEntry2    PDQ:FAR
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 7/29/89       .000    Split routine to TSR2.
; 7/30/89       .001    Add wait for res option.
;               .002    Fix SI ref in IE2.
; 8/1/89        .003    Have IntEntry1 set DS to DGROUP for var inits.
; 8/13/89       .004    Change use of res flag.  Save active PID on entry.
; 9/10/89       .005    Update doc, move extrn.
; 11/4/89       .006    Don't swap stacks if P.D.Q. program is non-TSR or
;                       if the P.D.Q. stack is already in use.
; 11/13/89      .007    Fix stack swap compare jump.
; 12/18/89      .008    Reduce byte count on stack math.
; 12/29/89      .009    Fix overwrite during stack swap.
; 1/8/90        .010    Unified include file.
; 3/1/90        .011    Stack swap timing.
; 6/21/90       .012    Fix 50h/51h DOS Bug.
; 8/5/90        .013    Don't get current PSP for DOS 2.x.
;----------------------------------------------------------------------
EXTRN   R$GETPSP:NEAR

PUBLIC  PointIntHere
PUBLIC  IntEntry1
PUBLIC  IntEntry2

;----------------------------------------------------------------------
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
DGROUP          GROUP   DSEG,USEG,PDQ_STACK

DSEG            SEGMENT WORD    PUBLIC  'DATA'
INCLUDE R$PDQ.EQU
EXTRN   P$DOSVER:WORD                   ;these are all in PDQDATA.ASM
EXTRN   _SPSAVE:WORD                    ;Used in IntEntry2
EXTRN   _RESIDENT:WORD
EXTRN   _SWAPPER:WORD
DSEG            ENDS
;----------------------------------------------------------------------
USEG            SEGMENT WORD    PUBLIC  'BSS'
USEG            ENDS
;----------------------------------------------------------------------
PDQ_STACK       SEGMENT PARA    STACK   'STACK'
EXTRN   PDQ_STACK_HEAD:NEAR             ;Used in IntEntry2
PDQ_STACK       ENDS

;----------------------------------------------------------------------
; Code segment.
;----------------------------------------------------------------------
CSEG            SEGMENT WORD    PUBLIC  'CODE'
;======================================================================
; PointIntHere (PDQ)
; Support routines for making BASIC routines memory resident.
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Save the current vector for the specified interrupt and point it to
;    a PDQ procedure.
; 2. This subroutine may be called as many times as needed to hook as many
;    interrupts as needed.  Programmer should ensure that each call is for
;    a different interrupt.  If not, the program will eventually crash.
; 3. Each interrupt must have a unique array of the proper length or the
;    program will crash.
; 4. Because the main section of PDQ code is not written to be re-entrant,
;    two ISRs that may be active at the same time should not call the same
;    subroutines or functions.  Do so at your own risk.
;----------------------------------------------------------------------
; Usage:
;       Registers.IntNum = interrupt number
;       CALL PointIntHere(Registers)
;----------------------------------------------------------------------
; 7/16/89       Revised to save new int vector to aid in deinstalling.
;----------------------------------------------------------------------
PointIntHere    PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:DGROUP

                PUSH    BP                      ;Create stack frame
                MOV     BP,SP
                PUSH    SI                      ;Save used registers
                PUSH    DS
;----------------------------------------------------------------------
; Retrieve passed pointer to struct.  Load in SI for base addressing.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BP+6]      ;Pointer to struct
;----------------------------------------------------------------------
; Get the current vector for the specifed interrupt.
;----------------------------------------------------------------------
                MOV     AH,35H                      ;Get interrupt address
                MOV     AL,BYTE PTR [STRUCT_INTNUM] ;Interrupt #
                INT     21H                         ;Returned in ES:BX
        ASSUME  ES:NOTHING

                MOV     WORD PTR [STRUCT_OLDINTOFF],BX  ;Save old vector
                MOV     WORD PTR [STRUCT_OLDINTSEG],ES
;----------------------------------------------------------------------
; Set the new target address into DS:DX, and set the vector thru DOS.
; Save the new vector in the struct as well.  This is for a later deinstall.
;----------------------------------------------------------------------
                MOV     AH,25H                      ;Set interrupt vector
                MOV     AL,BYTE PTR [STRUCT_INTNUM] ;Interrupt #

                MOV     DX,[BP+2]               ;IP of instruction after CALL
                ADD     DX,3                    ; Skip GOTO
                MOV     WORD PTR [STRUCT_PDQOFF],DX     ;Save entry offset

                MOV     BX,[BP+4]               ;CS of BASIC int handler
                MOV     WORD PTR [STRUCT_PDQSEG],BX
                MOV     DS,BX                   ; from ret adr on stack
        ASSUME  DS:NOTHING
                INT     21H
;----------------------------------------------------------------------
; Restore registers and return to PDQ.
;----------------------------------------------------------------------
                POP     DS                      ;Restore registers
        ASSUME  DS:DGROUP
                POP     SI
                POP     BP                      ;Erase stack frame
                RET     2                       ;RETF, remove 1 param

PointIntHere    ENDP

;======================================================================
; IntEntry1 (PDQ)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Called from PDQ as the first step when control is transferred by an
;    interrupt to save the AX register and give DGROUP addressability.
; 2. Because control is passed directly from the interrupt, no registers
;    except CS:IP are known.
;----------------------------------------------------------------------
; Usage:
;       CALL    IntEntry1
;----------------------------------------------------------------------
; 7/16/89       Patch after first call.
; 7/17/89       Go with interrupts on.
; 8/1/89        Remove patch.  Must save ax,ds, set ds=dgroup for pdq
;               code that may follow.
;----------------------------------------------------------------------
IntEntry1       PROC    FAR
        ASSUME  CS:CSEG, DS:NOTHING, ES:NOTHING, SS:NOTHING

                STI                             ;Interrupts on
                CLD                             ;String moves forward

                PUSH    BP                      ;Make room on stack
                PUSH    BP
                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                XCHG    AX,WORD PTR [BP+6]      ;Hocus Pocus
                XCHG    AX,WORD PTR [BP+2]
                MOV     AX,DS
                XCHG    AX,WORD PTR [BP+8]
                XCHG    AX,WORD PTR [BP+4]

                MOV     AX,DGROUP
                MOV     DS,AX
        ASSUME  DS:DGROUP

                POP     BP                      ;Erase stack frame
                RET                             ;RETF to PDQ

IntEntry1       ENDP

;======================================================================
; IntEntry2 (PDQ)
;       Copyright (c) 1989,1990 Crescent Software
;       Copyright (c) 1989,1990 Schaefer Software, Robert L. Hummel
;----------------------------------------------------------------------
; 1. Called from PDQ as part of the two-call interrupt service routine
;    entry.  When called, no registers except cs:ip are known.  AX has been
;    pushed on the stack before the parameters, DS = DGROUP.
; 2. When control passes to PDQ, registers in the struct are set to the
;    values they had when the interrupt occurred. The flags register is
;    taken from the value stored by the interrupt.
; 3. Note that register values can only be saved once = only one interrupt
;    can be serviced at a time in linear fashion.  Should the interrupt
;    occur again, it will either be passed to the original ISR or terminated
;    immediately with an IRET, depending on the Action parameter.
; 4. Stack is swapped only if program is resident and this is the first
;    interrupt to be serviced.
; 5. BP is always set to the value for the main program.  Control cannot be
;    transferred into a subprogram.
;
; Stack: FL CS IP / DS AX / STRUCT ACTION / CS IP
;----------------------------------------------------------------------
; Usage:
;       CALL    IntEntry(Registers, Action%)
; where
;       Action% bit 0 = 0       Jump to old interrupt routine.
;                       1       Ignore subsequent interrupts.
;               bit 1 = 0       Wait until resident
;                       1       Work immediately
;----------------------------------------------------------------------
; 7/17/89       Transfer flags from pre-int stack.
; 7/30/89       Use _RESIDENT to determine if popup should happen.
;               Expand definition of action variable.
;               Fix improper SI set in toggle path.
; 8/1/89        New stack on entry.
; 11/4/89       Stack swap options.
;----------------------------------------------------------------------
IntEntry2       PROC    FAR
        ASSUME  CS:CSEG, DS:DGROUP, ES:NOTHING, SS:NOTHING

                STI                             ;Interrupts on
                PUSH    BP                      ;Create stack frame
                MOV     BP,SP

                PUSH    SI                      ;Save used registers
;----------------------------------------------------------------------
; If bit 1 of the action word = 1, then the interrupt routine can get
; control without waiting for this copy to go resident.
;----------------------------------------------------------------------
                MOV     SI,WORD PTR [BP+6]      ;Pointer to action word
                TEST    WORD PTR [SI],2         ;Active immediate flag on?
                MOV     SI,WORD PTR [BP+8]      ;Pointer to struct
                JNZ     IE2_0A                  ; yes
;----------------------------------------------------------------------
; Action set = 0 means the program must be resident to gain control.
; If not resident, treat as if busy.
;----------------------------------------------------------------------
                CMP     WORD PTR [_RESIDENT],0  ;Is res flag on?
                JE      IE2_0B                  ; no
;----------------------------------------------------------------------
; If the service routine for this int isn't busy, get control.
;----------------------------------------------------------------------
IE2_0A:
                CMP     WORD PTR [STRUCT_BUSY],FALSE
                JE      IE2_2
;----------------------------------------------------------------------
; The ISR is already busy.  Check the option parameter for next action.
;----------------------------------------------------------------------
IE2_0B:
                PUSH    SI                      ;Save register
                MOV     SI,WORD PTR [BP+6]      ;Address of Action parameter
                TEST    WORD PTR [SI],1         ;0 = goto old int
                POP     SI                      ;Restore register
                JNZ     IE2_1
;----------------------------------------------------------------------
; Transfer control to old interrupt.  Since we can only control the stack,
; put the old vector's CS:IP on the stack just after the 3 words pushed by
; the INT, remove excess words, then RETF.
;----------------------------------------------------------------------
                PUSH    WORD PTR [BP+12H]       ;Get original flags
                POP     AX                      ; into AX

                XCHG    AX,WORD PTR [BP+8]      ;Save flags on stack

                MOV     AX,WORD PTR [STRUCT_OLDINTOFF]  ;IP of destination
                XCHG    AX,WORD PTR [BP+0AH]            ; on stack
                PUSH    AX                              ;Save orig AX

                MOV     AX,WORD PTR [STRUCT_OLDINTSEG]  ;CS of destination
                XCHG    AX,WORD PTR [BP+0CH]            ; on stack
                MOV     DS,AX                           ;Restore orig DS
        ASSUME  DS:NOTHING

                POP     AX                      ;Restore orig AX
                POP     SI                      ;Restore orig SI

                POP     BP                      ;Erase stack frame
                ADD     SP,6                    ;Clean stack
                POPF                            ;Restore orig flags
                CLI                             ;Interrupts off
                RET                             ;FAR RET to old interrupt
;----------------------------------------------------------------------
; Terminate this interrupt.  Remove all parameters and return immediately.
; Note: most interrupts don't appreciate being treated this way.
;----------------------------------------------------------------------
        ASSUME  DS:DGROUP
IE2_1:
                POP     SI

                POP     BP                      ;Erase stack frame
                ADD     SP,8                    ;Adjust stack
                POP     AX                      ;Restore original AX
                POP     DS                      ;Restore registers
        ASSUME  DS:NOTHING
                CLI                             ;Interrupts off
                IRET                            ;Cancel interrupt
;----------------------------------------------------------------------
; Prepare to transfer control to the PDQ code.
; Save the current register values in the struct.
;----------------------------------------------------------------------
        ASSUME  DS:DGROUP
IE2_2:
                MOV     WORD PTR [STRUCT_BUSY],TRUE     ;Don't re-enter

                POP     WORD PTR [STRUCT_SI]    ;SI off stack
                POP     WORD PTR [STRUCT_BP]    ;BP

                MOV     WORD PTR [STRUCT_BX],BX ;Load from registers
                MOV     WORD PTR [STRUCT_CX],CX
                MOV     WORD PTR [STRUCT_DX],DX
                MOV     WORD PTR [STRUCT_DI],DI
                MOV     WORD PTR [STRUCT_ES],ES

                MOV     BX,WORD PTR [BP+12H]            ;Original flags
                MOV     WORD PTR [STRUCT_FLAGS],BX      ; into struct

                POP     DX                      ;Remove return address
                POP     CX                      ; of PDQ call from stack

                POP     BX                      ;Discard parameters
                POP     BX

                POP     WORD PTR [STRUCT_AX]    ;Get original AX
                POP     WORD PTR [STRUCT_DS]    ; DS from other stack
;----------------------------------------------------------------------
; If program isn't resident, don't swap the stack, it already points
; to the PDQ stack.
;----------------------------------------------------------------------
                CMP     WORD PTR [_RESIDENT],0
                JE      IE2_3
;----------------------------------------------------------------------
; Program is resident.  If the stack already swapped, don't do it again.
;----------------------------------------------------------------------
                CLI                             ;Interrupts off
                CMP     WORD PTR [_SWAPPER],0   ;0 means not swapped
                JNE     IE2_3
;----------------------------------------------------------------------
; Save the old SS:SP and change to the PDQ stack.
; Set a flag to indicate to other interrupts that the stack has already
; been swapped.  The intnum is used so that the code can determine which
; interrupt has to restore the original stack on exit.
;----------------------------------------------------------------------
                MOV     WORD PTR [STRUCT_SS],SS ;Save current SS:SP
                MOV     WORD PTR [STRUCT_SP],SP ; for stack switch

                MOV     AX,WORD PTR [STRUCT_INTNUM]     ;Get int num
                PUSH    DS                      ;DS on stack

                POP     SS                      ;SS=DS
        ASSUME  SS:DGROUP
                MOV     SP,WORD PTR [_SPSAVE]   ;Set SP
                MOV     WORD PTR [_SWAPPER],AX  ;Say it has control
                STI                             ;Interrupts on

;----------------------------------------------------------------------
; Set _RESIDENT to the currently active PSP for DOS versions 3.x.
; For 2.x versions the value is unobtainable in a reliable method.
;----------------------------------------------------------------------
                MOV     BX,-1                   ;current PSP not available
                CMP     BYTE PTR [P$DosVer],2
                JE      IE2_2B
                
                CALL    R$GETPSP
IE2_2B:
                MOV     WORD PTR [_RESIDENT],BX
;----------------------------------------------------------------------
; Interrupts on, set BP to proper value for stack frame in main program.
;----------------------------------------------------------------------
IE2_3:
                STI
                MOV     BP,OFFSET DGROUP:PDQ_STACK_HEAD ;Set stack frame
;----------------------------------------------------------------------
; Transfer control to PDQ by pushing the address and RETF.
; Note that these pushes have to happen after any stack swap.
;----------------------------------------------------------------------
                PUSH    CX                      ;PDQ CS
                PUSH    DX                      ; and IP

                RET                             ;Far return to BASIC

IntEntry2       ENDP

CSEG            ENDS
                END
