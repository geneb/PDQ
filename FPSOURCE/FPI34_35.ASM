;FPI34_35.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   05/15/90    .000    Single precision conversion routines
;   07/13/90    .001    Now in EMULATOR.ASM (added P$LEA)
;   02/04/91    .002    Now in EMULATOR.ASM (more work done by P$LEA)
;   02/16/91    .003    Began Rob Hummel's implementations
;   02/27/91    .004    Reconstruct
;   02/28/91    .005    Extract from EMULATOR.ASM
;   03/18/91    .006    Combine P$Int34, P$Int35, FP_CNVRT, and _3C's
;   03/18/91            Assume DS:Nothing in Single_to_Temp, Temp_to_Single
;   03/19/91    .007    Assume DS:Nothing in P$Int34, P$Int35
;               .008    Made FP_34_ Public to save code in FPI38_39
;   04/18/91    .009    Add Rounding to Temp_to_Single
;   09/30/91    .010    Rework code Temp_to_Single

;======================================================================
; Public Symbols.
;----------------------------------------------------------------------
    Public          P$Int34             ;Near Proc Interrupt Handler
    Public          P$Int34_3C          ;Near Proc
    Public          P$Int35             ;Near Proc Interrupt Handler
    Public          P$Int35_3C          ;Near Proc
    Public          FP_34_              ;Near Proc
;----------------------------------------------------------------------
;======================================================================


;======================================================================
; DGROUP addressing fixed up by linker.
;----------------------------------------------------------------------
    DGROUP          GROUP   DSEG,USEG
;----------------------------------------------------------------------
;======================================================================


;======================================================================
; DSEG: Initialized data.
;----------------------------------------------------------------------
    DSEG            SEGMENT WORD    PUBLIC      'DATA'
;----------------------------------------------------------------------
    Extrn           FP_ST           :Word               ;in FP_STACK
    Extrn           StatusWord      :Word               ;in FP_STACK
    Extrn           ControlWord     :Word               ;in FP_STACK
    Extrn           Temp_Real       :TByte              ;in FP_STACK
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
    Extrn       P$FP_ADD                :Near           ;in FP_MATH.asm
    Extrn       P$FP_SUB                :Near           ;in FP_MATH.asm
    Extrn       P$FP_MUL                :Near           ;in FP_MATH.asm
    Extrn       P$FP_DIV                :Near           ;in FP_MATH.asm
    Extrn       P$FP_COM                :Near           ;in FP_MATH.asm
    Extrn       P$POP_FP                :Near           ;in FP_STACK.asm
    Extrn       P$PUSH_FP               :Near           ;in FP_STACK.asm
    Extrn       P$Copy_TR               :Near           ;in FP_STACK.asm
    Extrn       P$Xchg_TR               :Near           ;in FP_STACK.asm
    Extrn       P$Temp_Zero             :Near           ;in FP_STACK.asm
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int34 performs simple math on single precision operators, and values
;           already on the floating point stack.
;----------------------------------------------------------------------
P$Int34     Proc Near

    ASSUME  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Test the carry flag.  CF indicates a 2-register operation
;----------------------------------------------------------------------
    Jc      FP_34_

;----------------------------------------------------------------------
; Convert the Single pointed to by SI to Temp_Real.  Point SI to Temp_Real
;----------------------------------------------------------------------
    Mov     BX,SI               ;put the address of the Single in BX
    Push    AX
    Call    P$Single_to_Temp    ;convert it to temporary real format
    Pop     AX
    Mov     SI,Offset DGroup:Temp_Real  ;have SI point to the converted data
    
;----------------------------------------------------------------------
;   Establish DS = DGroup if we were called from P$Int34_3C
;----------------------------------------------------------------------
    Push    SS
    Pop     DS
    Assume  ES:DGROUP

;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg Part of instruction)
;   which was copied from DL in Emulator above.  These functions operate on
;   the instruction form "Ffunc [DI],[SI]".
;----------------------------------------------------------------------
FP_34_      Proc Near
;----------------------------------------------------------------------
    Or      AX,AX
    Jnz     @F

    Jmp     P$FP_ADD    ;DL=0   FADD

 @@:
;----------------------------------------------------------------------
    Dec     AX
    Jnz     @F

    Jmp     P$FP_MUL    ;DL=1   FMUL

 @@:
;----------------------------------------------------------------------
    Dec     AX
    Jnz     @F

    Jmp     P$FP_COM    ;DL=2   FCOM

 @@:
;----------------------------------------------------------------------
    Dec     AX
    Jnz     @F

    Call    P$FP_COM    ;DL=3   FCOMP
    Jmp     P$Pop_FP

 @@:
;----------------------------------------------------------------------
    Dec     AX
    Jnz     @F

    Jmp     P$FP_SUB    ;DL=4   FSUB

 @@:
;----------------------------------------------------------------------
    Dec     AX
    Jnz     @F

    Xchg    SI,DI       ;DL=5   FSUBR
    Jmp     P$FP_SUB

 @@:
;----------------------------------------------------------------------
    Dec     AX
    Jnz     @F

    Jmp     P$FP_DIV    ;DL=6   FDIV

 @@:
;----------------------------------------------------------------------
    Dec     AX
    Jnz     @F

    Xchg    SI,DI       ;DL=7   FDIVR
    Jmp     P$FP_DIV

 @@:
;----------------------------------------------------------------------
    Ret

FP_34_      EndP

P$Int34     EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int34_3C is called when a segment override is given with a P$Int34
;   instruction.  See P$Int3C.
;----------------------------------------------------------------------
P$Int34_3C  Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   A Carry here indicates a segment override on a stack operation.
;   In other words, the seg override is a wasted prefix and will be ignored!
;----------------------------------------------------------------------
    Jc      FP_34_

    Jmp     P$Int34

P$Int34_3C  EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int35 loads and stores Single precision operators, also sign change,
;           absolute value, constant loading, and testing.
;----------------------------------------------------------------------
P$Int35     Proc Near

    ASSUME  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Test the carry flag.  CF indicates a 2-register operation
;----------------------------------------------------------------------
    Jc      FP_35_

;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg Part of instruction)
;   which was copied from DL in Emulator above.  These functions operate on
;   the instruction form "Ffunc ST,[SI]".
;----------------------------------------------------------------------
    Or      AX,AX               ;DL=0   FLD
    Jnz     @F
    Mov     BX,SI               ;address of the Single
    Call    P$Single_to_Temp    ;convert to temporary real format
    Jmp     P$Push_FP

 @@:Dec     AX                  ;DL=1
    ;reserved

; @@:
    Dec     AX                  ;DL=2   FST
    Jnz     @F
    Push    SI                  ;address of the Single
    Mov     SI,DI               ;Stack Top
    Call    P$Copy_TR           ;to Temp_Real
    Pop     BX                  ;address of the Single
    Jmp     P$Temp_to_Single    ;the temporary real copy to DWord Ptr[BX]

 @@:Dec     AX                  ;DL=3   FSTP
    Jnz     @F
    Call    P$Pop_FP            ;Stack Top to Temp_Real
    Mov     BX,SI               ;address of the Single
    Jmp     P$Temp_to_Single    ;the popped temporary real to DWord Ptr[BX]

 @@:Dec     AX                  ;DL=4   FLDENV
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=5   FLDCW
    Jnz     @F
    Mov     AX,[SI]
    Mov     DGROUP:ControlWord,AX
    Ret

 @@:Dec     AX                  ;DL=6   FSTENV
    ;Jnz     @F
    ;unsupported 3/7/91
    
; @@:
    Dec     AX                  ;DL=7   FSTCW
    Jnz     @F
    Mov     AX,DGROUP:ControlWord
    Mov     [SI],AX
    ;Ret

 @@:Ret
;----------------------------------------------------------------------


;----------------------------------------------------------------------
;   Test for the correct function based on AX (ie. Reg Part of instruction)
;   which was copied from DL in Emulator above.  These functions operate on
;   the instruction form "Ffunc ST(i)".
;----------------------------------------------------------------------
 FP_35_:                        ;Note: XX = Reserved

    Or      AX,AX               ;DL=0   FLD ST(i)
    Jnz     @F
    Call    P$Copy_TR           ;copy ST(i) to Temp_Real
    Jmp     P$Push_FP           ;Temp_Real to Stack Top

 @@:Dec     AX                  ;DL=1   FXCH ST(i)
    Jnz     @F
    Jmp     P$Xchg_TR

 @@:Dec     AX                  ;DL=2   determine the instruction based on DH
    ;(FNOP, XX,XX,XX,XX,XX,XX,XX)
    Je      FP_35_DL2

; @@:
    Dec     AX                  ;DL=3   FSTP ST(i)
    Jnz     @F
    Call    P$Xchg_TR
    Jmp     P$Pop_FP

 @@:Dec     AX                  ;DL=4   determine the instruction based on DH
    ;(FCHS, FABS, XX, XX, FTST, fxam, XX, XX)
    Je      FP_35_DL4

; @@:
    Dec     AX                  ;DL=5   determine the instruction based on DH
    ;(fld1, fldl2t, fldl2e, fldpi, fldlg2, fldln2, fldz, XX)
    Je      FP_35_DL5

; @@:
    Dec     AX                  ;DL=6   determine the instruction based on DH
    ;(f2xm1, fyl2x, fptan, fpatan, fxtract, XX, fdecstp, fincstp)
    Je      FP_35_DL6

; @@:
    Dec     AX                  ;DL=7   determine the instruction based on DH
    ;(fprem, fyl2xp1, fsqrt, XX, frndint, fscale, XX, XX)
    Je      FP_35_DL7

; @@:
    Ret
;----------------------------------------------------------------------



 FP_35_DL2:
;----------------------------------------------------------------------
; Test for the correct function based on DH (ie. Mem part of instruction)
;----------------------------------------------------------------------
    Mov     AL,DH
;----------------------------------------------------------------------
; These functions operate on the instruction form "Ffunc".
;----------------------------------------------------------------------

    Or      AX,AX               ;DL=0   FNOP
    ;Jnz     @F
    ;Nop

; @@:Dec     AX                  ;DL=1
;    ;reserved
; @@:Dec     AX                  ;DL=2
;    ;reserved
; @@:Dec     AX                  ;DL=3
;    ;reserved
; @@:Dec     AX                  ;DL=4
;    ;reserved
; @@:Dec     AX                  ;DL=5
;    ;reserved
; @@:Dec     AX                  ;DL=6
;    ;reserved
; @@:Dec     AX                  ;DL=7
;    ;reserved

; @@:
    Ret




 FP_35_DL4:
;----------------------------------------------------------------------
; Test for the correct function based on DH (ie. Mem part of instruction)
;----------------------------------------------------------------------
    Mov     AL,DH
;----------------------------------------------------------------------
; These functions operate on the instruction form "Ffunc".
;----------------------------------------------------------------------


    Or      AX,AX               ;DL=0   FCHS (ST)
    Jnz     @F
    Xor     Byte Ptr [DI+9],80h
    Ret

 @@:Dec     AX                  ;DL=1   FABS (ST)
    Jnz     @F
    And     Byte Ptr [DI+9],7Fh
    Ret
    
 @@:Dec     AX                  ;DL=2
    ;reserved
; @@:
    Dec     AX                  ;DL=3
    ;reserved

; @@:
    Dec     AX                  ;DL=4   FTST {ST,+0.0}
    Jnz     @F
    Call    P$Temp_Zero
    Mov     SI,Offset DGroup:Temp_Real
    Jmp     P$FP_COM

; @@:Dec     AX                  ;DL=5   fxam
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=6
;    ;reserved
; @@:Dec     AX                  ;DL=7
;    ;reserved

 @@:Ret
;----------------------------------------------------------------------




 FP_35_DL5:
;----------------------------------------------------------------------
; Test for the correct function based on DH (ie. Mem part of instruction)
;----------------------------------------------------------------------
    Mov     AL,DH
;----------------------------------------------------------------------
; These functions operate on the instruction form "Ffunc".
;----------------------------------------------------------------------

    Or      AX,AX               ;DL=0   FLD1
    Jnz     @F
    Call    P$Temp_Zero
    Mov     Word Ptr [Temp_Real+8],3FFFh
    Mov     Byte Ptr [Temp_Real+7],80h
    Jmp     P$Push_FP

 @@:Dec     AX                  ;DL=1   fld l2t
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=2   fld l2e
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=3   fld pi
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=4   fld lg2
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=5   fld ln2
    ;Jnz     @F
    ;unsupported 3/7/91

; @@:
    Dec     AX                  ;DL=6   FLDZ
    Jnz     @F
    Call    P$Temp_Zero
    Jmp     P$Push_FP

; @@:Dec     AX                  ;DL=7
;    ;reserved

 @@:Ret
;----------------------------------------------------------------------



 FP_35_DL6:
;----------------------------------------------------------------------
; Test for the correct function based on DH (ie. Mem part of instruction)
;----------------------------------------------------------------------
    Mov     AL,DH
;----------------------------------------------------------------------
; These functions operate on the instruction form "Ffunc".
;----------------------------------------------------------------------

;    Or      AX,AX               ;DL=0   f2xm1
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=1   fyl2x
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=2   fptan
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=3   fpatan
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=4   fxtract
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=5
;    ;reserved
;
; @@:Dec     AX                  ;DL=6   fdecstp
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=7   fincstp
;    ;Jnz     @F
;    ;unsupported 3/7/91

; @@:
    Ret
;----------------------------------------------------------------------



 FP_35_DL7:
;----------------------------------------------------------------------
; Test for the correct function based on DH (ie. Mem part of instruction)
;----------------------------------------------------------------------
    Mov     AL,DH
;----------------------------------------------------------------------
; These functions operate on the instruction form "Ffunc".
;----------------------------------------------------------------------

;    Or      AX,AX               ;DL=0   fprem
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=1   fyl2xp1
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=2   fsqrt
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=3
;    ;reserved
;
; @@:Dec     AX                  ;DL=4   frndint
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=5   fscale
;    ;Jnz     @F
;    ;unsupported 3/7/91
;
; @@:Dec     AX                  ;DL=6
;    ;reserved
; @@:Dec     AX                  ;DL=7
;    ;reserved

; @@:
    Ret

P$Int35     EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Int35_3C is called when a segment override is given with a P$Int35
;   instruction.  See P$Int3C.
;----------------------------------------------------------------------
P$Int35_3C     Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   A Carry here indicates a segment override on a stack operation.
;   In other words, the seg override is a wasted prefix and will be ignored!
;----------------------------------------------------------------------
    Jc      FP_35_

    Jmp     P$Int35

P$Int35_3C     EndP
;----------------------------------------------------------------------


;----------------------------------------------------------------------
;   P$Single_to_Temp converts the 4 byte Real at DS:BX to Temp_Real
;
;   Regs:   Destroyed   AX,DX
;   Flags:  Unknown
;----------------------------------------------------------------------
P$Single_to_Temp    Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
;   Clear Temp_Real to accept new data
;----------------------------------------------------------------------
    Call    P$Temp_Zero
    
;----------------------------------------------------------------------
;   Put the sign bit, exponent, and high mantissa bit of the Single in DX
;   for testing and bit shifting
;----------------------------------------------------------------------
    Mov     DX,[BX+2]
    Test    DX,7F80h                    ;test all the exponent bits
    Jz      @F                          ;if none are set it's zero

;----------------------------------------------------------------------
;   Re-arrange the bits according to the rule
;----------------------------------------------------------------------
    Mov     AL,DH                       ;the sign and 7 exponent bits
    Cbw                                 ;extend the sign bit
    Shl     DL,1                        ;the 8th exponent bit
    Rcl     AX,1                        ;into AX and throw away a sign bit

;----------------------------------------------------------------------
;   Temporary Reals do not imply the "1." from Singles and Doubles
;----------------------------------------------------------------------
    Stc                                 ;insert the "1." (was implied)
    Rcr     DL,1                        ;into the high mantissa byte

;----------------------------------------------------------------------
;   Increase the Single precision bias to Temp_Real bias
;----------------------------------------------------------------------
    And     AH,80h                      ;leave only the sign bit in AH
    Add     AX,(3FFFh-7Fh)              ;apply the new normalization

;----------------------------------------------------------------------
;   Store the converted portion in Temp_Real
;----------------------------------------------------------------------
    Mov     Word Ptr DGroup:[Temp_Real+8],AX    ;put it in Temp_Real expon.
    Mov     Byte Ptr DGroup:[Temp_Real+7],DL

;----------------------------------------------------------------------
;   Copy the low word of the mantissa to Temp_Real
;----------------------------------------------------------------------
    Mov     AX,[BX]
    Mov     Word Ptr DGroup:[Temp_Real+5],AX

;----------------------------------------------------------------------
;   Return.  (Exit label provided if Single Precision = 0)
;----------------------------------------------------------------------
 @@:RetN

P$Single_to_Temp    EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$Temp_to_Single extracts a 4-byte Real from Temp_Real to DS:BX
;
;   Regs:   Destroyed   AX,CX,DX
;   Flags:  Unknown
;----------------------------------------------------------------------
P$Temp_to_Single    Proc Near

    Assume  CS:PDQ_FP,  DS:Nothing, ES:DGROUP,  SS:DGROUP

;----------------------------------------------------------------------
; Put the high byte of the TR mantissa in AL for testing and bit shifting
;----------------------------------------------------------------------
    Xor     DX,DX                               ;to test for the implied "1."
    Or      DL,Byte Ptr DGROUP:[Temp_Real+7]    ;hi byte of mantissa
    Jns     Zero_Exit                           ;not there set true zero

    And     DL,7Fh                              ;clear the "1."
    Mov     AX,Word Ptr DGROUP:[Temp_Real+5]    ;low word of mantissa
    Mov     CX,Word Ptr DGROUP:[Temp_Real+8]    ;sign and exponent
    
;----------------------------------------------------------------------
; Try to round 4/18/91.  Default to RC = 0 (default)
;----------------------------------------------------------------------
    Cmp     Byte Ptr DGROUP:[Temp_Real+4],DH
    Jns     @F                  ;test MSB of insignif mant as "1/2" to round

    Add     AX,1                ;Round up lo 16 bits
    Adc     DL,DH               ;ripple hi 7 bits of mantissa
    Jno     @F                  ;do we adjust the exponent?

    Inc     CX                  ;yes

 @@:Sub     CX,(3FFFh-7Fh)      ;reduce the exponent bias
    Mov     DH,CL               ;expo in DH, CL is Trash
    Shl     DL,1                ;squeeze "1."   space @ LSB
    Shl     CH,1                ;sign out to CF, CH is Trash
    Rcr     DX,1                ;sign into DX   remove space @ LSB

 @@:Mov     [BX+2],DX           ;Label provided if TR = 0 or de-normal
    Mov     [BX],AX
    RetN

 Zero_Exit:                     ;force a 32 bit Real Zero
    Xor     AX,AX
    Cwd
    Jmp     @B

P$Temp_to_Single    EndP
;----------------------------------------------------------------------

    PDQ_FP      EndS

;======================================================================

END
