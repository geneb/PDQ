;********** _TIME$.ASM - "smaller" version of the TIME$ function

;Copyright (c) Ethan Winer 1990

;This routine replaces the normal P.D.Q. TIME$ function using less code, and
;with only one small limitation: it may not be used within a non-simplified
;interrupt handler.  We recommend using this version whenever you need to
;save a few bytes, in all non-TSR and "simplified" TSR programs that read
;TIME$.  The only reason this version is not the default is for consistency
;with the other P.D.Q. "stub files" that always provide smaller code in
;exchange for less functionality.

.Model Medium, Basic
    Extrn P$MakeTemp:Proc   ;this is in MAKETEMP.ASM
    
.Code

B$FTIM Proc Uses DI

    Mov  CX,8               ;request 8 bytes to hold the output string
    Call P$MakeTemp         ;returns BX and DI
    Cmp  CL,8               ;did we get all 8 bytes?
    Jne  Exit               ;no, exit now
    
    Mov  AH,2Ch             ;get time service
    Int  21h                ;call DOS - return codes as follows:
                            ;CH = Hours   (0-23)   CL = Minutes (0-59)
                            ;DH = Seconds (0-59)   DL = 1/100 Seconds (0-99)

    Push CX                 ;save this for a moment
    Mov  AL,CH              ;first do the hours
    Call _ASCII             ;convert byte to ASCII digits and store them
    Mov  AL,':'             ;make a colon
    Stosb                   ;and store that

    Pop  AX                 ;retrieve the minutes, was CX when pushed
    Call _ASCII
    Mov  AL,':'
    Stosb

    Mov  AL,DH              ;as above for the seconds
    Call _ASCII

Exit:
    Mov  AX,BX              ;transfer the descriptor address to AX
    Ret                     ;and return to BASIC

B$FTIM Endp



_ASCII   Proc Near

    Cbw                   ;convert numerator in AL into a full word
    Mov  CL,10            ;divisor = 10, prepare to divide AX/CL
    Div  CL               ;leaves quotient in AL, remainder in AH
    Push AX               ;save results of division
    Call ASCII_2          ;convert byte in AL to ASCII, assign to T$
    Pop  AX               ;retrieve remainder
    Mov  AL,AH            ;prepare to assign remainder to T$

ASCII_2:
    Add  AL,48            ;convert byte to ASCII - "1" = Chr$(1 + 48)
    Stosb                 ;store the current digit into the output
    Ret

_ASCII Endp
End
