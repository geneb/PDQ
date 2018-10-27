;********** COLOR.ASM - PDQ replacement for BASIC's B$COLR routine

;Copyright (c) 1989 Ethan Winer

; 10/14/92, Thomas G. Hanlin III: added support for graphics modes


;This routine accepts a varying number of parameters, and therefore must use
;self-modifying code.  For each parameter that was specified, BASIC first
;passes a value of 1, and then follows that with the actual color argument.
;Parameters that were not given are instead flagged with a value of zero.
;The optional border parameter is handled slightly differently -- it's either
;there or it's not.  However, this COLOR routine ignores the border parameter.  The
;The examples below show what BASIC passes for each possible combination:
;
;COLOR FG            Push 1: Push FG: Push 2
;COLOR ,BG           Push 0: Push 1:  Push BG: Push 3
;COLOR ,, Border     Push 0: Push 0:  Push 1:  Push Border: Push 4
;
;COLOR FG, BG        Push 1: Push FG: Push 1:  Push BG: Push 4
;COLOR FG, , Border  Push 1: Push FG: Push 0:  Push 1:  Push Border: Push 5
;COLOR , BG, Border  Push 0: Push 1:  Push BG: Push 1:  Push Border: Push 5
;
;COLOR FG,BG,Border  Push 1:Push FG:Push 1:Push BG:Push 1:Push Border:Push 6
;
;See COLORDAT.ASM for a description of the format used for the color byte.


.Model Medium, Basic
.Data
    Extrn P$Color: Byte     ;this is in COLORDAT.ASM
    Extrn b$ForeColor: Byte ;this is in COLORDAT.ASM

.Code

B$COLR Proc Uses SI, NumArgs:Word

    Mov  SI,NumArgs       ;BASIC supplies the number of passed arguments
    Inc  SI               ;except it's actually one less than what we need
    Shl  SI,1             ;moreover, Ret n requires two bytes per parameter
    Mov  CS:Patch,SI      ;self-modify the code below as necessary

    Mov  AL,[BP+SI+04]    ;load the foreground color parameter flag
    Or   AL,AL            ;is it zero (parameter not given)?
    Jz   GetBG            ;yes, go get the background
    Mov  AL,[BP+SI+02]    ;no, load the actual foreground value
    Mov  BL,AL            ;save it in BL too
    Mov  b$ForeColor,AL   ;save a copy for graphics modes

    And  P$Color,1110000b ;clear the foreground portion of the current color
    And  AL,16            ;AND the new color with 16 to isolate the flash bit
    Mov  CL,3             ;multiply times 8 by shifting
    Shl  AL,CL            ;  to put it into the correct bit position
    And  BL,15            ;mask the flash bit on the copy of the FG value
    Add  AL,BL            ;now AL holds the foreground part of the color
    Or   P$Color,AL       ;apply that to the current color value

    Cmp  SI,6             ;was this foreground parameter the only one?
    Jz   Exit             ;yes, so we're done
    Dec  SI               ;no, adjust SI so [BP+SI] below points to the BG
    Dec  SI               ;(two Dec's is faster and less code than Sub SI,2)

GetBG:
    Mov  AL,[BP+SI+02]    ;load the background color parameter flag
    Or   AL,AL            ;is it zero (parameter not given)?
    Jz   Exit             ;yes, so we're done

    Mov  AL,[BP+SI]         ;no, load the actual background value
    And  P$Color,10001111b  ;clear the background part of the current color
    And  AL,7             ;restrict the range to 0 - 7 to mask illegal values
    Mov  CL,4             ;multiply times 16 by shifting
    Shl  AL,CL            ;  to put it into the correct position
    Or   P$Color,AL       ;apply the background value to the current color

Exit:
    Pop  SI               ;we have to pop these manually
    Pop  BP
    Db   0CAh             ;this is the opcode for Ret n
Patch DW 6                ;assume 3 arguments (Ret 6)

B$COLR Endp
End
