;_DEBUGFP.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;written by Paul Passarelli

;   03/11/91    .000    Original
;   04/19/91    .001    Added 4 more labels

;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          P$HookFP            ;Proc Far

    Public          B$FCMP
    Public          B$FIL2
    Public          B$FILD
    Public          B$FIS2
    Public          B$FIST
    Public          B$FIX4
    Public          B$FIX8
    Public          B$INT4
    Public          B$INT8
    Public          B$FUST
    Public          B$FVAL
    Public          B$PCR4
    Public          B$PCR8
    Public          B$PER4
    Public          B$PER8
    Public          B$PSR4
    Public          B$PSR8
    Public          B$RND0
    Public          B$RND1
    Public          B$RNZP
    Public          B$SGN4
    Public          B$SGN8
    Public          B$STR4
    Public          B$STR8
    Public          B$TIMR
;======================================================================



;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
    DGROUP          GROUP   DSEG,USEG
;======================================================================



;======================================================================
; DSEG: Initialized data.
;----------------------------------------------------------------------
    DSEG            SEGMENT WORD    PUBLIC  'DATA'
;----------------------------------------------------------------------
    FP_Req_Msg  DB  "Floating Point Required at "
    FP_Req_     DW  FP_Req_ - FP_Req_Msg, Offset DGroup:FP_Req_Msg

    Colon_Msg   DB  ":"
    Colon_      DW  Colon_ - Colon_Msg, Offset DGroup:Colon_Msg
;----------------------------------------------------------------------
    DSEG            ENDS
;======================================================================



;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
    USEG            SEGMENT WORD    PUBLIC  'BSS'
;----------------------------------------------------------------------
    Extrn       OldFPInts   :DWord          ;Interrupt vectors 34h - 3Dh
                                            ;in UnhookFP.ASM
;----------------------------------------------------------------------
    USEG            ENDS
;======================================================================



;======================================================================
; Code segment.
;----------------------------------------------------------------------
    PDQ_FP          SEGMENT WORD    PUBLIC  'CODE'
;----------------------------------------------------------------------
    Extrn       B$PSSD      :Far    ;this is in PRINT.ASM
    Extrn       B$FHEX      :Far    ;this is in HEX$.ASM
    Extrn       B$PESD      :Far    ;this is in PRINT.ASM
    Extrn       B$CEND      :Far    ;this is in PDQ.ASM
;----------------------------------------------------------------------

    Assume  CS:PDQ_FP, DS:DGROUP, ES:Nothing, SS:DGROUP

;----------------------------------------------------------------------

;----------------------------------------------------------------------
;   These are the locations that interrupts are directed to.
;   They all fall into Show_FP.
;----------------------------------------------------------------------
P$Int_FP    Proc
P$Int_FP    EndP
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;   Modify the return address on the stack, because an interrupt only
;   takes 2 bytes, yet the Show_FP handles Calls which take 5 bytes.
;----------------------------------------------------------------------
    Pop     AX                      ;make INT same size as CALL
    Add     AX,3
    Push    AX                      ; 5 will be subtracted later

;----------------------------------------------------------------------
;   These are the public subs that handle BASIC FP operations.
;   They all fall into Show_FP.
;----------------------------------------------------------------------
B$FCMP      Proc
B$FCMP      EndP

B$FIL2      Proc
B$FIL2      EndP

B$FILD      Proc
B$FILD      EndP

B$FIS2      Proc
B$FIS2      EndP

B$FIST      Proc
B$FIST      EndP

B$FIX4      Proc
B$FIX4      EndP

B$FIX8      Proc
B$FIX8      EndP

B$INT4      Proc
B$INT4      EndP

B$INT8      Proc
B$INT8      EndP

B$FUST      Proc
B$FUST      EndP

B$FVAL      Proc
B$FVAL      EndP

B$PCR4      Proc
B$PCR4      EndP

B$PCR8      Proc
B$PCR8      EndP

B$PER4      Proc
B$PER4      EndP

B$PER8      Proc
B$PER8      EndP

B$PSR4      Proc
B$PSR4      EndP

B$PSR8      Proc
B$PSR8      EndP

B$RND0      Proc    ;4/19/91
B$RND0      EndP

B$RND1      Proc    ;4/19/91
B$RND1      EndP

B$RNZP      Proc    ;4/19/91
B$RNZP      EndP

B$SGN4      Proc
B$SGN4      EndP

B$SGN8      Proc
B$SGN8      EndP

B$STR4      Proc
B$STR4      EndP

B$STR8      Proc
B$STR8      EndP

B$TIMR      Proc    ;4/19/91
B$TIMR      EndP
;----------------------------------------------------------------------


;----------------------------------------------------------------------
;   Show_FP shows the Segment:Address of the floating point instruction
;           that we are trying to remove.
;----------------------------------------------------------------------
Show_FP     Proc    ;Internal
    Assume  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Print the Error message
;----------------------------------------------------------------------
    Mov     AX,Offset DGroup:FP_Req_   ;print "Floating Point Required at "
    Push    AX
    Call    B$PSSD

;----------------------------------------------------------------------
;   Print the Segment
;----------------------------------------------------------------------
    Pop     DX            ;retrieve the address from the stack
    Pop     AX            ;retrieve the segment from the stack
    Push    DX            ;restore the address to the stack

    Cwd
    Push DX               ;pass that on to HEX$
    Push AX
    Call B$FHEX           ;convert the segment to a Hex string

    Push AX               ;pass the descriptor address HEX$ returns to PRINT
    Call B$PSSD           ;print it
    
;----------------------------------------------------------------------
;   Print the Colon
;----------------------------------------------------------------------
    Mov  AX,Offset DGroup:Colon_  ;print the separating colon
    Push AX
    Call B$PSSD

;----------------------------------------------------------------------
;   Print the Address
;----------------------------------------------------------------------
    Pop  AX               ;retrieve the address from the stack
    Sub  AX,5             ;adjust for the size of the CALL

    Cwd
    Push DX               ;pass that on to HEX$
    Push AX
    Call B$FHEX           ;convert the segment to a Hex string

    Push AX               ;pass the descriptor address HEX$ returns to PRINT
    Call B$PESD           ;print it

    Jmp  B$CEND           ;end the program

Show_FP     EndP
;----------------------------------------------------------------------


;----------------------------------------------------------------------
P$HookFP    Proc Far
    Assume  CS:PDQ_FP, DS:DGROUP, ES:Nothing, SS:DGROUP
;----------------------------------------------------------------------------
;   Save registers
;----------------------------------------------------------------------------
    Push    AX
    Push    BX
    Push    CX
    Push    DX
    Push    SI
    Push    BP
    Push    DS
    Push    ES

;----------------------------------------------------------------------------
;   Save the existing interrupt vectors to local storage
;----------------------------------------------------------------------------
    Mov     AX,3534h                ;service 35h in AH, INT 34h in AL
    Mov     CX,10                   ;for Interrupt 34h - 3Dh
    Mov     SI,Offset DGroup:OldFPInts  ;local storage

 Save_Old_Int:
    Int     21h                     ;via DOS
    Mov     [SI],BX                 ;save the address
    Mov     [SI+2],ES               ;save the segment
    Add     SI,4                    ;point to the next storage area
    Inc     AL                      ;select the next interrupt
    Loop    Save_Old_Int

;----------------------------------------------------------------------------
;   Now redirect the floating point interrupts to ourselves
;----------------------------------------------------------------------------
    Push    CS                      ;here's the segment
    Pop     DS                      ;which DOS wants in DS
    Assume  DS:Nothing

    Mov     DX,Offset P$Int_FP
    Mov     CX,10
    Mov     AX,2534h                ;point Interrupt 34h - 3Dh to our handler

 Tell_New_Int:
    Int     21h                     ;call DOS to do it
    Inc     AL
    Loop    Tell_New_Int

;----------------------------------------------------------------------------
;   Restore registers. Return
;----------------------------------------------------------------------------
    Pop     ES
    Pop     DS
    Assume  DS:DGROUP

    Pop     BP
    Pop     SI
    Pop     DX
    Pop     CX
    Pop     BX
    Pop     AX

    Ret
P$HookFP EndP
;----------------------------------------------------------------------

    PDQ_FP          EndS
;======================================================================

END
