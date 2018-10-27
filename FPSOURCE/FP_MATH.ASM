;FP_MATH.ASM
;Copyright (c) 1990-1991 Crescent Software Inc.
;Written by Paul Passarelli

;   05/10/90    .000    Add & Subtract FP in Temp_Real
;   06/16/90    .001    Normalize, extracted 2/13/91
;   05/24/90    .002    Multiply
;   07/17/90    .003    Division
;   12/14/90    .004    B$DVI4
;   12/17/90    .005    P$10x
;   02/11/91    .006    Use full circular stack
;   03/01/91    .008    Reconstruct
;                       Merged FP_COM & P$AbsComp
;   03/21/91    .009    Normalize, returned
;   04/15/91    .010    Correct FP_COM for dual negative values
;   04/18/91    .011    Test for 0 in FP_MUL & FP_DIV (ie 0/1.34)
;   05/28/91    .012    Ensure FP_MUL clears ALL!!! product space.
;                       Have P$Normalize convert denormals to zero
;   07/16/91    .013    +0.000... + +0.000... = 0.0  Not exponent 1 !!!
;   12/13/91    .014    Increased precision in P$FP_DIV by only shifting out
;                       zero bits during the inner loop.
;                       Fixed Precision loss in P$FP_MUL
;   02/20/92    .015    Add 1/x test to P$FP_DIV
;
;======================================================================
; Public and External Symbols.
;----------------------------------------------------------------------
    Public          P$FP_ADD            ;Near Proc
    Public          P$FP_SUB            ;Near Proc
    Public          P$FP_MUL            ;Near Proc
    Public          P$FP_DIV            ;Near Proc
    Public          P$FP_COM            ;Near Proc
    Public          P$Normalize         ;Near Proc

    Extrn           P$DoError:Far       ;in DOERROR.ASM
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
    Extrn           Spare_Real      :TByte          ;in FP_STACK.ASM
    Extrn           Temp_Real       :TByte          ;in FP_STACK.ASM

    Extrn           StatusWord      :Word           ;in FP_STACK.ASM

    Extrn           P$PDQErr        :Word           ;in ERRDATA.ASM
;----------------------------------------------------------------------
    DSEG            ENDS
;======================================================================



;======================================================================
; USEG: Uninitialized Data.
;----------------------------------------------------------------------
    USEG            SEGMENT WORD    PUBLIC  'BSS'

    Reciprocal      DB  1 Dup(?)

    USEG            ENDS
;======================================================================



;======================================================================
; Code segment.
;----------------------------------------------------------------------
    PDQ_FP          SEGMENT WORD    PUBLIC  'CODE'
;----------------------------------------------------------------------
    ASSUME  CS:PDQ_FP
;----------------------------------------------------------------------
    Extrn       P$PUSH_FP       :Near   ;in FP_STACK.asm
    Extrn       P$POP_FP        :Near   ;in FP_STACK.asm
    Extrn       P$Temp_Zero     :Near   ;in FP_STACK.asm
    Extrn       P$Copy_TR       :Near   ;in FP_STACK.asm
    Extrn       P$Xchg_TR       :Near   ;in FP_STACK.asm

;----------------------------------------------------------------------



;----------------------------------------------------------------------
; P$FP_SUB  Subtracts FP numbers.
;
;   Input:  ES:[DI], DS:[SI]
;   Result: ES:[DI] = ES:[DI] ñ DS:[SI]  (may require P$Normalize)
;   Assume: Valid numbers, result may exceed QB capabilities
;   RegS:   Destroyed AX BX CX SI
;   Flags:  Unknown
;----------------------------------------------------------------------
P$FP_SUB    Proc Near               ;ES:[DI] = ES:[DI] - DS:[SI]

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
    Call    P$Copy_TR               ;expendable copy of the second operator
                                    ;in Temp_Real and DS:[SI]
;----------------------------------------------------------------------

;----------------------------------------------------------------------
    Xor     Byte Ptr [Temp_Real+9],80h  ;Changing the sign of the second
                                        ; operator makes P$FP_ADD subtract.

   ;Jmp    Short P$FP_ADD           ;not needed, falls into P$FP_ADD
;----------------------------------------------------------------------



;----------------------------------------------------------------------
; P$FP_ADD  Adds FP numbers.
;
;   Input:  ES:[DI], DS:[SI]
;   Result: ES:[DI] = ES:[DI] ñ DS:[SI]  (may require P$Normalize)
;   Assume: Valid numbers, result may exceed QB capabilities
;   RegS:   Destroyed AX BX CX SI
;   Flags:  Unknown
;----------------------------------------------------------------------
P$FP_ADD    Proc Near               ;ES:[DI] = ES:[DI] + DS:[SI]

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
    Call    P$Copy_TR               ;expendable copy of the second operator
                                    ;in Temp_Real and DS:[SI]
;----------------------------------------------------------------------

;----------------------------------------------------------------------
; Compare the operators by absolute magnitude.  Difference in magnitude
; is returned in CX.
;----------------------------------------------------------------------
    Call    P$AbsComp    ;[di],tempreal[SI]    ;compare by absolute magnitude

    Jb      Swap_Ops                ;³Dest³ < ³Source³  reverse 'em

    Ja      Compute_Shift           ;³Dest³ > ³Source³  O.K. (for now)

;----------------------------------------------------------------------
; Fast equality routine here. ( 2x or Zero) 12/17/90
;----------------------------------------------------------------------
    Mov     AX,[DI+8]
    Xor     AX,Word Ptr [Temp_Real+8]
    Js      Subtractive_Zero        ;label to use existing code sequence

    Or      AX,Word Ptr [Temp_Real+8]   ;we know AX = 0
    Jz      @F                          ;0.0 + 0.0 = 0.0  Not exponent 1 !!!

    Inc     Word Ptr [DI+8]         ;assume addition result = 2x
@@:
    RetN                            ;the mantissa is still normal

;----------------------------------------------------------------------
; if ³Dest³ < ³Temp_Real³ then switch the values
;----------------------------------------------------------------------
 Swap_Ops:
    Call    P$Xchg_TR
    Neg     CX                      ;CX was negative, change its sign

;----------------------------------------------------------------------
; Is it nessasary to proceed with the calculation?
;----------------------------------------------------------------------
 Compute_Shift:
    Cmp     CX,64
    Jb      OKtoShift               ;Yes.
    RetN                            ;No, Temp_Real insignificant by magnitude

;----------------------------------------------------------------------
; De-normalize the mantissa of Temp_Real by CX places
;----------------------------------------------------------------------
 OKtoShift:
    Mov     BX,SI
    Clc
    Call    RightShifter

;----------------------------------------------------------------------
; Determine similarity or difference of the signs of the operators
;----------------------------------------------------------------------
    Mov     AL,Byte Ptr[DI+9]
    Xor     AL,Byte Ptr[Temp_Real+9]
    Jns     Similar                 ;are the signs the same or different

    Call    SubMantissa
    Jnz     Complete_Op

;----------------------------------------------------------------------
; Force a full zero if necessary.
;----------------------------------------------------------------------
 Subtractive_Zero:                  ;label for fast equality routine above
    Call    P$Temp_Zero
    Call    P$Xchg_TR
    RetN

;----------------------------------------------------------------------
; Perform the addition
;----------------------------------------------------------------------
 Similar:
    Call    AddMantissa
    Jnc     Complete_Op             ;test for an increase in magnitude
    
;----------------------------------------------------------------------
; The sum requires a higher power of 2.
;----------------------------------------------------------------------
    Mov     BX,DI
    Inc     Word Ptr[BX+8]          ;increase the exponent
    Inc     CX                      ;CX is known to be zero
    Call    RightShifter            ;put the carry back into the mantissa

;----------------------------------------------------------------------
; Finish the operation
;----------------------------------------------------------------------
 Complete_Op:
    Mov     BX,DI
    Call    P$Normalize             ;typically FP_ST
    RetN

P$FP_ADD    EndP
P$FP_SUB    EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------
;   P$FP_MUL Multiplication routine for FP numbers.
;            64-bit quantities [SI]*[DI]=[Temp_Real-8] (unsigned).
;
;   Input:  ES:[DI], DS:[SI]
;   Result: ES:[DI] = ES:[DI] * DS:[SI]  (may require P$Normalize)
;   Assume: Valid numbers are on the stack and in Temp_Real
;           result may exceed QB capabilities
;   Regs:   Destroyed AX BX CX DX SI DI BP
;   Flags:  Unknown
;
P$FP_MUL    Proc Near              ;Result = ST * Temp_Real

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
; Make an expendable copy of the second operator if necessary.
;----------------------------------------------------------------------
    Call    P$Copy_TR               ;DI = DEST, SI = Temp_Real

    Xchg    DI,SI                   ;SI = DEST, DI = Temp_Real
    Xor     BP,BP                   ;keep a zero handy for clearing
    Mov     Word Ptr[Temp_Real-2],BP
    Mov     Word Ptr[Temp_Real-4],BP
    Mov     Word Ptr[Temp_Real-6],BP
    Mov     Word Ptr[Temp_Real-8],BP    ;too small to be significant


    Mov     CX,Word Ptr[Temp_Real+8]
    Jcxz    Times0

    Mov     CX,Word Ptr[SI+8]
    Inc     CX                      ;
    Loop    @F                      ;Jcxnz  @@: (if you will)
    
 Times0:
    Call    P$Temp_Zero
    Jmp     P$Xchg_TR               ;we're out-a-here

 @@:
;----------------------------------------------------------------------
; Multiply the 64-bit mantissas
;----------------------------------------------------------------------
    Push    SI
    Mov     CX,Word Ptr [Temp_Real+0]
    Push    Word Ptr [Temp_Real+2]
    Pop     Word Ptr [Spare_Real]

    Mov     Word Ptr[Temp_Real+0],BP
    Mov     Word Ptr[Temp_Real+2],BP
    Jcxz    @F
    
    Lodsw
    Mul     CX
    Mov     Word Ptr[Temp_Real-8],AX            ;too small to be significant
    Mov     Word Ptr[Temp_Real-6],DX
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real-6],AX
    Adc     Word Ptr[Temp_Real-4],DX
    Adc     Word Ptr[Temp_Real-2],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real-4],AX
    Adc     Word Ptr[Temp_Real-2],DX
    Adc     Word Ptr[Temp_Real+0],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real-2],AX
    Adc     Word Ptr[Temp_Real+0],DX
    Adc     Word Ptr[Temp_Real+2],BP
 @@:Pop     SI

;----------------------------------------------------------------------
    Push    SI
    Mov     CX,Word Ptr [Spare_Real]
    Push    Word Ptr [Temp_Real+4]
    Pop     Word Ptr [Spare_Real]

;    Mov     Word Ptr[Temp_Real+2],BP
    Mov     Word Ptr[Temp_Real+4],BP
    Jcxz    @F

    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real-6],AX
    Adc     Word Ptr[Temp_Real-4],DX
    Adc     Word Ptr[Temp_Real-2],BP
    Adc     Word Ptr[Temp_Real+0],BP
    Adc     Word Ptr[Temp_Real+2],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real-4],AX
    Adc     Word Ptr[Temp_Real-2],DX
    Adc     Word Ptr[Temp_Real+0],BP
    Adc     Word Ptr[Temp_Real+2],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real-2],AX
    Adc     Word Ptr[Temp_Real+0],DX
    Adc     Word Ptr[Temp_Real+2],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real+0],AX
    Adc     Word Ptr[Temp_Real+2],DX
    Adc     Word Ptr[Temp_Real+4],BP
 @@:Pop     SI

;----------------------------------------------------------------------
    Push    SI
    Mov     CX,Word Ptr [Spare_Real]
    Push    Word Ptr [Temp_Real+6]
    Pop     Word Ptr [Spare_Real]


;    Mov     Word Ptr[Temp_Real+4],BP
    Mov     Word Ptr[Temp_Real+6],BP
    Jcxz    @F

    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real-4],AX
    Adc     Word Ptr[Temp_Real-2],DX
    Adc     Word Ptr[Temp_Real+0],BP
    Adc     Word Ptr[Temp_Real+2],BP
    Adc     Word Ptr[Temp_Real+4],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real-2],AX
    Adc     Word Ptr[Temp_Real+0],DX
    Adc     Word Ptr[Temp_Real+2],BP
    Adc     Word Ptr[Temp_Real+4],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real+0],AX
    Adc     Word Ptr[Temp_Real+2],DX
    Adc     Word Ptr[Temp_Real+4],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real+2],AX
    Adc     Word Ptr[Temp_Real+4],DX
    Adc     Word Ptr[Temp_Real+6],BP
 @@:Pop     SI

;----------------------------------------------------------------------
    Push    SI
    Mov     CX,Word Ptr [Spare_Real]

;    Mov     Word Ptr[Temp_Real+6],BP
    Jcxz    @F

    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real-2],AX
    Adc     Word Ptr[Temp_Real+0],DX
    Adc     Word Ptr[Temp_Real+2],BP
    Adc     Word Ptr[Temp_Real+4],BP
    Adc     Word Ptr[Temp_Real+6],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real+0],AX
    Adc     Word Ptr[Temp_Real+2],DX
    Adc     Word Ptr[Temp_Real+4],BP
    Adc     Word Ptr[Temp_Real+6],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real+2],AX
    Adc     Word Ptr[Temp_Real+4],DX
    Adc     Word Ptr[Temp_Real+6],BP
    Lodsw
    Mul     CX
    Add     Word Ptr[Temp_Real+4],AX
    Adc     Word Ptr[Temp_Real+6],DX
 @@:Pop     SI   ;Wham!

;----------------------------------------------------------------------
    Xchg    SI,DI                   ;DI = DEST, SI = Temp_Real

    Mov     AX,[DI+8]
    Mov     DX,Word Ptr[Temp_Real+8]
    Mov     BL,AH
    Add     AX,DX
    Sub     AX,(3FFFh - 1)
    Xor     BL,DH
    Js      Product_Negative

 Product_Positive:
    And     AH,7Fh                  ;clear the sign bit
    Jmp Short Mul_Adj

 Product_Negative:
    Or      AH,80h                  ;set the sign bit

 Mul_Adj:
    Mov     Word Ptr[Temp_Real+8],AX
    Call    P$Xchg_TR

    Mov     BX,DI
    Call    P$Normalize             ;FP_ST
    Ret
P$FP_MUL    EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------------
; Division routine for FP numbers.
;
;       Input:  ES:DI ö DS:SI
;       Result: ES:DI = Quotient (passed on to P$Normalize)
;               Divide by zero = Interrupt 0!
;       Assume: No segment boundary is spanned.
;               Result may exceed QB capabilities
;       Regs:   Destroyed AX BX CX DX SI DI
;       Flags:  Unknown
;
P$FP_DIV    Proc Near               ;Result = ST0 / Temp_Real

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
; Make an expendable copy of the second operator if necessary.
;----------------------------------------------------------------------
    Call    P$Copy_TR

;----------------------------------------------------------------------
; Test for Zero Divisor.
;----------------------------------------------------------------------
    Or      Word Ptr[Temp_Real+8],0
    Jnz     Divisor

    Mov     Word Ptr [DI+8],0FFFFh
    Mov     Byte Ptr [DI+7],0C0h

    Mov     Word Ptr P$PDQErr,11    ;the error code for division by zero
    Call    P$DoError               ;if ON ERROR is in effect, trip it

    Jmp     Exit                    ;was Int 0

 Divisor:

;----------------------------------------------------------------------
; Test for Zero Dividend.
;----------------------------------------------------------------------
    Or      Word Ptr[DI+8],0
    Jnz     Dividend
    Call    P$Temp_Zero
    Jmp     P$Xchg_TR

 Dividend:

;----------------------------------------------------------------------
;   Create stack frame and local storage.
;----------------------------------------------------------------------
    Push    BP                      ;preserve BP
    Push    BP                      ;local variable
    Mov     BP,SP                   ;local pointer


;----------------------------------------------------------------------
;   Clear the quotient space
;----------------------------------------------------------------------
    Mov     [BP],DI
    Mov     DI,Offset DGroup:Spare_Real
    Mov     CX,5
    Xor     AX,AX
    Rep     StoSw

    Mov     Byte Ptr Reciprocal,0

    
;----------------------------------------------------------------------
; We'll use BX to write the Quotient as is accumulates. (was DI)
;----------------------------------------------------------------------
    Mov     BX,Offset DGroup:[Spare_Real+6] ;the MSW of the quotient

;----------------------------------------------------------------------
; Set up the outer loop
;----------------------------------------------------------------------
    Mov     CX,4                    ;count 4 words
 Quad_Loop:
    Push    CX                      ;save the word counter
    Push    BX                      ;save the quotient pointer
    Xor     DX,DX                   ;DX accumulates bits of success/failure

;----------------------------------------------------------------------
; Set up the inner loop
;----------------------------------------------------------------------
        Mov     CX,16                   ;count 16 bits each word
     Word_Loop:                         ;begin nested loop
        Mov     DI,[BP]                 ;local copy of Dest
        Mov     SI,Offset DGROUP:Temp_Real

        Push    DX
        Call    SubMantissa
        Pop     DX

        Cmc
        Rcl     DX,1                    ;this is the new LSB
        Test    DX,1                    ;did we have a "1" or a "0"
        Jnz     Zero_Shift

        Push    DX
        Call    AddMantissa             ;undo the subtraction
        Pop     DX

     Zero_Shift:
        Call    Comp_Dividend_Zero
        Jnz     Reduce_Divisor

        Jmp     Exit_Quad_Loop


     Reduce_Divisor:
        Or      Byte Ptr Reciprocal,0
        Jnz     via_Rx_Divisor

        Test    Byte Ptr DGroup:Temp_Real,1
        Jnz     via_Lx_Dividend

     via_Rx_Divisor:
        Shr     Word Ptr[Temp_Real+6],1
        Rcr     Word Ptr[Temp_Real+4],1
        Rcr     Word Ptr[Temp_Real+2],1
        Rcr     Word Ptr[Temp_Real],1
        Jmp     @F

     via_Lx_Dividend:
        Shl     Word Ptr [DI],1
        Rcl     Word Ptr [DI+2],1
        Rcl     Word Ptr [DI+4],1
        Rcl     Word Ptr [DI+6],1

        Jnc     @F                  ;1/x test

        Call    Comp_Dividend_Zero
        Jnz     @F

        Stc                         ;undo the Lx_Dividend
        Rcr     Word Ptr [DI+6],1
        Rcr     Word Ptr [DI+4],1
        Rcr     Word Ptr [DI+2],1
        Rcr     Word Ptr [DI],1
        Mov     Byte Ptr Reciprocal,-1
        Jmp     via_Rx_Divisor
        
        
     @@:
        Loop    Word_Loop               ;end nested loop
;----------------------------------------------------------------------

    Pop     BX
    Pop     CX
    Mov     [BX],DX                 ;apply DX to the quotient
    Dec     BX                      ;point to the lower word of the quotient
    Dec     BX

    Loop    Quad_Loop               ;end outer loop

    Jmp Short Quotient_Sign         ;we finished OK


 Exit_Quad_Loop:

    Dec     CL
    Shl     DX,CL                   ;shove bits in DX the rest of the way
    Pop     BX                      ;recover quotient pointer from stack
    Pop     AX                      ;discard CX from stack
    Mov     [BX],DX                 ;apply DX to the quotient

;----------------------------------------------------------------------
; Determine the sign for the quotient.
;----------------------------------------------------------------------
 Quotient_Sign:
    Mov     SI,[BP]
    Mov     AX,[SI+8]                   ;dividend sign
    Mov     DX,Word Ptr[Temp_Real+8]    ;divisor sign
    Mov     BL,AH
    Sub     AX,DX
    Add     AX,3FFFh                    ;re-introduce the bias
    Xor     BL,DH
    Js      Quotient_Negative

 Quotient_Positive:
    And     AH,7Fh
    Jmp Short Div_Adj

 Quotient_Negative:
    Or      AH,80h
 Div_Adj:
    Mov     Word Ptr[Spare_Real+8],AX

    Mov     BX,SI                       ;put in BX now for P$Normalize
    Mov     DI,SI
    Mov     SI,Offset DGROUP:Spare_Real
    Mov     CX,5
    Rep     MovSw
    Call    P$Normalize

    Pop     BP                          ;undo local variable
    Pop     BP                          ;restore BP

 Exit:
    Ret


Comp_Dividend_Zero:         ;Returns w/ ZR|NZ Trashes AX
    Mov     AX,[DI]
    Or      AX,[DI+2]
    Or      AX,[DI+4]
    Or      AX,[DI+6]
    Retn

P$FP_DIV EndP



;----------------------------------------------------------------------------
;   P$FP_COM    Routine equivalent to  "CMP  Temp_Real,ST0"
;               sets flags for conditional JMP.
;
;   Input:  ES:[DI], DS:[SI]
;   Result: Flags set for conditional jump
;   Assume: Valid numbers. not "NAN" or "Proj. Inf."
;   Regs:   Destroyed AX CX SI DI
;   Flags:  Net result of a signed comparison.
;
P$FP_COM    Proc Near

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
; Make an expendable copy of the second operator if necessary.
;----------------------------------------------------------------------
    Call    P$Copy_TR
    
;----------------------------------------------------------------------

    Xchg    DI,SI           ;switch for CmpSb
    Std                     ;work from the most to least significant byte
    Mov     CX,9

    Add     DI,+9
    Add     SI,+9

    Mov     AH,[SI]         ;was ES:[DI+9]
    Mov     AL,[DI]         ;was DS:[SI+9]

    Xor     AL,AH           ;test for identical signs
    Jns     SameSign

    Xor     AL,AH           ;was AL or AH originally signed?
   ;Js      Signed          ;AL, so DS:SI was negative.  ES:DI > DS:SI

   ;Xchg    AH,AL           ;AH, so, exchange Less Than for Greater Than
 Signed:
    Cmp     AL,AH           ;force the signed compare
    Jmp Short Compared

 SameSign:
;----------------------------------------------------------------------
    Or      AH,AH
    Jns     @F              ;both positive
    Xchg    DI,SI           ;switch for CmpSb
 @@:
;----------------------------------------------------------------------

    Cmpsb                   ;1 byte to Dec SI and DEC DI, Ignore Sign.
    Jne     Compared

 Comp_Mant:
    RepE    Cmpsb           ;line 'em up

 Compared:
    Cld                     ;put it back the way BASIC wants it
    Lahf
    Mov     StatusWord,AX   ;1/14/91
    Ret

P$FP_COM EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------------
;   Routine to normalize the ten byte real value at DS:BX to proper 80x87
;   Temporary Real format (see below).  Used by Add, Sub, Mul, Div, and
;   Integer conversion routines.
;
;   Temp Real Format:
;   S³EEEEEEEEEEEEEEE³1³MMMMMMMMMMMMMMMMMMM...(total 63 "M" Mantissa bits)
;
;      Input:  DS:BX points to biased Temporary Real (possibly de-normalized)
;      Result: Normalized TByte value at DS:BX
;      Assume: NOT  "NAN" or "Projective Infinity"
;      Regs:   Unchanged (preserved)
;      Flags:  Unchanged (preserved)
;
;----------------------------------------------------------------------
P$Normalize Proc Near

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
    Push    AX
    Push    CX
    Push    DX
    Push    SI
    Push    DI
    PushF

    Xor     AX,AX
    Or      AX,Word Ptr[BX+6]           ;set flags for MSW (mant)
    Js      Function_Exit               ;MSB is set (1), we're done.

    Mov     SI,Word Ptr[BX+4]           ;mantissa in registers for speed
    Mov     DI,Word Ptr[BX+2]
    Mov     DX,Word Ptr[BX]

    Or      AX,SI                       ;test for non zero mantissa
    Or      AX,DI
    Or      AX,DX
    Jnz     Left_Shifter_0              ;we're OK

    Or      AX,Word Ptr[BX+8]           ;test for non zero exponent
    Jz      Function_Exit               ;Function_Zero

    Dec     Word Ptr[BX+8]
    Jz      Denormal

    Or      Byte Ptr[BX+7],80h
    Jmp Short Function_Exit

 Left_Shifter_0:
    Mov     AX,Word Ptr[BX+6]           ;re-establish AX from the NZ test
    Xor     CX,CX
    Dec     CX
 Left_Shifter:
    Shl     DX,1                        ;DX = [BX]  (lsw)
    Rcl     DI,1                        ;DI = [BX+2]
    Rcl     SI,1                        ;SI = [BX+4]
    Rcl     AX,1                        ;AX = [BX+6](msw)
    Jo      Left_Shift_Expo
    Loop    Left_Shifter                ;CX accumulates left shift negatively

 Left_Shift_Expo:
    Add     Word Ptr[BX+8],CX           ;return the exponent to the TByte
    Jnz     Completly_Normal            ;test for zero exponent

 Denormal:
    Xor     AX,AX
    Mov     Word Ptr[BX+6],AX           ;exponent is 0, mant may be denormal
    Mov     Word Ptr[BX+4],AX           ; Kill the entire number to zero
    Mov     Word Ptr[BX+2],AX           ; Sorry folks, I can't do the reduced
    Mov     Word Ptr[BX],AX             ; precision without bloating the code.
    Jmp Short Function_Exit

 Completly_Normal:
    Mov     Word Ptr[BX],DX             ;return the registers to the TByte
    Mov     Word Ptr[BX+2],DI
    Mov     Word Ptr[BX+4],SI
    Mov     Word Ptr[BX+6],AX

 Function_Exit:
    PopF
    Pop     DI
    Pop     SI
    Pop     DX
    Pop     CX
    Pop     AX
    
    Ret
P$Normalize EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------------
; P$AbsComp compares [DI] to [SI] by absolute magnitude
;
;   Input:  Temp Reals pointed to by ES:DI and DS:SI
;   Result: CX = difference in magnitude
;           Flags ready for conditional jump
;   Assume: Valid numbers. not "NAN" or "Proj. Inf."
;   Regs:   Others Unchanged
;   Flags:  Net result of a signed comparison
;----------------------------------------------------------------------
P$AbsComp   Proc Near

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
    Push    DX
    Push    SI
    Push    DI

    Xchg    SI,DI
    Add     SI,6                ;set up for CmpSW
    Add     DI,6
    Std

    Mov    CX,[SI+2]            ;here we need the exponents
    Mov    DX,[DI+2]

    And    CH,7Fh               ;lose the sign bits
    And    DH,7Fh               ;for absolute magnitude

    Sub    CX,DX                ;to return the shift count

    Jne    @F
    ;Ja    ³Dest³ >> ³Source³
    ;Jb    ³Dest³ << ³Source³

    Cmpsw
    Jne    @F

    Cmpsw
    Jne    @F

    Cmpsw
    Jne    @F

    Cmpsw                       ;³Dest³ {">", "<", "="} ³Source³

 @@:Cld

    Pop     DI
    Pop     SI
    Pop     DX
    Ret

    ;Notes:
    ;12/17/90   to determine the need to swap operands in P$FP_ADD.
    ;03/01/91   generic operands [DI], [SI]
P$AbsComp EndP



;----------------------------------------------------------------------------
; Performs place alignment of mantissa for addition or subtraction.
;
;       Input:  BX pointing to the 64-bit mantissa
;               CX number of bits to shift
;               CF Carry Flag will be shifted into the mantissa
;       Result: Aligned de-normalized mantissa
;       Assume: no segment boundary is spanned
;       Regs:   CX = 0
;       Flags:  NC if input CX <> 0, unchanged if CX = 0
;               others unchanged
;
RightShifter    Proc Near

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
    Jcxz   No_Right_Shift
 Right_Shift:
    Rcr    Word Ptr[BX+6],1
    Rcr    Word Ptr[BX+4],1
    Rcr    Word Ptr[BX+2],1
    Rcr    Word Ptr[BX],1
    Clc
    Loop   Right_Shift
 No_Right_Shift:
    Ret
RightShifter    EndP
;----------------------------------------------------------------------



;----------------------------------------------------------------------------
; Routines to add or subtract 64 bit (ones complement) mantissas.
;
;       Input:  ES:DI ñ DS:SI point to the source operands
;       Result: ES:DI = Sum or Difference
;       Assume: Valid numbers
;       Regs:   Destroyed AX BX DX
;       Flags:  Set by last (MSW) "ADC" or "SBB"
;               Others unknown
;
Mant_Add_Sub    Proc Near

    ASSUME  CS:PDQ_FP,  DS:DGROUP,  ES:DGROUP, SS:DGROUP

;----------------------------------------------------------------------
    Push    CX
    Push    SI
    Push    DI

;----------------------------------------------------------------------
; Setup the pointers and loop counter
;----------------------------------------------------------------------
    Mov     BX,SI           ;DS:BX ==> Temp_Real
    Mov     SI,DI           ;ES:DI & DS:SI ==> Destination

    Mov     CX,4
    Clc                     ;clear for first addition
    

;----------------------------------------------------------------------
; Top of Loop.
;----------------------------------------------------------------------
 Mant_Word:
    Lodsw                   ;get the Dest word in AX
    Jmp     DX              ;"ADC" or "SBB"  based upon point of entry

;----------------------------------------------------------------------
; Add or Subtract accordingly
;----------------------------------------------------------------------
 xADC::                     ; Label Byte
    Adc     AX,[BX]
    Jmp Short @F
 xSBB::                     ; Label Byte
    Sbb     AX,[BX]
 @@:

;----------------------------------------------------------------------
; Complete the Loop
;----------------------------------------------------------------------
    Stosw                   ;store the result
    Inc     BX              ;have BX point to the next Temp_Real word
    Inc     BX
    Loop    Mant_Word

;----------------------------------------------------------------------

    Pop     DI
    Pop     SI
    Pop     CX
    RetN

AddMantissa     Proc Near        ;ADD [SI+n],[BX+n]
    Mov    DX,Offset PDQ_FP:xADC ;addition instruction
    Jmp Short Mant_Add_Sub

SubMantissa     Proc Near        ;SUB [SI+n],[BX+n]

    Mov    DX,Offset PDQ_FP:xSBB ;subtract instruction
    Jmp Short Mant_Add_Sub

SubMantissa     EndP
AddMantissa     EndP
Mant_Add_Sub    EndP
;----------------------------------------------------------------------

    PDQ_FP          EndS
;======================================================================

END
