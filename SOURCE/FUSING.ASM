; FUSING - Copyright (c) 1989 by Chris May                     (3/1/1989)
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Function to format a number similar to "USING" statement            ³
;³                                                                      ³
;³  DECLARE FUNCTION FUsing$ (Number$, Image$)                          ³
;³  Image$ = "####.####"                                                ³
;³  X$ = FUsing$ (STR$(X), Image$)                                      ³
;³                                                                      ³
;³  where  STR$(X)  = passed string to be formatted                     ³
;³                                                                      ³
;³  Note:  It is very important that the number be input in this        ³
;³         manner, since this format is required.                       ³
;³                                                                      ³
;³         Image$   = format required for string                        ³
;³                                                                      ³
;³ The following string formats are supported:                          ³
;³                                                                      ³
;³ CHARACTER   DESCRIPTION                                              ³
;³                                                                      ³
;³     #       Represents each digit position                           ³
;³                                                                      ³
;³     .       Gives a decimal point                                    ³
;³                                                                      ³
;³     +       Causes the sign of the number to be used.                ³
;³              The sign must occur at the start of the field           ³
;³                                                                      ³
;³    **       Causes leading spaces in the field to be filled          ³
;³              with asterisks                                          ³
;³                                                                      ³
;³    $$       Causes a dollar sign to be placed to the immediate       ³
;³              left of the formatted number                            ³
;³                                                                      ³
;³   **$       Combines the effects of ** and $$                        ³
;³                                                                      ³
;³     ,       Causes a comma to be placed to the left of every         ³
;³              third digit left of the decimal point. The comma        ³
;³              may appear anywhere within the numeric field.           ³
;³                                                                      ³
;³     %       If the number will not fit in the Image then the         ³
;³              leftmost character in the formatted string will         ³
;³              be a % sign.                                            ³
;³                                                                      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

.MODEL medium, Basic
.Data?
   Buffer DB 50 Dup (?)       ;the output is stored here

.DATA

   ADPI            DB    ?    ;no. of places after dec. pt. in Image$
   ADPS            DB    ?    ;no. of places after dec. pt. in STR$(X)
   Asterisk        DB    ?    ;"*" if ** in Image$, otherwise " "
   BDPI            DB    ?    ;no. of places before dec. pt. in Image$
   BDPS            DB    ?    ;no. of places before dec. pt. in STR$(X)
   Carry           DB    ?    ;carry flag
   Comma           DB    ?    ; = 1 if comma otherwise 0
   CommaCount      DB    ?    ;counter for insertion of commas
   Dollar          DB    ?    ; = 1 if $ sign otherwise 0
   Exponent        DB    ?    ;contains value of exponent
   IDecimal        DB    ?    ; = 1 if "." in Image$ otherwise 0
   IPlus           DB    ?    ; = 1 if + sign in Image$
   SDecimal        DB    ?    ; = 1 if "." in STR$(X) otherwise 0
   SPlus           DB    ?    ;"+" or "-" according to sign of STR$(X)
   IStart          DW    ?    ;contains start address of Image$

.CODE

FUsing Proc Far, Strg:Word, Image:Word

   Mov    ADPI,0              ;initial value
   Mov    ADPS,0              ;initial value
   Mov    Asterisk," "        ;assume space initially
   Mov    BDPI,0              ;initial value
   Mov    BDPS,0              ;initial value
   Mov    Carry,0             ;initial value
   Mov    Comma,0             ;initial value
   Mov    CommaCount,0        ;initial value
   Mov    Dollar,0            ;initial value
   Mov    Exponent,0          ;initial value
   Mov    IDecimal,0          ;initial value
   Mov    IPlus,0             ;initial value
   Mov    SDecimal,0          ;initial value
   Mov    SPlus,"+"           ;assume "+" initially
   Mov    SI,Image            ;get address of Image$
   Mov    CX,[SI]             ;put length of Image$ into CX
   Mov    SI,[SI+02]          ;load first character address of Image$

   Cld                        ;string moves will be in the forward direction

   Jcxz   Invalid             ;Image$ is invalid if of length zero
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the character
   Cmp    AL,"+"              ;is it a plus sign ?
   Jne    Done_Sign           ;no, okay as is
   Inc    IPlus               ;set sign flag
   Jcxz   Invalid             ;invalid since string not long enough
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the character

Done_Sign:

   Cmp    AL,"$"              ;is it a "$" ?
   Jne    Isit_Star           ;no, check for asterisk

   Jcxz   Invalid             ;invalid if only one "$" and CX is zero
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the current character
   Cmp    AL,"$"              ;is the next character a "$" also ?
   Jne    Invalid             ;no, so invalid since two "$" signs required

   Mov    Dollar,1            ;yes, set the Dollar flag
   Mov    BDPI,1              ;one usable field space with "$$"
   Jcxz   Search_Strg         ;finished checking the string ?
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the character

Isit_Star:

   Cmp    AL,"*"              ;is it a "*" ?
   Jne    Isit_Comma          ;no, check for comma

   Jcxz   Invalid             ;string must have two "*" to be valid
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the current character
   Cmp    AL,"*"              ;is the next character a "*" also ?
   Jne    Invalid             ;string must have two "*" to be valid

   Mov    Asterisk,"*"        ;yes, set the asterisk
   Mov    BDPI,2              ;two usable field spaces with "**"

   Jcxz   Search_Strg         ;finished checking the string ?
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the current character
   Cmp    AL,"$"              ;does a "$" sign follow "**" ?
   Jne    Isit_Comma          ;no, so check for comma
   Mov    Dollar,1            ;yes, set the Dollar flag
   Jcxz   Search_Strg         ;finished checking the string ?
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the current character

Isit_Comma:

   Cmp    AL,","              ;is it a "," ?
   Jne    Isit_Pound          ;no, check for pound

   Inc    Comma               ;yes, set comma flag
   Inc    BDPI                ; and add one more to BDPI
   Jcxz   Search_Strg         ;finished checking the string ?
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the current character

Isit_Pound:

   Cmp    AL,"#"              ;is it a "#" ?
   Jne    Isit_Decimal        ;no, check for decimal

   Cmp    IDecimal,0          ;have we reached a decimal point yet ?
   Je     Add2BDPI            ;no, so add to BDPI
   Inc    ADPI                ;yes, so add to ADPI instead
   Jcxz   Search_Strg         ;finished checking the string ?
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the current character
   Jmp    Isit_Comma          ;check for decimal

Invalid:

   Jmp    Exit1               ;if here then the parsed Image was invalid

Add2BDPI:

   Inc    BDPI
   Jcxz   Search_Strg         ;finished checking the string ?
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the current character
   Jmp    Isit_Comma

Isit_Decimal:

   Cmp    AL,"."              ;is it a "." ?
   Jne    Invalid             ;no, then nothing else acceptable

   Mov    IDecimal,1          ;set the decimal flag
   Jcxz   Search_Strg         ;finished checking the string ?
   Dec    CL                  ;put counter on next character
   Lodsb                      ;load the current character
   Jmp    Isit_Comma          ;go back and check for comma

Search_Strg:

   Mov    SI,Strg             ;get address of STR$(X)
   Mov    CX,[SI]             ;put length of STR$(X) into CX
   Mov    SI,[SI+02]          ;get address of first character of STR$(X)
   Xor    BL,BL               ;set exponent value to zero initially
   Lodsb                      ;load the sign
   Dec    CL                  ;decrease length accordingly
   Cmp    AL,"-"              ;is it a minus sign ?
   Jne    Next_Char           ;no, so leave SPlus alone and continue
   Mov    SPlus,"-"           ;yes, change SPlus to minus

Next_Char:

   Jcxz   Strg_Search_Done    ;end of Strg so must be done
   Dec    CL                  ;decrease counter
   Lodsb                      ;load next character
   Cmp    AL,"."              ;is it a "." ?
   Je     Got_SDecimal        ;yes
   Cmp    AL,"D"              ;is it exponent ?
   Jae    Got_Exponent        ;yes
   Cmp    SDecimal,0          ;have we found the decimal point yet ?
   Jne    Add2ADPS            ;yes, so add to ADPS
   Inc    BDPS                ;no, so add to BDPS instead
   Jmp    Next_Char           ;any more ?

Add2ADPS:

   Inc    ADPS
   Jmp    Next_Char           ;any more ?

Got_SDecimal:

   Mov    SDecimal,1          ;there is a decimal point in Strg so set flag
   Jmp    Next_Char           ; and check the next

Got_Exponent:

   Lodsb                      ;load the exponent sign
   Cmp    AL,"-"              ;is exponent negative ?
   Jne    Find_Exp_Value      ;no, so leave flag as is
   Inc    Exponent            ;set flag for negative exponent

Find_Exp_Value:

   Xor    AH,AH               ;clear AH
   Lodsb                      ;load character
   Sub    AL,48               ;convert from ASCII
   Mov    BL,10               ;set up to multiply by ten
   Mul    BL                  ;10 x AL appears in AX
   Mov    BX,AX               ;save result in BX
   Xor    AH,AH               ;clear AH
   Lodsb                      ;load next digit
   Sub    AL,48               ;convert from ASCII
   Add    BX,AX               ;BX now contains value of exponent

   Cmp    Exponent,0          ;is exponent positive ?
   Je     Strg_Search_Done    ;yes, then don't negate
   Neg    BL                  ;no, then change the sign of the exponent

Strg_Search_Done:

   Push   DS
   Pop    ES                  ;ensure that ES holds the data segment
   Mov    SI,Image            ;get Image
   Mov    CX,[SI]             ;and save length of Image in CX
   Mov    DI,Offset Buffer    ;get address of Buffer
   Mov    [DI],CX             ;put length of Image in Buffer
   Add    DI,4                ;bump past string descriptor
   Mov    [DI-02],DI          ;create address part of string descriptor
   Dec    DI                  ;point to previous character
   Mov    IStart,DI           ;and save it
   Add    DI,CX               ;DI now points to last character in string

   Mov    Exponent,BL         ;save value of exponent
   Xor    CH,CH               ;clear CH, only need CL for looping below
   Xor    BH,BH               ;clear BH, only need BL
   Mov    BL,BDPS
   Add    BL,SDecimal         ;BL contains BDPS + SDecimal

   Std                        ;backward string moves for field

   Mov    SI,Strg             ;load Strg
   Mov    CX,[SI]             ;length of Strg in CX
   Mov    SI,[SI+02]          ;first character address

   Cmp    Exponent,0          ;do we have an exponent ?
   Jg     Pos_Exponent        ;yes, then do positive exponent if +ve
   Jl     Neg_Exponent        ;yes, then do negative exponent if -ve

   Cmp    ADPS,0              ;no exponent, but does ADPS exist ?
   Jl     Done_ADPS           ;no, then do BDPS

   Mov    AL,ADPI
   Cmp    ADPS,AL             ;is ADPS>ADPI ?
   Ja     Check_Round1        ;yes, so rounding may be necessary

   Sub    AL,ADPS             ;AL contains number of zeros to do
   Mov    CL,AL               ;number of zeros to do in CL
   Call   Put_Zeros           ;put the zeros

   Add    BL,ADPS
   Add    SI,BX               ;point to character to load
   Mov    CL,ADPS             ;number of characters to put in Image

Put_ADPS:

   Jcxz   Done_ADPS           ;no more ADPS left to do
   Dec    CL                  ;decrease counter
   Lodsb                      ;look at the next digit
   Call   Put_Digit           ;put in Image
   Jmp    Put_ADPS            ; CL times

Done_ADPS:

   Jmp    Do_BDPS

Check_Round1:

   Mov    CL,ADPI             ;set counter
   Add    BL,ADPI
   Inc    BL                  ;look at character after ADPS
   Add    SI,BX
   Lodsb                      ;load the digit to be checked
   Cmp    AL,"5"              ;is digit less than 5 ?
   Jb     Put_ADPS            ;yes, then leave carry flag setting
   Mov    Carry,1             ;set the carry flag
   Jmp    Put_ADPS            ;put it in Image

Neg_Exponent:

   Add    BL,ADPS             ;BL contains  SDecimal + BDPS + ADPS
   Mov    CL,ADPI
   Add    CL,Exponent
   Sub    CL,ADPS             ;CL contains  ADPI - ADPS + Exponent
   Jl     Check_ADPS          ;if negative then no zeros after ADPS
   Call   Put_Zeros           ;put the zeros in Image
   Mov    CL,ADPS
   Add    CL,BDPS
   Add    CL,SDecimal         ;CL contains  ADPS + BDPS + SDecimal
   Add    SI,BX
   Jmp    Do_String

Pos_Exponent:

   Cmp    ADPI,0              ;does ADPI exist ?
   Je     No_ADPI             ;no, so no zeros required after decimal point
   Mov    CL,ADPI             ;number of zeros to put after the decimal
   Call   Put_Zeros           ;put the zeros in Image

No_ADPI:

   Cmp    IDecimal,0          ;is a decimal point required
   Je     No_Decimal          ;no, so don't put one
   Mov    AL,"."              ;yes, so put one
   Call   Put                 ; in Image

No_Decimal:

   Mov    CL,Exponent         ;get the exponent value
   Sub    CL,ADPS             ;subtract ADPS to get number of zeros
   Mov    AL,"0"              ;set up to put zeros

More_Zeros:

   Call   Check_Comma         ;check for comma
   Call   Put                 ;put it in Image
   Loop   More_Zeros          ;do this CL times

   Mov    CL,BDPS
   Add    CL,ADPS             ;CL contains number of digits remaining
   Add    BL,ADPS             ;point to end of ADPS
   Add    SI,BX
   Jmp    Put_BDPS            ;then continue with BDPS

Check_ADPS:

   Add    BL,CL               ;BL contains  ADPI + Exponent + SDecimal + BDPS
   Jl     Do_Zeros            ;if BL < 0 then do zeros
   Cmp    ADPS,0              ;is ADPS = 0 ?
   Je     Do_ADPS             ;yes, then continue with ADPS
   Cmp    BL,0                ;yes, then check to see if BL is zero
   Je     Do_Zeros           ;if it is just do zeros

Do_ADPS:

   Mov    CL,BL               ;CL contains the same
   Inc    BL                  ;look at next character for rounding
   Add    SI,BX
   Lodsb                      ;load the character
   Cmp    AL,"."              ;is it the decimal point ?
   Jne    Check_Round2        ;no, then okay to continue
   Dec    CL
   Lodsb                      ;load the next character

Check_Round2:

   Cmp    AL,"5"              ;is the digit less than "5" ?
   Jb     Do_String           ;yes, leave the flag setting
   Inc    Carry               ;set the flag

Do_String:

   Jcxz   Do_Zeros
   Dec    CL                  ;decrease counter
   Lodsb                      ;load character
   Cmp    AL,"."              ;is it a decimal point ?
   Je     Do_String           ;yes, then get again
   Call   Put_Digit           ;put digit in Image
   Jmp    Do_String           ; do this CL times

Do_Zeros:

   Mov    CL,BDPS
   Neg    CL
   Sub    CL,Exponent         ;CL contains ( - BDPS - Exponent )
   Cmp    CL,ADPI             ;is this greater than ADPI ?
   Jle    Zero_Count_OK       ;no, so number of zeros is okay
   Mov    CL,ADPI             ;yes, make ADPI the number of zeros

Zero_Count_OK:

   Call   Put_Zeros           ;put the zeros in Image
   Mov    BDPS,0              ;no more BDPS left

Do_BDPS:

   Cmp    IDecimal,0          ;does decimal exist in Image$
   Je     Check_BDPS          ;no, so lets check BDPS
   Mov    AL,"."
   Call   Put                 ;put the decimal point in Image

Check_BDPS:

   Mov    CL,BDPS
   Cmp    CL,0                ;does BDPS exist ?
   Ja     Put_BDPS            ;yes, so do it
   Cmp    BDPI,0              ;does BDPI exist ?
   Je     Check_Carry         ;no, then check whether Carry is set
   Jmp    Put_Overflow        ;yes, then okay

Put_BDPS:

   Jcxz   Check_Carry         ;done with BDPS
   Lodsb                      ;load the next digit in the field
   Cmp    AL,"."              ;if decimal point
   Je     Put_BDPS            ; then get again
   Call   Check_Comma         ;put a comma ?
   Call   Put_Digit           ;put digit in Image
   Loop   Put_BDPS

Check_Carry:

   Cmp    Carry,0             ;is the Carry still set ?
   Je     Check_Dollar        ;no, done with BDPS, now check whether dollar

Put_Overflow:

   Mov    CL,1                ;since Carry flag is set, display a "1"
   Call   Put_Zeros           ;display the zeros

Check_Dollar:

   Cmp    Dollar,0            ;do we need a "$"
   Je     Check_Sign          ;no, so check the sign
   Mov    AL,"$"              ;yes (NOTE: a pound sign may be substituted here)
   Call   Put                 ;put it in Image

Check_Sign:

   Mov    AL,SPlus            ;load the sign
   Cmp    AL,"-"              ;is it a minus sign ?
   Je     Put_Sign            ;yes, then put it in Image

   Cmp    IPlus,0             ;do we need a sign ?
   Je     Check_Star          ;no, so check for asterisk

Put_Sign:

   Call   Put                 ;put it in Image

Check_Star:

   Mov    AL,Asterisk         ;set "*" or " " as necessary

Remaining_Field:

   Cmp    DI,IStart           ;have we filled the field ?
   Jbe    Exit                ;yes, then all done
   Stosb                      ;no, then put it in Image
   Jmp    Remaining_Field

Exit:

   Cld                        ;must restore direction flag for return to QB
   Mov    AX,Offset Buffer    ;save Buffer address in AX for function call
 
Exit1:
   Ret

FUsing EndP
;----------------------------------------------------------------------------
Put Proc Near

   Cmp    DI,IStart           ;are we at the first character
   Ja     Put_Okay            ;no, then okay to continue
   Je     Put_Percent         ;if equal then do "%" sign
   Ret                        ;just return otherwise

Put_Percent:

   Mov    AL,"%"              ;set up the "%" sign
   Inc    DI                  ;point to first character in string
   Stosb                      ;and put it in Image
   Dec    DI                  ;reduce DI to be less than IStart
   Ret                        ;and return

Put_Okay:

   Stosb                      ;put it in Image
   Ret                        ;and return

Put EndP
;----------------------------------------------------------------------------
Put_Digit Proc Near

   Cmp    Carry,0             ;is the carry flag set ?
   Je     No_Carry            ;no, then skip the following

   Cmp    AL,"9"              ;is it a 9 ?
   Je     Disp_Zero           ;yes, then do a zero
   Inc    AL                  ;no, then increase digit by one
   Mov    Carry,0             ; and turn off the Carry

No_Carry:

   Call   Put                 ;put digit in Image
   Ret                        ;done

Disp_Zero:

   Mov    AL,"0"
   Jmp    No_Carry            ;go put it in Image

Put_Digit EndP
;----------------------------------------------------------------------------
Put_Zeros Proc Near

Put_Zero:

   Mov    AL,"0"              ;setup
   Cmp    Carry,0             ;is the Carry flag set ?
   Je     No_Reset            ;no, then skip the following
   Dec    Carry               ;reset the Carry
   Inc    AL                  ;make "0" into "1"

No_Reset:

   Jcxz   Zeros_Done          ;no zeros to do
   Call   Put                 ;put it in Image
   Loop   Put_Zero            ; CL times

Zeros_Done:   Ret

Put_Zeros EndP
;----------------------------------------------------------------------------
Check_Comma Proc Near

   Push   AX                  ;save AX on stack
   Cmp    Comma,1             ;is comma required ?
   Jne    Comma_Done          ;no, then don't put one
   Cmp    CommaCount,3        ;is a comma due ?
   Jne    Not_Yet             ;no, not yet
   Mov    AL,","              ;set up to put comma
   Call   Put                 ; and put it in Image
   Mov    CommaCount,0        ;reset the comma counter

Not_Yet:

   Inc    CommaCount          ;increase the comma counter

Comma_Done:

   Pop    AX                  ;retrieve AX from stack
   Ret

Check_Comma EndP
;----------------------------------------------------------------------------
End
