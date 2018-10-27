;FPI38_39.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   06/04/90    .000    Double precision conversion routines
;   02/16/91    .001    Began Rob Hummel's implementations
;   02/27/91    .002    Reconstruct
;   02/28/91    .003    Extract from EMULATOR.ASM
;   03/19/92    .004    Combine P$Int38, P$Int39, FP_CNVRT, and _3C's
;               .005    Assume DS:Nothing in Real8_TR, TR_Real8
;                       Assume DS:Nothing in P$Int38, P$Int39
;               .006    Made FP_34_ Extrn (Public in FPI34_35.asm) saved code
;   04/19/91    .007    Add default rounding to TR_Real8
;   09/05/91    .008    Changed mask in TR_Real8 for infinite exponent
;                       Cosmetic changes for MASM 6.0 (ML.EXE)
;   12/13/91    .009    Fix Rounding in TR_Real8 for TRIG.BAS

;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          P$Int38             ;Proc Interrupt Handler
    Public          P$Int38_3C          ;Proc Interrupt Handler
    Public          P$Int39             ;Proc Interrupt Handler
    Public          P$Int39_3C          ;Proc Interrupt Handler
;======================================================================



;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
    DGROUP          GROUP   DSEG,USEG
;======================================================================



;======================================================================
; DSEG: Initialized data.
;----------------------------------------------------------------------
    DSEG            SEGMENT WORD    PUBLIC      'DATA'
;----------------------------------------------------------------------
    Extrn           StatusWord      :Word       ;in FP_STACK.asm
    Extrn           Temp_Real       :TByte      ;in FP_STACK.asm
;----------------------------------------------------------------------
    DSEG            ENDS
;======================================================================



;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
    USEG            SEGMENT WORD    PUBLIC      'BSS'
    USEG            ENDS
;======================================================================



;======================================================================
; Code segment.
;----------------------------------------------------------------------
    PDQ_FP          SEGMENT WORD    PUBLIC      'CODE'
;----------------------------------------------------------------------
    ASSUME  CS:PDQ_FP
;----------------------------------------------------------------------
    Extrn           P$POP_FP        :Near       ;in FP_STACK.ASM
    Extrn           P$PUSH_FP       :Near       ;in FP_STACK.ASM
    Extrn           P$Copy_TR       :Near       ;in FP_STACK.ASM
    Extrn           P$Xchg_TR       :Near       ;in FP_STACK.ASM
    Extrn           P$Temp_Zero     :Near       ;in FP_STACK.ASM

    Extrn           FP_34_          :Near       ;in FPI35_35.ASM
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int38 similar to INT 34h with Double precision
;----------------------------------------------------------------------
P$Int38     Proc Near

    ASSUME  CS:PDQ_FP, DS:Nothing, ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
;   Test the carry flag.  CF indicates a 2-register operation
;----------------------------------------------------------------------
    Jc      FP_38_

;----------------------------------------------------------------------
; Convert the Double pointed to by SI to Temp_Real.  Point SI to Temp_Real
;----------------------------------------------------------------------
    Mov     BX,SI                       ;put the address of the Double in BX
    Push    AX
    Push    DI
    Call    Real8_TR                    ;convert it to temporary real format
    Pop     DI
    Pop     AX
    Mov     SI,Offset DGroup:Temp_Real  ;have SI point to the converted data

;----------------------------------------------------------------------
;   Establish DS = DGroup if we were called from P$Int35_3C
;----------------------------------------------------------------------
    Push    SS
    Pop     DS
    Assume  ES:DGROUP

;----------------------------------------------------------------------
;   Use existing code to test for the correct function based on AX
;   (ie. Reg Part of instruction) which was copied from DL in Emulator
;   above.  These also operate on the instruction form "Ffunc [DI],[SI]".
;----------------------------------------------------------------------
 FP_38_:

    Jmp     FP_34_

P$Int38 EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int38_3C is called when a segment override is given with a P$Int38
;   instruction.  See P$Int3C.
;----------------------------------------------------------------------
P$Int38_3C  Proc Near

    Assume  CS:PDQ_FP, DS:Nothing, ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
;   A Carry here indicates a segment override on a stack operation.
;   In other words, the seg override is a wasted prefix and will be ignored!
;----------------------------------------------------------------------
    Jc      FP_38_

    Jmp     P$Int38

P$Int38_3C  EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int39 is similar to INT 35h with Double precision.  Simple
;           functions for STR$(0) and VAL("0").  Service FP stack and status.
;----------------------------------------------------------------------
P$Int39     Proc Near

    ASSUME  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Test the carry flag.  CF indicated a 2-register operation
;----------------------------------------------------------------------
    Jc      FP_39_

;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg Part of instruction)
;   which was copied from DL in Emulator above.  These functions operate on
;   the instruction form "Ffunc ST,[SI]".
;----------------------------------------------------------------------
    Or      AX,AX               ;DL=0   FLD
    Jnz     @F
    Mov     BX,SI
    Call    Real8_TR            ;convert it to temporary real format
    Jmp     P$Push_FP

 @@:Dec     AX                  ;DL=1
    ;reserved

; @@:
    Dec     AX                  ;DL=2   FST
    Jnz     @F
    Push    SI
    Mov     SI,DI
    Call    P$Copy_TR
    Pop     BX
    Jmp     TR_Real8            ;squeeze the temporary real to QWord Ptr[BX]

 @@:Dec     AX                  ;DL=3   FSTP
    Jnz     @F
    Call    P$Pop_FP
    Mov     BX,SI
    Jmp     Short TR_Real8      ;squeeze the temporary real to QWord Ptr[BX]

 @@:Dec     AX                  ;DL=4   frstor  (94bytes)
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=5
    ;reserved

; @@:
    Dec     AX                  ;DL=6   fsave   (94bytes)
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=7   FSTSW
    Jnz     @F
    Mov     AX,DGROUP:[StatusWord]      ;recover the info.
    Mov     Word Ptr[SI],AX             ;store it where we're told
    ;Ret

 @@:Ret
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg part of instruction)
;   which was copied from DL in Emulator above.  These functions operate on
;   the instruction form "Ffunc ST(i)".
;----------------------------------------------------------------------
 FP_39_:

    Or      AX,AX               ;DL=0   ffree st(i)
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=1   FXCH ST(i)
    Jnz     @F
    Jmp     P$Xchg_TR

 @@:Dec     AX                  ;DL=2   FST ST(i)
    Jnz     @F
    Push    SI
    Mov     SI,DI
    Call    P$Copy_TR
    Pop     DI
    Jmp     P$Xchg_TR

 @@:Dec     AX                  ;DL=3   FSTP ST(i)
    Jnz     @F
    Call    P$Xchg_TR
    Jmp     P$Pop_FP

; @@:Dec     AX                  ;DL=4
;    ;reserved
; @@:Dec     AX                  ;DL=5
;    ;reserved
; @@:Dec     AX                  ;DL=6
;    ;reserved
; @@:Dec     AX                  ;DL=7
;    ;reserved

 @@:Ret
P$Int39 EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int39_3C is called when a segment override is given with a P$Int39
;   instruction.  See P$Int3C.
;----------------------------------------------------------------------
P$Int39_3C     Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   A Carry here indicates a segment override on a stack operation.
;   In other words, the seg override is a wasted prefix and will be ignored!
;----------------------------------------------------------------------
    Jc      FP_39_

    Jmp     P$Int39

P$Int39_3C     EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
; Real8_TR converts the 8 byte real at DS:BX to Temp_Real
;
;   Regs:   Destroyed AX,CX,DX,SI,DI,BP
;   Flags:  Unknown
;----------------------------------------------------------------------
Real8_TR    Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Clear Temp_Real to accept new data
;----------------------------------------------------------------------
    Call    P$Temp_Zero

;----------------------------------------------------------------------
;   Put the sign bit, exponent, and high mantissa bits of the Double
;   in AX for testing and bit shifting.
;----------------------------------------------------------------------
    Mov     AX,[BX+6]
    Test    AX,0FFE0h                    ;test for a zero exponent
    Jz      @F                           ;zero exponent rule for true zero

;----------------------------------------------------------------------
;   Load registers with the remaining mantissa bits for speed.  BP will
;   catch the least significant bits.
;----------------------------------------------------------------------
    Mov     SI,[BX+4]                    ;use registers for speed
    Mov     DI,[BX+2]
    Mov     DX,[BX]
    Xor     BP,BP

;----------------------------------------------------------------------
;   Rearrange the bits according to the rule
;----------------------------------------------------------------------
    Mov     CX,4                         ;4 times clears AX of mantissa bits
 Dbl_Right:
    Sar     AX,1                         ;SAR preserves the sign bit
 Mant_Right_5:
    Rcr     SI,1
    Rcr     DI,1
    Rcr     DX,1
    Rcr     BP,1
    Jcxz    Dbl_Full_Right               ;exits after the fifth shift

    Loop    Dbl_Right
    Stc
    Jc      Mant_Right_5                 ;put the "1." in the mantissa

 Dbl_Full_Right:

;----------------------------------------------------------------------
;   Increase the Double precision bias to Temp_Real bias
;----------------------------------------------------------------------
    And     AH,87h                       ;"10000111b" remove debris from SAR
    Add     AX,(3FFFh-3FFh)              ;establish the new bias

;----------------------------------------------------------------------
;   Copy the registers to Temp_Real
;----------------------------------------------------------------------
    Mov     Word Ptr DGROUP:[Temp_Real+8],AX
    Mov     Word Ptr DGROUP:[Temp_Real+6],SI
    Mov     Word Ptr DGROUP:[Temp_Real+4],DI
    Mov     Word Ptr DGROUP:[Temp_Real+2],DX
    Mov     Word Ptr DGROUP:[Temp_Real],BP

;----------------------------------------------------------------------
;   Return.  (Exit label provided if Double Precision = 0)
;----------------------------------------------------------------------
 @@:RetN

Real8_TR    EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
; TR_Real8 extracts an 8-byte Real from Temp_Real to DS:BX
;
;   Regs:   Destroyed   AX,CX,DX,SI,DI,BP
;   Flags:  Unknown
;----------------------------------------------------------------------
TR_Real8    Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Clear AX here to create a zero, and accept bits for conversion.
;   Load SI with high word or mantissa for testing and bit shifting.
;----------------------------------------------------------------------
    Xor     AX,AX
    Mov     SI,Word Ptr DGROUP:[Temp_Real+6]
    Test    SI,8000h                       ;test for the "1."
    Jnz     Load_Regs                      ;absent if de-normalized mantissa

;----------------------------------------------------------------------
;   The value in Temp_Real was not normal or is zero.  Set DP# = 0
;----------------------------------------------------------------------
    Mov     [BX+6],AX            ;indicate true zero
    Mov     [BX+4],AX            ;indicate true zero \
    Mov     [BX+2],AX            ;indicate true zero  >should not be necessary
    Mov     [BX],AX              ;indicate true zero /
    Jmp     Short Exit           ;exit the routine
    
;----------------------------------------------------------------------
;   Load the mantissa into registers for shifting
;----------------------------------------------------------------------
 Load_Regs:
    Mov     BP,Word Ptr DGROUP:[Temp_Real]
    Mov     DX,Word Ptr DGROUP:[Temp_Real+2]
    Mov     DI,Word Ptr DGROUP:[Temp_Real+4]
;----------------------------------------------------------------------
;   The MSB of SI is the implied "1." of the Double precision.
;----------------------------------------------------------------------
    And     SI,7FFFh             ;loose the "1."

;----------------------------------------------------------------------
;   We move the mantissa 5 places to the left leaving space for the exponent
;----------------------------------------------------------------------
    Mov     CX,5
 Dbl_Left:
    Shl     BP,1
    Rcl     DX,1
    Rcl     DI,1
    Rcl     SI,1
    Rcl     AX,1
    Loop    Dbl_Left

;----------------------------------------------------------------------
; Try to round 4/19/91.  Default to RC = 0 (default)
; This block of code seems logically backwards unless we assume the last
; bit (LSB DX) is even. 12/13/91

;----------------------------------------------------------------------
    Or      BP,BP           
    Jz      Exact_Result

    Test    DX,1        ;Even Rounding.
    Jnz     Rounded

 Rounder:
    Add     DX,1        ;just adds the 1 to DX
    Adc     DI,CX
    Adc     SI,CX
    Adc     AX,CX
 Rounded:
 
;----------------------------------------------------------------------
;   Store the mantissa in the destination Double precision
;----------------------------------------------------------------------
 Exact_Result:
    Mov     [BX],DX
    Mov     [BX+2],DI
    Mov     [BX+4],SI
    Mov     [BX+6],AX                    ;MSB's of mantissa, exponent blanked
    
;----------------------------------------------------------------------
;   Reduce the bias of the TR exponent to the Double precision bias value,
;   then transfer the sign bit.
;----------------------------------------------------------------------
    Mov     AX,Word Ptr DGROUP:[Temp_Real+8]     ;the TR exponent and sign
    Push    AX                                   ;keep a copy
    And     AX,7FFFh                             ;lose the sign bit
    Sub     AX,(3FFFh-3FFh)                      ;compute new bias

;----------------------------------------------------------------------
;   Slide the exponent into its proper position
;----------------------------------------------------------------------
    Mov     CL,4                         ;4 times removes exponent bits
    Shl     AX,CL                        ;shift it into the correct position

;----------------------------------------------------------------------
;   Now recover the sign information
;----------------------------------------------------------------------
    Pop     CX                           ;get the copy we saved
    And     CX,0C000h                    ;mask all but the sign & "#INF"  (was 8000h)
    Or      AX,CX                        ;combine with the exponent in AX
    Or      [BX+6],AX                    ;store it in the double

;----------------------------------------------------------------------
;   Return  (Exit label provided if TR = 0 or de-normal)
;----------------------------------------------------------------------
 Exit:
    Ret

TR_Real8    EndP
;----------------------------------------------------------------------


    PDQ_FP  EndS
;======================================================================

END
