;EMULATOR.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   05/15/90    .000    Original
;   07/13/90    .001    Added P$LEA
;   02/04/91    .002    More work done by P$LEA
;   02/16/91    .003    Began Rob Hummel's implementations
;   02/27/91    .004    Reconstruct
;   03/07/91    .005    Moved code fragment from P$INT_FP to P$LEA
;   03/12/91    .006    Removed extra routine to get callers CS byte
;                       Moved code fragment from P$LEA to P$INT_FP
;   03/15/91    .007    Begin to add INT 3Ch support
;   03/20/91    .008    Preserve DS
;   04/19/91    .009    Back-patch code for INT 3Dh
;   12/11/91    .010    Combined INT 3Dh with P$Int_EM
;   02/21/92    .011    Added JMP $+2 to flush 80486 prefetch queue

;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          P$Int_EM            ;Proc Interrupt Handler
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
    Extrn           FP_ST           :Word           ;in FP_STACK
    Extrn           FP_STn          :Word           ;in FP_STACK
;----------------------------------------------------------------------
;   Interrupt   Is the label for the jump table.

    Interrupt   DW  P$Int34                         ;in FPI34_35
                DW  P$Int35                         ;in FPI34_35
                DW  P$Int36                         ;in FPI36_37
                DW  P$Int37                         ;in FPI36_37
                DW  P$Int38                         ;in FPI38_39
                DW  P$Int39                         ;in FPI38_39
                DW  P$Int3A                         ;in FPI3A_3B
                DW  P$Int3B                         ;in FPI3A_3B
                DW  P$Int3C                         ;in P$Int3C.asm
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

    Assume  CS:PDQ_FP

;----------------------------------------------------------------------
    Extrn           P$GetFP_STn     :Near   ;in FP_STACK.asm
    Extrn           P$Int34         :Near   ;in FPI34_35
    Extrn           P$Int35         :Near   ;in FPI34_35
    Extrn           P$Int36         :Near   ;in FPI36_37
    Extrn           P$Int37         :Near   ;in FPI36_37
    Extrn           P$Int38         :Near   ;in FPI38_39
    Extrn           P$Int39         :Near   ;in FPI38_39
    Extrn           P$Int3A         :Near   ;in FPI3A_3B
    Extrn           P$Int3B         :Near   ;in FPI3A_3B
    Extrn           P$Int3C         :Near   ;in P$INT3C
;----------------------------------------------------------------------



;----------------------------------------------------------------------
; P$Int_EM is the target for the 10 floating point interrupts, 34h - 3Dh
; which are directed here.  Registers are preserved, the interrupt number
; is read from the caller's code segment, then serviced by P$Int##.
;----------------------------------------------------------------------
P$Int_EM    Proc

    Assume  CS:PDQ_FP, DS:DGROUP, ES:Nothing, SS:DGROUP

;----------------------------------------------------------------------
;   Restore maskable interrupts, clear direction flag, create stack
;   frame, and save registers.
;----------------------------------------------------------------------
    Sti
    Cld                         ;string moves forward
    Push    BP
    Mov     BP,SP

    Push    AX
    Push    BX
    Push    CX
    Push    DX
    Push    SI
    Push    DI
    Push    ES
    Push    DS

;----------------------------------------------------------------------
;   Determine which interrupt was used, increment the "IRET IP" on the stack
;----------------------------------------------------------------------
    Assume  DS:Nothing
    Lds     SI,[BP+2]           ;DS gets caller's CS, SI gets caller's IP

    Dec     SI                  ;SI points to the interrupt number
    LodSb


;----------------------------------------------------------------------
;   Was it Interrupt 3Dh FWAIT ?
;----------------------------------------------------------------------
    Cmp     AL,3Dh
    Jne     ItIsINT34_3C

;----------------------------------------------------------------------
; Now we will back-patch the INT 3Dh to a "2 byte NOP" (Mov AX,AX)
; Get the segmented address of the caller's Int 3Dh
;----------------------------------------------------------------------
    Les     DI,[BP+2]           ;we use ES:DI to quickly change the code
    Assume  ES:Nothing
    Dec     DI
    Dec     DI
;----------------------------------------------------------------------
; Put the Opcode for a "2 byte NOP" in AX, then quickly replace the old code
;----------------------------------------------------------------------
    Mov     AX,0C089h        ;Op-code for "Mov AX,AX"
    Stosw
;----------------------------------------------------------------------
; There is no reason to execute this new code this time, so we do not
; reset the callers IP to the Int 3Dh that got us here.
;----------------------------------------------------------------------
; Restore the registers we used, and return from interrupt.
;----------------------------------------------------------------------
    Jmp     RFI
;----------------------------------------------------------------------




;----------------------------------------------------------------------
 ItIsINT34_3C:
;----------------------------------------------------------------------
;   Calculate and save the interrupt number on the stack
;----------------------------------------------------------------------
    Cbw
    Sub     AX,34h              ;make compensation for jump table
    Shl     AX,1                ;make compensation for words from bytes
    Push    AX                  ;use later with the jump table (Pop BX)

;----------------------------------------------------------------------
;   Was it Interrupt 3Ch?
;----------------------------------------------------------------------
    Cmp     AL,10h
    Jb      Mode_Reg_RM         ;no.
    
;----------------------------------------------------------------------
;   Perform special handling for INT 3Ch
;----------------------------------------------------------------------
    LodSb
    Mov     BX,SP
    Xchg    AX,SS:[BX]          ;caller's Seg override byte w/instruction
    Push    DS                  ;caller's CS
    Push    ES                  ;caller's ES
    Push    AX                  ;the interrupt number calculated above

;----------------------------------------------------------------------
;   Get the Mode/Reg/R-M byte from the caller's code segment
;----------------------------------------------------------------------
 Mode_Reg_RM:
    Lodsb
    Mov     [BP+2],SI           ;put the new IP back on the stack

    Push    SS                  ;restore DS
    Pop     DS
    Assume  DS:DGROUP

;----------------------------------------------------------------------
;   Extract the Reg and R-M info from the Mode/Reg/R-M byte in AL
;----------------------------------------------------------------------
    Mov     AH,AL               ;2nd copy in AH
    Xor     DX,DX               ;now DX freely accepts the bits

;----------------------------------------------------------------------
;   This loop extracts the R-M bits of the coprocessor instruction
;----------------------------------------------------------------------
    Mov     CX,3
 @@:
    Shr     AH,1                ;copy the R-M bits to DH    (xx/xxx/R-M)
    Rcr     DH,1
    Loop    @B

;----------------------------------------------------------------------
;   This loop extracts the Reg bits, actually encoding bits of "ESC"
;----------------------------------------------------------------------
    Mov     CL,3
 @@:
    Shr     AH,1                ;copy the REG bits to DL    (xx/REG/xxx)
    Rcr     DL,1
    Loop    @B

;----------------------------------------------------------------------
;   Complete the shift in DH and DL
;----------------------------------------------------------------------
    Mov     CL,5                ;slide the bits in DH and DL down to 0-7
    Shr     DX,CL
    Mov     CL,CH               ;CX=0

;----------------------------------------------------------------------
;   Keep a copy of the Mode/Reg/R-M byte for INT 3Ch
;----------------------------------------------------------------------
    Push    AX

;----------------------------------------------------------------------
;   Interpret the co-processor opcodes.
;----------------------------------------------------------------------
                      ;Input: AL = Mode/Reg/R-M byte
                      ;       DL = Reg portion of instruction byte
                      ;       DH = R-M portion of instruction byte
                      ;       BP = Stack Frame
    Call    P$LEA     ;----------------------------------------------
                      ;Output: SI = Address of the data, -- or --
                      ;             Address of ST(i) (2-register instruction)
                      ;       CARRY = Set if 2-register instruction
                      ;       Destroyed AX BX CX DI BP
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;   CX is free at this point to hold the copy of the Mode/Reg/R-M byte
;----------------------------------------------------------------------
    Pop     CX

;----------------------------------------------------------------------
;   Each P$INT## routine uses DI to point to ST, and AX to determine
;   the instruction.  Do it here to save code.
;----------------------------------------------------------------------
    Mov     DI,FP_ST
    Mov     AL,DL               ;DL contains "ESC" instruction information
    Cbw

;----------------------------------------------------------------------
;   GLOBAL ASSUMPTIONS. ES = DS, CLD.  In P$INT## unless otherwise indicated.
;----------------------------------------------------------------------
    Push    DS
    Pop     ES
    Assume  ES:DGROUP

;----------------------------------------------------------------------
; Service the interrupt initially determined, now saved on the stack
;----------------------------------------------------------------------
    Pop     BX                  ;was pushed as AX
    Call    [Interrupt+BX]

;----------------------------------------------------------------------
; Return from interrupt
;----------------------------------------------------------------------
 RFI:
    Pop     DS
    Pop     ES
    Pop     DI
    Pop     SI
    Pop     DX
    Pop     CX
    Pop     BX
    Pop     AX
    Pop     BP
    IRet
P$Int_EM    EndP
;----------------------------------------------------------------------





;----------------------------------------------------------------------
;   P$LEA   Recovers code segment "arguments" following the interrupt
;
;   Input:      AL = Mode/Reg/R-M byte
;               DL = Reg portion of instruction byte
;               DH = R-M portion of instruction byte
;               SI = Caller's IP
;               BP = Stack Frame
;
;   Output:     SI = Address of the data, -- or --
;                    Address of ST(i) (2-register instruction)
;               CARRY = Set if 2-register instruction
;
;               Destroyed AX BX CX DI BP.  Do not use "USES"!!!
;
;   Assume:     The instruction does not span a segment boundary
;----------------------------------------------------------------------
P$LEA       Proc Near   ;Internal

    Assume  CS:PDQ_FP,  DS:DGROUP,  ES:Nothing, SS:DGROUP

;----------------------------------------------------------------------
;   Examine the Mode bits of the instruction byte
;----------------------------------------------------------------------
    Cmp     AL,0C0h             ;"11..." = a 2-register instruction
    Jb      IP_Counter          ;more CS bytes to read (Mod/xxx/R-M)

;----------------------------------------------------------------------
;   Obtain the register address from DH.
;----------------------------------------------------------------------
    Mov     AL,DH               ;DH has the R-M number from the instruction
    Call    P$GetFP_STn         ;get the address of this stack element
    Mov     SI,FP_STn           ;put it in SI
    Stc                         ;be sure to indicate a Reg-Reg operation
    RetN

;----------------------------------------------------------------------
;   To get the rest of the Mod/xxx/R-M bytes from the caller's code segment.
;   To copy the caller's CS, set-up regs for MovSb.
;----------------------------------------------------------------------
 IP_Counter:
    Push    DS
    Push    ES

    Mov     DS,[BP+4]           ;DS gets the caller's CS
    Assume  DS:Nothing

    Push    CS
    Pop     ES                  ;ES gets the current CS
    Assume  ES:PDQ_FP

    Mov     DI,Offset OpCode    ;DI is the target of the new code

;----------------------------------------------------------------------
;   We will create the instruction LEA SI, [Callers Mode/Reg/R-M byte]
;   to get the desired address in SI for our own use.
;----------------------------------------------------------------------
    And     AL,11000111b        ;force intermittent instruction "Lea AX,???"
    Or      AL,00110000b        ;force final instruction "Lea SI,???"
    
    StoSb                       ;copy the E.A. Mode/Reg/R-M byte
    
;----------------------------------------------------------------------
;   Determine how many bytes are required to complete the encoding
;----------------------------------------------------------------------
    Test    AL,80h              ;"10..." = 16 bit
    Jnz     Disp_16_Bit

    Test    AL,40h              ;"01..." = 8 bit
    Jnz     Disp_8_Bit

    And     AL,00000111b        ;scrap all but the R-M portion of the byte
    Cmp     AL,6                ;"...110" = direct memory operand
    Jne     Disp_0_Bit          ;ie. [BX+SI+0]

;----------------------------------------------------------------------
;   Depending upon entry point, copy the indicated number of bytes,
;   and correct the caller's return IP accordingly.
;----------------------------------------------------------------------
 Disp_16_Bit:
    MovSb
    Inc     CX
 Disp_8_Bit:
    MovSb
    Inc     CX
 Disp_0_Bit:
    Mov     AL,0C3h             ;this is the OpCode for a Near Return
    StoSb
    Add     [BP+2],CX           ;add this back to Caller's(Interrupt) IP

;----------------------------------------------------------------------
;   Restore Seg Regs.
;----------------------------------------------------------------------
    Pop     ES                  ;restore seg regs
    Pop     DS
    Assume  DS:DGROUP,ES:DGROUP

;----------------------------------------------------------------------
;   Restore pre-interrupt Mode/Reg/R-M pointers
;----------------------------------------------------------------------
    Mov     DI,[BP-12]
    Mov     BX,[BP-4]
    Mov     SI,[BP-10]
    Mov     BP,[BP]

;----------------------------------------------------------------------
;   The "LEA SI,???" instruction.
;----------------------------------------------------------------------
    Jmp     $+2                 ;Flush the Queue if this is a 486
    
    DB      8Dh                 ;the opcode for Load Effective Address
 OpCode:
    DB      00                  ;the Mode/Reg/R-M byte
    DB      00                  ;the one-byte displacement (if any)
    DB      00                  ;the two-byte displacement (if any)
    Ret                         ;carry will be clear
    
P$LEA       EndP
;----------------------------------------------------------------------

    PDQ_FP          EndS
;======================================================================

End
