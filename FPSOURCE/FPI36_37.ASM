;FPI36_37.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   07/13/90    .000    Long Integer conversion routines
;   02/16/91    .001    Began Rob Hummel's implementations
;   02/27/91    .002    Reconstruct
;   03/08/91    .003    Full Rounding Control in Temp_to_Long
;   03/12/91    .004    FINIT
;   03/20/91    .005    L2T and T2L public for FPI3A_3B
;   04/18/91    .006    expanded the rounding in Temp_to_Long

;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          P$Int36             ;Proc Interrupt Handler
    Public          P$Int36_3C          ;Proc Interrupt Handler
    Public          P$Int37             ;Proc Interrupt Handler
    Public          P$Int37_3C          ;Proc Interrupt Handler
    Public          P$Long_to_Temp      ;Near Proc
    Public          P$Temp_to_Long      ;Near Proc
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
    Extrn           Temp_Real       :TByte          ;in FP_STACK.asm
    Extrn           ControlWord     :Word           ;in FP_STACK
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
;----------------------------------------------------------------------
    ASSUME  CS:PDQ_FP
;----------------------------------------------------------------------
    Extrn           P$PUSH_FP       :Near           ;in FP_STACK.asm
    Extrn           P$POP_FP        :Near           ;in FP_STACK.asm
    Extrn           P$Copy_TR       :Near           ;in FP_STACK.asm
    Extrn           P$Xchg_TR       :Near           ;in FP_STACK.asm
    Extrn           P$Normalize     :Near           ;in FP_NORM.asm

    Extrn           P$Temp_Zero     :Near           ;in FP_STACK.asm

    Extrn           P$FINIT         :Near           ;in FP_STACK.asm

    Extrn           FP_34_          :Near           ;in FPI34_35.asm
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int36 similar to INT 34h with 32-bit integers
;----------------------------------------------------------------------
P$Int36     Proc Near

    ASSUME  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Test the carry flag.  CF indicated a 2-register operation
;----------------------------------------------------------------------
    Jc      FP_36_

;----------------------------------------------------------------------
; Convert the Long pointed to by SI to Temp_Real.  Point SI to Temp_Real
;----------------------------------------------------------------------
    Mov     BX,SI               ;put the address of the Double in BX
    Push    AX
    Call    P$Long_to_Temp      ;convert it to temporary real format
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
 FP_36_::

    Jmp     FP_34_

P$Int36 EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int36_3C is called when a segment override is given with a P$Int36
;   instruction.  See P$Int3C.
;----------------------------------------------------------------------
P$Int36_3C  Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   A Carry here indicates a segment override on a stack operation.
;   In other words, the seg override is a wasted prefix and will be ignored!
;----------------------------------------------------------------------
    Jc      FP_36_

    Jmp     P$Int36

P$Int36_3C  EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int37 loads and stores 32 bit two's complement numbers.
;           and TByte values. 1-29-91
;----------------------------------------------------------------------
P$Int37     Proc Near

    ASSUME  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Test the carry flag.  CF indicated a 2-register operation
;----------------------------------------------------------------------
    Jc      FP_37_

;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg Part of instruction)
;   which was copied from DL in Emulator above.  These functions operate on
;   the instruction form "Ffunc ST,[SI]".
;----------------------------------------------------------------------
    Or      AX,AX               ;DL=0   FILD
    Jnz     @F
    Mov     BX,SI
    Call    P$Long_to_Temp      ;convert it to temporary real format
    Jmp     P$Push_FP

 @@:Dec     AX                  ;DL=1
    ;reserved

; @@:
    Dec     AX                  ;DL=2   FIST
    Jnz     @F
    Push    SI
    Mov     SI,DI
    Call    P$Copy_TR
    Pop     BX
    Jmp Short P$Temp_to_Long    ;temporary real to DWord Ptr[BX]

 @@:Dec     AX                  ;DL=3   FISTP
    Jnz     @F
    Call    P$Pop_FP
    Mov     BX,SI
    Jmp Short P$Temp_to_Long    ;squeeze the temporary real to QWord Ptr[BX]

 @@:Dec     AX                  ;DL=4
    ;reserved

; @@:
    Dec     AX                  ;DL=5   FLD ten byte real
    Jnz     @F
    Call    P$Copy_TR           ;copy DS:SI to Temp_Real
    Jmp     P$PUSH_FP           ;push it onto the floating point stack

 @@:Dec     AX                  ;DL=6
    ;reserved

; @@:
    Dec     AX                  ;DL=7   FSTP ten byte real
    Jnz     @F
    Call    P$Xchg_TR           ;swap ST,Mem
    Jmp     P$Pop_FP            ;pop the trash

 @@:Ret
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg Part of instruction)
;   which was copied from DL in Emulator above.  These functions operate on
;   the instruction form "Ffunc".
;----------------------------------------------------------------------
 FP_37_::

    Or      AX,AX               ;DL=0
    ;reserved
    Dec     AX                  ;DL=1
    ;reserved
    Dec     AX                  ;DL=2
    ;reserved
    Dec     AX                  ;DL=3
    ;reserved
    Dec     AX                  ;DL=4
    ;(feni, fdisi, fclex, finit,XX,XX,XX,XX)
    Je      FP_37_DL4

; @@:Dec     AX                  ;DL=5
;    ;reserved
; @@:Dec     AX                  ;DL=6
;    ;reserved
; @@:Dec     AX                  ;DL=7
;    ;reserved

; @@:
    Ret
;----------------------------------------------------------------------



 FP_37_DL4:
;----------------------------------------------------------------------
; Test for the correct function based on DH (ie. Mem part of instruction)
;----------------------------------------------------------------------
    Mov     AL,DH
;----------------------------------------------------------------------
; These functions operate on the instruction form "Ffunc".
;----------------------------------------------------------------------
    Or      AX,AX               ;DH=0   feni
    ;Jnz     @F
    ;unsupported 3/11/91

; @@:
    Dec     AX                  ;DH=1   fdisi
    ;Jnz     @F
    ;unsupported 3/11/91

; @@:
    Dec     AX                  ;DH=2   fclex
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DH=3   FINIT
    Jnz     @F
    Jmp     P$FINIT

; @@:Dec     AX                  ;DH=4
;    ;reserved
; @@:Dec     AX                  ;DH=5
;    ;reserved
; @@:Dec     AX                  ;DH=6
;    ;reserved
; @@:Dec     AX                  ;DH=7
;    ;reserved

 @@:Ret

P$Int37     EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int37_3C is called when a segment override is given with a P$Int37
;   instruction.  See P$Int3C.
;----------------------------------------------------------------------
P$Int37_3C     Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   A Carry here indicates a segment override on a stack operation.
;   In other words, the seg override is a wasted prefix and will be ignored!
;----------------------------------------------------------------------
    Jc      FP_37_

    Jmp     P$Int37

P$Int37_3C     EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Long_to_Temp converts the 4-byte integer at DS:BX to Temp_Real
;
;   Regs:   Destroyed AX,CX,DX
;   Flags:  Unknown
;----------------------------------------------------------------------
P$Long_to_Temp Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Clear Temp_Real, and CX to accept new data
;----------------------------------------------------------------------
    Call    P$Temp_Zero
    Mov     CX,AX                       ;clear space for the exponent

;----------------------------------------------------------------------
;   Load AX and the flags with the high word.
;----------------------------------------------------------------------
    Or      AX,[BX+2]
    Mov     DX,[BX]                     ;get the low word
    Jns     NotNegative

;----------------------------------------------------------------------
;   Negate the negative to a positive number and neg sign and proceed
;----------------------------------------------------------------------
    Neg     DX
    Adc     AX,0
    Neg     AX
    Mov     CH,80h                      ;hold the sign bit for the exponent
    Jmp Short Integer_to_Real

;----------------------------------------------------------------------
;   Complete the zero test to avoid normalizing zero
;----------------------------------------------------------------------
 NotNegative:
    Jnz     Integer_to_Real             ;are there MSW bits?

    Or      DX,AX                       ;no, is the lo word Zero?
    Jz      @F                          ;yes, the whole thing is zero!
    
;----------------------------------------------------------------------
;   Store the bits of the long in Temp_Real
;----------------------------------------------------------------------
 Integer_to_Real:
    Mov     Word Ptr DGROUP:[Temp_Real+4],DX    ;low word
    Mov     Word Ptr DGROUP:[Temp_Real+6],AX    ;high word

;----------------------------------------------------------------------
;   Apply adjusted default bias to the exponent's sign bit in CX
;----------------------------------------------------------------------
    Or      CX,(3FFFh+31)
    Mov     Word Ptr DGROUP:[Temp_Real+8],CX    ;store exponent in TR
    
;----------------------------------------------------------------------
;   Normalize the value in Temp_Real
;----------------------------------------------------------------------
    Push    SS
    Pop     DS
    Assume  DS:DGROUP
    
    Mov     BX,Offset DGROUP:Temp_Real
    Call    P$Normalize                 ;correct the bias and bit placement

;----------------------------------------------------------------------
;   Return.  (Exit label provided if Long Integer = 0)
;----------------------------------------------------------------------
 @@:RetN

P$Long_to_Temp EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Temp_to_Long extracts a 4-byte Long Integer from Temp_Real to DS:BX
;   with rounding controled by the emulator Control Word.
;
;   Regs:   Destroyed   AX,CX,DX,SI,DI
;   Flags:  Unknown
;----------------------------------------------------------------------
P$Temp_to_Long  Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Save BX here so we can use it for other things.  Load AX with Temp_Real
;   exponent for testing and bit shifting.
;----------------------------------------------------------------------
    Push   BX                           ;save the pointer to where it goes
    Mov    AX,Word Ptr DGROUP:[Temp_Real+8]     ;get the exponent
    And    AX,7FFFh                     ;lose the sign bit (if any)
    Sub    AX,3FFFh                     ;remove bias from the integer portion
    Jae    Absolute_Integer             ;go work on the integer part

;----------------------------------------------------------------------
;   Since DX:AX is the natural choice to hold a long integer.  Clear DX:AX
;   and exit the routine.
;----------------------------------------------------------------------
 Long_Zero:
    Xor    AX,AX
    Mov    DX,AX
    Jmp    Regs_2mem

;----------------------------------------------------------------------
;   Does the value have any significant bits in the range of 1 to 2 ^ 31?
;----------------------------------------------------------------------
 Absolute_Integer:
    Mov    CX,63
    Sub    CX,AX
    Js     Long_Zero                    ;too large for significant portion
    
;----------------------------------------------------------------------
;   Load the mantissa into registers for shifting
;----------------------------------------------------------------------
    Mov    BX,Word Ptr DGROUP:[Temp_Real+6]
    Mov    SI,Word Ptr DGROUP:[Temp_Real+4]
    Mov    DX,Word Ptr DGROUP:[Temp_Real+2]
    Mov    AX,Word Ptr DGROUP:[Temp_Real]

;----------------------------------------------------------------------
;   Shift float down to range, Carry holds coarse rounding info, (.5 | 0 )
;   DI holds sensitive rounding info (up to .49999...)
;----------------------------------------------------------------------
    Xor     DI,DI           ;we use DI as a bit bucket
 Int_Down:
    Shr     BX,1
    Rcr     SI,1
    Rcr     DX,1
    Rcr     AX,1
    Jnc     @F
    Inc     DI
 @@:Loop    Int_Down

    PushF                   ;save the Carry flag
    And     DH,7Fh          ;clear the long sign bit (31 bits significant)

;----------------------------------------------------------------------
;   Isolate the rounding bits in ControlWord
;----------------------------------------------------------------------
    Mov     BX,DGROUP:[ControlWord]
    Xchg    BL,BH
    And     BX,0Ch
    Shr     BX,1

;----------------------------------------------------------------------
;   Is the value positive or negative?  It affects rounding.
;----------------------------------------------------------------------
    Mov     CX,Word Ptr DGROUP:[Temp_Real+8]    ;get the real exponent
    And     CH,80h                      ;keep the sign bit
    Jns     PosVal                      ;it's a positive number

;----------------------------------------------------------------------
;   Change the sign to a negative number, use the 2nd half of the RC table
;----------------------------------------------------------------------
    Neg     AX
    Adc     DX,0
    Neg     DX
    Add     BL,8                        ;to get the negative order table

 PosVal:
;----------------------------------------------------------------------
;   Restore the coarse rounding info, select appropriate rounding technique
;----------------------------------------------------------------------
    PopF
    Mov     BX,Word Ptr CS:[RC+BX]
    Jmp     BX

            ;for positive values    ;for negative values
    RC:
        DW  RC0, RC1, RC2, RC3,     RC4, RC5, RC6, RC7

;----------------------------------------------------------------------
;   Act like a coprocessor
;----------------------------------------------------------------------
 RC0:                   ;RC = 0     Round to nearest or even default
    Jnc     Regs_2mem   ;           CF = .5 if there then add 1 (Coarse)
    Add     AX,1
    Adc     DX,0
    Jmp Short Regs_2mem

 RC1:                   ;RC = 1     Round Down ==> -infinity (0)
    Jmp Short Regs_2mem

 RC2:                   ;RC = 2     Round Up ==> +infinity
    Adc     DI,0        ;           CF = .5(Coarse) DI <= 0.499...(Fine)
    Jz      Regs_2mem
    Add     AX,1
    Adc     DX,0
    Jmp Short Regs_2mem

 RC3:                   ;RC = 3     Chop Truncate ==> 0
    Jmp Short Regs_2mem ;           Basic "FIX"


 RC4:                   ;RC = 0     Round to nearest or even default
    Jnc     Regs_2mem   ;           CF = .5 if there then add 1 (Coarse)
    Add     AX,1
    Adc     DX,0
    Jmp Short Regs_2mem

 RC5:                   ;RC = 1     Round Down ==> -infinity
    Adc     DI,0        ;           (Fine Rouding <= 0.499...)
    Jz      Regs_2mem
    Sub     AX,1
    Sbb     DX,0
    Jmp Short Regs_2mem

 RC6:                   ;RC = 2     Round Up ==> +infinity
    Adc     DI,0        ;           (Fine Rouding <= 0.499...)
    Jz      Regs_2mem
    Add     AX,1
    Adc     DX,0
    Jmp Short Regs_2mem

 RC7:                   ;RC = 3     Chop Truncate ==> 0
    Jmp Short Regs_2mem ;           Basic "FIX"

;----------------------------------------------------------------------
;   Recover the target address Pushed in BX, and store the long integer
;   to DS:BX.  (Exit label provided if TR = 0, or de-normal, or overflow)
;----------------------------------------------------------------------
 Regs_2mem:
    Pop    BX
    Mov    [BX],AX
    Mov    [BX+2],DX
    Ret
    
P$Temp_to_Long  EndP
;----------------------------------------------------------------------

    PDQ_FP      EndS
;======================================================================

END
