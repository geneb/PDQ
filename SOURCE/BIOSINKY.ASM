;******** BIOSINKY.ASM - BIOS-only INKEY routine

;Copyright (c) 1989 Ethan Winer

;This routine is identical to the PDQInkey function, except it calls the
;BIOS rather than DOS.  Although BIOSInkey does not support redirection,
;it may be called from a P.D.Q. TSR program.

.Model Medium, Basic
.Code

BIOSInkey Proc

    Xor  BX,BX             ;assume no character is pending
    Mov  AH,1              ;now see if there really is one
    Int  16h               ;call the BIOS
    Jz   Exit              ;nope, so exit

    Mov  AH,0              ;get the character service
    Int  16h               ;call BIOS to get it
    Mov  BL,AL             ;put the character into BL
    Or   AL,AL             ;is it an extended key?
    Jnz  Exit              ;no, so we're all done

    Mov  BL,AH             ;yes, put the code into BL
    Neg  BX                ;convert to a negative value

Exit:
    Sti                    ;reenable interrupts (this should NOT be necessary)
    Mov  AX,BX             ;assign the function output
    Ret                    ;return to BASIC

BIOSInkey Endp
End
