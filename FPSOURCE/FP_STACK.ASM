;FP_STACK.ASM
;Copyright (c) 1990 Crescent Software Inc.
;Written by Paul Passarelli

;   05/24/90    .000    Create FP_Stack, Push_FP, Pop_FP
;   07/10/90    .001    Add FP stack pointer
;   10/31/90    .002    Combine Temp_Zero, and Swap_TR_ST0
;   02/11/91    .003    Rewrite for circular stack, and full ST(n) access
;   02/13/91    .004    Seperate FINCSTP & FDECSTP
;   03/01/91    .005    Restructure
;   03/04/91    .005    Restructure (Rob, please explain DGROUP:Temp_Real)
;   03/08/91    .006    Public P$FINCSTP
;   03/12/91    .007    P$FINIT
;   03/18/91    .008    Assume DS:Nothing in P$Temp_Zero
;   03/19/91    .009    As above in P$Push_FP, P$Pop_FP, P$Copy_TR, P$Xchg_TR
;   04/18/91    .010    Optimize P$FINCSTP and P$FDECSTP

;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          FP_ST               ;Word
    Public          FP_STn              ;Word
    Public          StatusWord          ;Word
    Public          ControlWord         ;Word
    Public          Spare_Real          ;TByte
    Public          Temp_Real           ;TByte
    Public          P$PUSH_FP           ;Near Proc
    Public          P$POP_FP            ;Near Proc
    Public          P$GetFP_STn         ;Near Proc
    Public          P$Temp_Zero         ;Near Proc
    Public          P$Copy_TR           ;Near Proc
    Public          P$Xchg_TR           ;Near Proc
    Public          P$FINCSTP           ;Near Proc
    Public          P$FINIT             ;Near Proc
;======================================================================


;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
    DGROUP          GROUP   DSEG,USEG


;======================================================================
; DSEG: Initialized data.
;----------------------------------------------------------------------
    DSEG            SEGMENT WORD    PUBLIC  'DATA'
;----------------------------------------------------------------------
    Spare_Real  DT      1   dup(0)      ;extra 80 bits
    Temp_Real   DT      1   dup(0)      ;work space
    FP_STACK    DT      8   dup(0)      ;the Floating Point Stack

    FP_ST       DW      Offset DGroup:FP_STACK  ;Public pointer to Stack Top
    FP_STn      DW      Offset DGroup:FP_STACK  ;Public pointer to Stack Item

    StatusWord  DW      0               ;01/14/91
    ControlWord DW      0               ;03/01/91

    IS_TP       DB      0,10            ;Internal Stack Top Pointer, Const 10
    IS_TPn      DB      0               ;Internal Stack Item Pointer
;----------------------------------------------------------------------
    DSEG            ENDS
;======================================================================


;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
    USEG            SEGMENT WORD    PUBLIC  'BSS'
    USEG            ENDS
;======================================================================



;======================================================================
; Code segment.
;----------------------------------------------------------------------
    PDQ_FP          SEGMENT WORD    PUBLIC  'CODE'

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------



;----------------------------------------------------------------------------
;   2 Complementary routines to push and Pop values to/from the floating
;   point stack.  The source/destination is the memory called "Temp_Real".
;
;       I/O:    Ten-byte real in Temp_Real
;       Result: Temp_Real On/Off FP_STACK
;               FP_ST = address of ST
;               IS_TP is adjusted Dn/Up
;       Assume:
;       Regs:   Unchanged (preserved)
;       Flags:  Unchanged (preserved)
;
P$PUSH_FP   Proc Near               ;pushes Temp_Real onto the FP stack

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP
    
    Push    AX
    Push    CX
    Push    SI
    Push    DI
    Push    DS
    PushF                           ;preserve the flags

    Push    SS
    Pop     DS
    Assume  DS:DGROUP

    Call    P$FDECSTP
    Mov     SI,Offset DGroup:Temp_Real  ;source addresses
    Mov     DI,DGROUP:FP_ST             ;destination address
    Mov     CX,5
    Rep     MovSw

    PopF                            ;restore the flags
    Pop     DS
    Pop     DI
    Pop     SI
    Pop     CX
    Pop     AX

    Ret

P$PUSH_FP   EndP



P$POP_FP    Proc Near               ;pops Temp_Real off of the 'FP' stack

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP
    
    Push    AX
    Push    CX
    Push    SI
    Push    DI
    Push    DS
    PushF                           ;preserve the flags

    Push    SS
    Pop     DS
    Assume  DS:DGROUP

    Mov    SI,DGROUP:FP_ST              ;public source address
    Mov    DI,Offset DGROUP:Temp_Real   ;target address
    Mov    CX,5
    Rep    MovSw
    Call   P$FINCSTP

    PopF                            ;restore the flags
    Pop     DS
    Pop     DI
    Pop     SI
    Pop     CX
    Pop     AX

    Ret
    
P$POP_FP    EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------------
;   Complementary routines to increment and decrement the floating point
;   stack pointer.  This is part of the Status Word.
;
;       I/O:    Nothing
;       Result: FP_ST gets address of ST
;               IS_TP is incremented or decremented accordingly
;       Assume:
;       Regs:   AX destroyed
;               Others unchanged
;       Flags:  Unknown
;
;----------------------------------------------------------------------

    Assume  CS:PDQ_FP, DS:Nothing, ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
P$FINCSTP   Proc Near
    Inc     Byte Ptr DGROUP:[IS_TP]     ;internal pointer
    Jmp     Short CalcSTP
;----------------------------------------------------------------------

P$FDECSTP   Proc Near
    Dec     Byte Ptr DGROUP:[IS_TP]     ;internal pointer
;----------------------------------------------------------------------

CalcSTP     Proc Near
    Mov     AX,Word Ptr DGROUP:[IS_TP]  ;internal pointer and constant 10

    And     AL,7                        ;make it circular
    Mov     Byte Ptr DGROUP:[IS_TP],AL  ;save back new internal pointer

    Mul     AH                          ;compute offset
    Add     AX,Offset DGROUP:FP_STACK
    Mov     DGROUP:FP_ST,AX             ;make it public
    Ret
;----------------------------------------------------------------------

CalcSTP     EndP
P$FDECSTP   EndP
P$FINCSTP   EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------------
;   Routine to get the address of an item on the Floating Point Stack
;
;       Input:  ST(Number) in AL
;       Output: FP_STn = address of ST(AL)
;       Assume: 0 ó AL ó 7
;       Regs:   Unchanged
;       Flags:  Unknown
;
P$GetFP_STn Proc Near
    Assume  DS:DGROUP
    Push    AX
    Mov     Byte Ptr[IS_TPn],AL         ;set the new item pointer
    Mov     AX,Word Ptr[IS_TP]          ;internal pointer and constant 10
    Add     AL,Byte Ptr[IS_TPn]         ;item pointer
    And     AL,7                        ;make it circular
    Mul     AH
    Add     AX,Offset DGROUP:FP_STACK
    Mov     FP_STn,AX
    Pop     AX
    Ret
P$GetFP_STn EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------------
; Routine to clear all 80 bits of Temp_Real (ie. force a Zero).
;
;   Input:  Nothing
;   Result: Temp_Real = 0
;           AX = 0
;   Assume:
;   Regs:   AX = 0
;           Others unchanged.
;   Flags:  NC NV (ZF PL)
;
P$Temp_Zero Proc Near               ;clears the Temp_Real and AX to Zero

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

    Push    DI
    Push    CX
    Xor     AX,AX                       ;clear AX to zero  (NC NV (ZF PL))
    Mov     DI,Offset DGROUP:Temp_Real  ;have ES:DI point to Temp_Real
    Mov     CX,5                        ;5 words = 10 bytes
    Rep     StoSW                       ;zero 'em out
    Pop     CX
    Pop     DI
    Ret
P$Temp_Zero EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Xchg_TR   Swaps the Ten Byte Temporary Reals at DS:SI and ES:DI
;
;   Regs:   Unchanged
;   Flags   Unchanged
;
;----------------------------------------------------------------------
P$Xchg_TR   Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

    Push    AX
    Push    BX
    Push    CX
    Push    SI
    Push    DI
    Push    DS
    PushF

    Push    SS
    Pop     DS
    Assume  DS:DGROUP

    Mov     CX,5
    Mov     BX,DI
    Mov     DI,SI

 Swapper:
    LodSW                       ;Mov AX,[SI]: Add SI,2
    Xchg    AX,[BX]             ;swap
    StoSW                       ;Mov [DI],AX: Add DI,2
    Inc     BX                  ;have BX point to the next word manually
    Inc     BX
    Loop    Swapper             ;do the other 4 words
    
    PopF
    Pop     DS
    Pop     DI
    Pop     SI
    Pop     CX
    Pop     BX
    Pop     AX
    RetN

P$Xchg_TR   EndP
;----------------------------------------------------------------------


;----------------------------------------------------------------------
;   P$Copy_TR   Determines the need to make a copy of the TenByte Real
;               at DS:SI to Temp_Real, a default math function operator.
;
;   Input:  Ten-byte data pointed to by DS:SI
;   Result: Copy of Ten-byte pointed to by DS:SI, A.K.A. Temp_Real
;   Regs:   SI points to Temp_Real
;           Others unchanged
;   Flags:  Unknown
;----------------------------------------------------------------------
P$Copy_TR   Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

    Cmp     SI,Offset DGROUP:Temp_Real  ;is SI pointing to Temp_Real?
    Je      @F                          ;yes, not necessary to copy.

    Push    CX                          ;no, save CX and DI.
    Push    DI
    Push    DS

    Push    SS
    Pop     DS
    Assume  DS:DGROUP

    Mov     DI,Offset DGROUP:Temp_Real
    Push    DI                          ;save it for the result
    Mov     CX,5
    Rep     MovSW
    Pop     SI                          ;recover the result

    Pop     DS
    Pop     DI                          ;restore regs
    Pop     CX

 @@:RetN
P$Copy_TR   EndP
;----------------------------------------------------------------------





;----------------------------------------------------------------------
;   P$FINIT Initializes the floating point emulator library as FINIT
;----------------------------------------------------------------------
P$FINIT Proc Near

    Assume  CS:PDQ_FP, DS:Nothing, ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
    Xor     AX,AX
    Mov     CX,Offset IS_TPn - Offset Spare_Real
    Mov     DI,Offset DGroup:Spare_Real
    Rep     Stosw

    Mov     FP_ST,Offset DGroup:FP_Stack
    Mov     FP_STn,Offset DGroup:FP_Stack

    Mov     StatusWord,0
    Mov     ControlWord,0

    Mov     Word Ptr IS_TP,(256*10)     ;Internal Stack Top Pointer, Const 10
    Mov     IS_TPn,0                    ;Internal Stack Item Pointer

    
P$FINIT EndP
;----------------------------------------------------------------------


    PDQ_FP  EndS
;======================================================================

END
