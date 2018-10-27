;P$INT3A.ASM
;Copyright (c) 1990 Crescent Software Inc.
;Written by Paul Passarelli

; 12/05/90  .000  Integer conversion routines
; 02/16/91  .001  Began Rob Hummel's implementations
; 02/27/91  .002  Reconstruct
; 03/08/91  .003  Add P$FINCSTP
;                 fix bug in  FP_3A_: FSUBP ST(i),ST
; 03/12/91  .004  Remove P$FINCSTP
; 03/20/91  .005  Combine P$Int3A, P$Int3B, I2T, and T2I
; 09/03/91  .006  FILD & FISTP QWord [currency]. Rearrange Proc-EndP
;                 for compatability with MASM 6.0 (ML)
; 09/04/91  .007  Due to bad documentation, FIDIV & FIDIVR were reversed, as
;                 were FISUB & FISUBR. This is an explanation not an excuse.

;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          P$Int3A             ;Proc Interrupt Handler
    Public          P$Int3A_3C          ;Proc Interrupt Handler
    Public          P$Int3B             ;Proc Interrupt Handler
    Public          P$Int3B_3C          ;Proc Interrupt Handler
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
    Extrn           Temp_Real       :TByte          ;in FP_STACK.ASM
    Extrn           FP_ST           :Word           ;in FP_STACK.ASM
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
    Extrn           P$FP_ADD        :Near           ;in FP_MATH.ASM
    Extrn           P$FP_SUB        :Near           ;in FP_MATH.ASM
    Extrn           P$FP_MUL        :Near           ;in FP_MATH.ASM
    Extrn           P$FP_DIV        :Near           ;in FP_MATH.ASM
    Extrn           P$FP_COM        :Near           ;in FP_MATH.ASM
    Extrn           P$POP_FP        :Near           ;in FP_STACK.ASM
    Extrn           P$PUSH_FP       :Near           ;in FP_STACK.ASM
    Extrn           P$Copy_TR       :Near           ;in FP_STACK.ASM
    Extrn           P$Xchg_TR       :Near           ;in FP_STACK.ASM
    Extrn           P$Long_to_Temp  :Near           ;in FPI36_37.ASM
    Extrn           P$Temp_to_Long  :Near           ;in FPI36_37.ASM

    Extrn           P$Normalize     :Near           ;in FP_NORM.asm

    Extrn           P$Temp_Zero     :Near           ;in FP_STACK.asm

;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   Interrupt 3Ah performs math and comparisons of values already on
;   the stack.
;----------------------------------------------------------------------
P$Int3A                 Proc Near

    ASSUME  CS:PDQ_FP, DS:Nothing, ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
;   Test the carry flag.  CF indicated a 2-register operation
;----------------------------------------------------------------------
    Jc      FP_3A_              ;Stack_Ops

;----------------------------------------------------------------------
; Convert the Integer pointed to by SI to Temp_Real.  Point SI to Temp_Real
;----------------------------------------------------------------------
    Mov     BX,SI
    Push    AX
    Call    P$Integer_to_Temp   ;convert it to temporary real format
    Pop     AX
    Mov     SI,Offset DGROUP:Temp_Real

;----------------------------------------------------------------------
;   Establish DS = DGroup if we were called from P$Int35_3C
;----------------------------------------------------------------------
    Push    SS
    Pop     DS
    Assume  ES:DGROUP

;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg part of instruction)
;   which was copied from DL in Emulator above.  These also operate on
;   the instruction form "Ffunc [DI],[SI]".
;   (NOTE: FSUB(R) & FDIV(R) are reversed in order.)
;----------------------------------------------------------------------
    Or      AX,AX               ;DL=0   FIADD  word integer
    Jnz     @F
    Jmp     P$FP_ADD

 @@:Dec     AX                  ;DL=1   FIMUL  word integer
    Jnz     @F
    Jmp     P$FP_MUL

 @@:Dec     AX                  ;DL=2   FICOM  word integer
    Jnz     @F
    Jmp     P$FP_COM

 @@:Dec     AX                  ;DL=3   FICOMP word integer
    Jnz     @F
    Call    P$FP_COM
    Jmp     P$Pop_FP

 @@:Dec     AX                  ;DL=4   FISUB word integer
    Jnz     @F
    Jmp     P$FP_SUB

 @@:Dec     AX                  ;DL=5   FISUBR  word integer
    Jnz     @F
    Xchg    SI,DI
    Jmp     P$FP_SUB

 @@:Dec     AX                  ;DL=6   FIDIV word integer
    Jnz     @F
    Jmp     P$FP_DIV

 @@:Dec     AX                  ;DL=7   FIDIVR  word integer
    Jnz     @F
    Xchg    SI,DI
    Jmp     P$FP_DIV

 @@:Ret
P$Int3A                 EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
; These functions operate on the instruction form "Ffunc ST(i),ST".
;----------------------------------------------------------------------
FP_3A_                  Proc Near

;----------------------------------------------------------------------
;   Reverse the pointers to accomodate the form
;----------------------------------------------------------------------
    Xchg    DI,SI

;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg part of instruction)
;   which was copied from DL in Emulator above.  These also operate on
;   the instruction form "Ffunc [SI],[DI]".
;   (NOTE: FSUB(R) & FDIV(R) are reversed in order.)
;----------------------------------------------------------------------
    Or      AX,AX               ;DL=0   ;FADDP ST(i),ST
    Jnz     @F
    Call    P$FP_ADD
    Jmp     P$POP_FP

 @@:Dec     AX                  ;DL=1   ;FMULP ST(i),ST
    Jnz     @F
    Call    P$FP_MUL
    Jmp     P$POP_FP

 @@:Dec     AX                  ;DL=2   ;FCOMP ST(i),ST
    Jnz     @F
    Call    P$FP_COM
    Jmp     P$POP_FP

 @@:Dec     AX                  ;DL=3   ;(XX, fcompp, XX,XX,XX,XX,XX,XX)
    ;Jnz     @F
    Je      FP_3A_DL3

; @@:
    Dec     AX                  ;DL=4   ;FSUBRP ST(i),ST
    Jnz     @F
    Call    P$Xchg_TR
    Call    P$FP_SUB
    Jmp     P$POP_FP

 @@:Dec     AX                  ;DL=5   ;FSUBP ST(i),ST
    Jnz     @F
    Call    P$FP_SUB
    Jmp     P$POP_FP

 @@:Dec     AX                  ;DL=6   ;FDIVRP ST(i),ST
    Jnz     @F
    Call    P$Xchg_TR
    Call    P$FP_DIV
    Jmp     P$POP_FP

 @@:Dec     AX                  ;DL=7   ;FDIVP ST(i),ST
    Jnz     @F
    Call    P$FP_DIV
    Jmp     P$POP_FP

 @@:Ret
;----------------------------------------------------------------------



;----------------------------------------------------------------------
; These functions operate on the instruction form "Ffunc".
;----------------------------------------------------------------------
 FP_3A_DL3:

;----------------------------------------------------------------------
;   Undo previous reversal of pointers
;----------------------------------------------------------------------
    Xchg    SI,DI

;----------------------------------------------------------------------
; Test for the correct function based on DH (ie. Mem part of instruction)
;----------------------------------------------------------------------
    Mov     AL,DH

;----------------------------------------------------------------------
;   Test for the correct function based on AX, this time the Mem part
;   of instruction which was copied from DH above.  These also operate on
;   the instruction form "Ffunc [SI],[DI]".
;----------------------------------------------------------------------
    Or      AX,AX               ;DH=0
    ;reserved

    Dec     AX                  ;DH=1   FCOMPP  {ST,ST(1)}
    Jnz     @F
    Call    P$FP_COM
    Call    P$POP_FP            ;first pop
    Jmp     P$POP_FP            ;second pop

; @@:Dec     AX                  ;DH=2
;    ;reserved
; @@:Dec     AX                  ;DH=3
;    ;reserved
; @@:Dec     AX                  ;DH=4
;    ;reserved
; @@:Dec     AX                  ;DH=5
;    ;reserved
; @@:Dec     AX                  ;DH=6
;    ;reserved
; @@:Dec     AX                  ;DH=7
;    ;reserved

 @@:Ret
;----------------------------------------------------------------------

FP_3A_                  EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int3A_3C is called when a segment override is given with a P$Int3A
;   instruction.  See P$Int3C.
;----------------------------------------------------------------------
P$Int3A_3C  Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   A Carry here indicates a segment override on a stack operation.
;   In other words, the seg override is a wasted prefix and will be ignored!
;----------------------------------------------------------------------
    Jc      FP_3A_
    
    Jmp     P$Int3A

P$Int3A_3C  EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int3B loads and stores 16-bit two's complement numbers.
;           and TByte values. 1-29-91
;----------------------------------------------------------------------
P$Int3B                 Proc Near

    ASSUME  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Test the carry flag.  CF indicated a 2-register operation
;----------------------------------------------------------------------
    Jc      FP_3B_

;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg part of instruction)
;   which was copied from DL in Emulator above.  These also operate on
;   the instruction form "Ffunc [SI]".
;----------------------------------------------------------------------
    Or      AX,AX               ;DL=0   FILD
    Jnz     @F
    Mov     BX,SI
    Call    P$Integer_to_Temp   ;convert it to temporary real format
    Jmp     P$Push_FP

 @@:Dec     AX                  ;DL=1
    ;Jnz     @F
    ;reserved

; @@:
    Dec     AX                  ;DL=2   FIST
    Jnz     @F
    Push    SI
    Mov     SI,DI
    Call    P$Copy_TR
    Pop     BX
    Jmp Short P$Temp_to_Integer ;temporary real copy to Word Ptr[BX]

 @@:Dec     AX                  ;DL=3   FISTP
    Jnz     @F
    Call    P$Pop_FP
    Mov     BX,SI
    Jmp Short P$Temp_to_Integer ;squeeze temporary real to Word Ptr[BX]

 @@:Dec     AX                  ;DL=4   FBLD
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=5   FILD Long (64-bit) Integer
    Jnz     @F
    Mov     BX,SI
    Call    P$Currency_to_Temp  ;convert it to temporary real format
    Jmp     P$Push_FP

 @@:Dec     AX                  ;DL=6   FBSTP
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=7   FISTP Long (64 bit) Integer
    Jnz     @F
    Call    P$Pop_FP
    Mov     BX,SI
    Jmp     P$Temp_to_Currency  ;squeeze temporary real to QWord Ptr[BX]

 @@:Ret
P$Int3B                 EndP
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg part of instruction)
;   which was copied from DL in Emulator above.  These also operate on
;   the instruction form "Ffunc [SI]".
;----------------------------------------------------------------------
FP_3B_                  Proc Near

    Or      AX,AX               ;DL=0   FFREE ST(i) & Pop
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=1   FXCH ST(i)
    Jnz     @F
    Push    SI
    Jmp     P$Xchg_TR

 @@:Dec     AX                  ;DL=2   FSTP ST(i)
    Jnz     @F
    Call    P$Xchg_TR
    Jmp     P$Pop_FP

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
FP_3B_                  EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int3B_3C is called when a segment override is given with a P$Int3B
;   instruction.  See P$Int3C.
;----------------------------------------------------------------------
P$Int3B_3C  Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   A Carry here indicates a segment override on a stack operation.
;   In other words, the seg override is a wasted prefix and will be ignored!
;----------------------------------------------------------------------
    Jc      FP_3B_
    
    Jmp     P$Int3B

P$Int3B_3C  EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Integer_to_Temp converts the 2-byte integer at DS:BX to Temp_Real
;   via Long_to_Temp.
;
;   Regs:   Destroyed AX,CX,DX
;   Flags:  Unknown
;----------------------------------------------------------------------
P$Integer_to_Temp   Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Save DS and BX.
;----------------------------------------------------------------------
    Push    DS
    Push    BX

;----------------------------------------------------------------------
;   Push the integer word at DS:BX onto the stack as a 32-bit Long Integer
;----------------------------------------------------------------------
    Mov     AX,[BX]             ;load the integer into register
    Cwd                         ;make it a 4 byte long integer
    Push    DX                  ;hi word
    Push    AX                  ;lo word

;----------------------------------------------------------------------
;   Have DS:BX point to the 32-bit long on the stack
;----------------------------------------------------------------------
    Push    SS
    Pop     DS
    Assume  DS:DGROUP
    Mov     BX,SP               ;DS:BX points to the long on the stack

;----------------------------------------------------------------------
;   Use P$Long_to_Temp to do the dirty work, then clean the stack
;----------------------------------------------------------------------
    Call    P$Long_to_Temp
    Pop     AX
    Pop     DX

;----------------------------------------------------------------------
;   Restore DS and BX, Return
;----------------------------------------------------------------------
    Pop     BX
    Pop     DS
    Assume  DS:Nothing
    Ret
    
P$Integer_to_Temp EndP
;----------------------------------------------------------------------




;----------------------------------------------------------------------
;   P$Temp_to_Integer extracts a 2-byte integer from Temp_Real to DS:BX
;   with rounding controlled by the emulator Control Word. (via Long_to_Temp)
;
;   Regs:   Destroyed   AX,CX,DX,SI,DI
;   Flags:  Unknown
;----------------------------------------------------------------------
P$Temp_to_Integer Proc Near

    Assume  CS:PDQ_FP, DS:Nothing, ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
;   Save DS and BX.
;----------------------------------------------------------------------
    Push    DS
    Push    BX

;----------------------------------------------------------------------
;   Make room on the stack for a long (32-bit) integer
;----------------------------------------------------------------------
    Push    DX                          ;room for hi word
    Push    AX                          ;room for lo word

;----------------------------------------------------------------------
;   Point DS:BX to the freshly created space
;----------------------------------------------------------------------
    Push    SS
    Pop     DS
    Assume  DS:DGROUP

    Mov     BX,SP                       ;BX points to the long on the stack

;----------------------------------------------------------------------
;   We'll use P$Temp_to_Long to do the dirty work of conversion and rounding
;----------------------------------------------------------------------
    Call   P$Temp_to_Long

;----------------------------------------------------------------------
;   Recover our long integer from the stack
;----------------------------------------------------------------------
    Pop     AX                          ;unload stack
    Pop     DX

;----------------------------------------------------------------------
;   Transfer the sign bit from DX to AX
;----------------------------------------------------------------------
    Shl     AX,1                        ;lose MSB of AX
    Rcl     DX,1                        ;rotate the sign bit into the carry
    Rcr     AX,1                        ;rotate the sign bit back into AX


;----------------------------------------------------------------------
;   Restore DS and BX.  Store the integer and return
;----------------------------------------------------------------------
    Pop     BX                          ;pointer for placement
    Pop     DS                          ;segment for placement
    Mov     [BX],AX                     ;store to integer (Mod 65536)
    Ret

P$Temp_to_Integer EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Currency_to_Temp converts the 8-byte integer at DS:BX to Temp_Real
;
;   Regs:   Destroyed AX,CX,DX ,SI,DI
;   Flags:  Unknown
;----------------------------------------------------------------------
P$Currency_to_Temp      Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Clear Temp_Real, and CX to accept new data
;----------------------------------------------------------------------
    Call    P$Temp_Zero                 ;returns 0 in AX
    Mov     CX,AX                       ;clear space for the exponent

;----------------------------------------------------------------------
;   Load AX and the flags with the high word.
;----------------------------------------------------------------------
    Or      AX,[BX+6]
    Mov     SI,[BX+4]
    Mov     DI,[BX+2]
    Mov     DX,[BX]                     ;get the low word

    Jns     NotNegative

;----------------------------------------------------------------------
;   Negate the negative to a positive number and neg sign and proceed
;----------------------------------------------------------------------
    Mov     CH,80h                      ;hold the sign bit for the exponent

    Not     DX                          ;flip the bits
    Not     DI
    Not     SI
    Not     AX

    Add     DX,1                        ;then add 1
    Adc     DI,0
    Adc     SI,0
    Adc     AX,0

    Jmp Short Integer_to_Real

;----------------------------------------------------------------------
;   Complete the zero test to avoid normalizing zero
;----------------------------------------------------------------------
 NotNegative:
    ;Or      AX,AX
    Jnz     Integer_to_Real             ;highest word

    Or      SI,SI
    Jnz     Integer_to_Real

    Or      DI,DI
    Jnz     Integer_to_Real

    Or      DX,DX                       ;lowest word
    Jnz     Integer_to_Real

    Jmp Short     @F                    ;the whole thing is zero!

;----------------------------------------------------------------------
;   Store the bits of the currency in Temp_Real
;----------------------------------------------------------------------
 Integer_to_Real:
    Mov     Word Ptr DGROUP:[Temp_Real],DX      ;low word
    Mov     Word Ptr DGROUP:[Temp_Real+2],DI
    Mov     Word Ptr DGROUP:[Temp_Real+4],SI
    Mov     Word Ptr DGROUP:[Temp_Real+6],AX    ;high word

;----------------------------------------------------------------------
;   Apply adjusted default bias to the exponent's sign bit in CX
;----------------------------------------------------------------------
    Or      CX,(3FFFh + 63)                     ;(3FFFh+31 was for 32 bit)
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

P$Currency_to_Temp      EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Temp_to_Currency extracts an 8-byte Long Integer from Temp_Real to DS:BX
;   with rounding controlled by the emulator Control Word.
;
;   Regs:   Destroyed   AX,CX,DX,SI,DI
;   Flags:  Unknown
;----------------------------------------------------------------------
P$Temp_to_Currency      Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Save BX here so we can use it for other things.
;   Load AX with Temp_Real exponent for testing and bit shifting.
;----------------------------------------------------------------------
    Push   BX                           ;save the pointer to where it goes
    Mov    AX,Word Ptr DGROUP:[Temp_Real+8]     ;get the exponent
    And    AX,7FFFh                     ;lose the sign bit (if any)
    Sub    AX,3FFFh                     ;remove bias from the integer portion
    Jae    Absolute_Integer             ;go work on the integer part

;----------------------------------------------------------------------
;   Since DX:AX is the natural choice to hold a long integer, we use
;   DX:DI:SI:AX in that order to hold a 64-bit currency.
;   Clear them now and exit the routine.
;----------------------------------------------------------------------
 Long_Zero:
    Xor    AX,AX                        ;lowest word
    Mov    SI,AX
    Mov    DI,AX
    Mov    DX,AX                        ;highest word
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
    Mov    DX,Word Ptr DGROUP:[Temp_Real+6]
    Mov    DI,Word Ptr DGROUP:[Temp_Real+4]
    Mov    SI,Word Ptr DGROUP:[Temp_Real+2]
    Mov    AX,Word Ptr DGROUP:[Temp_Real]

;----------------------------------------------------------------------
;   Shift float down to range, Carry holds coarse rounding info, (.5 | 0 )
;   DI holds sensitive rounding info (up to .49999...)
;----------------------------------------------------------------------
    Xor     BX,BX           ;we use BX as a bit bucket
 Int_Down:
    Shr     DX,1            ;highest word
    Rcr     DI,1
    Rcr     SI,1
    Rcr     AX,1            ;lowest word
    Jnc     @F
    Inc     BX
 @@:Loop    Int_Down

    PushF                   ;save the Carry flag
    Push    BX              ;and the fine rounding info

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
    Add     BL,8                        ;to get the negative order table

    Not     AX                          ;flip the bits
    Not     SI
    Not     DI
    Not     DX

    Add     AX,1                        ;then add 1
    Adc     SI,0
    Adc     DI,0
    Adc     DX,0

 PosVal:
;----------------------------------------------------------------------
;   Restore the fine and coarse rounding info, select appropriate rounding
;   technique.
;----------------------------------------------------------------------
    Pop     CX                          ;fine rounding info
    PopF                                ;Coarse rounding (CF)

    Mov     BX,Word Ptr CS:[RC+BX]
    Jmp     BX

    RC:
        DW  RC0,RC1,RC2,RC3     ;for positive values
        DW  RC4,RC5,RC6,RC7     ;for negative values

;----------------------------------------------------------------------
;   Act like a coprocessor
;----------------------------------------------------------------------
 RC0:                   ;RC = 0     Round to nearest or even default
    Jnc     Regs_2mem   ;           CF = .5 if there then add 1 (Coarse)
    Add     AX,1
    Adc     SI,0
    Adc     DI,0
    Adc     DX,0
    Jmp Short Regs_2mem

 RC1:                   ;RC = 1     Round Down ==> -infinity (0)
    Jmp Short Regs_2mem

 RC2:                   ;RC = 2     Round Up ==> +infinity
    Adc     CX,0        ;           CF = .5(Coarse) CX <= 0.499...(Fine)
    Jz      Regs_2mem
    Add     AX,1
    Adc     SI,0
    Adc     DI,0
    Adc     DX,0
    Jmp Short Regs_2mem

 RC3:                   ;RC = 3     Chop Truncate ==> 0
    Jmp Short Regs_2mem ;           Basic "FIX"


 RC4:                   ;RC = 0     Round to nearest or even default
    Jnc     Regs_2mem   ;           CF = .5 if there then add 1 (Coarse)
    Add     AX,1
    Adc     SI,0
    Adc     DI,0
    Adc     DX,0
    Jmp Short Regs_2mem

 RC5:                   ;RC = 1     Round Down ==> -infinity
    Adc     CX,0        ;           (Fine Rounding <= 0.499...)
    Jz      Regs_2mem
    Sub     AX,1
    Sbb     SI,0
    Sbb     DI,0
    Sbb     DX,0
    Jmp Short Regs_2mem

 RC6:                   ;RC = 2     Round Up ==> +infinity
    Adc     CX,0        ;           (Fine Rounding <= 0.499...)
    Jz      Regs_2mem
    Add     AX,1
    Adc     SI,0
    Adc     DI,0
    Adc     DX,0
    Jmp Short Regs_2mem

 RC7:                   ;RC = 3     Chop Truncate ==> 0
    Jmp Short Regs_2mem ;           Basic "FIX"

;----------------------------------------------------------------------
;   Recover the target address Pushed in BX, and store the long integer
;   to DS:BX.  (Exit label provided if TR = 0, or de-normal, or overflow)
;----------------------------------------------------------------------
 Regs_2mem:
    Pop     BX
    Mov     [BX],AX
    Mov     [BX+2],SI
    Mov     [BX+4],DI
    Mov     [BX+6],DX
    Ret

P$Temp_to_Currency      EndP
;----------------------------------------------------------------------



    PDQ_FP      EndS
;======================================================================

END
