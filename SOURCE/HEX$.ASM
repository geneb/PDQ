;******** HEX$.ASM - PDQ replacements for QB's B$FHEX and B$FOCT routines

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$MakeTemp:Proc ;this is in MAKETEMP.ASM
    
.Data?
    Digits DB 11 Dup(?)   ;this is where we'll put the output string

.Code

B$FOCT Proc               ;this is the entry point for OCT$()
    Mov  CX,0703h         ;AND mask in CH, rotate count in CL
    Db   4                ;fall through the Mov below with some bogus code
B$FOCT Endp               ;(1 byte vs. Jmp Short P$HEXOCT which is 3 bytes)


B$FHEX Proc               ;this is the entry point for HEX$()
    Mov  CX,0F04h         ;AND mask in CH, rotate count in CL
B$FHEX Endp               ;fall into the code below


P$HEXOCT Proc Uses SI DI, HiWord:Word, LoWord:Word

    Mov  DI,Offset Digits + 10 ;store digits starting at the end
    Xor  BX,BX                 ;BX will track the accumulated length
    Push DS                    ;transfer the segment to store to in ES
    Pop  ES

    Mov  AX,LoWord        ;get the low part of the number
    Mov  DX,HiWord        ;and then the high part
    Std                   ;we'll be assigning the output from right to left
                          ;(this is eventually cleared within P$TempStr)
More:
    Push AX               ;save what we're working on -----------+
    And  AL,CH            ;clear what we don't need              |
    Add  AL,"0"           ;convert to ASCII                      |
    Cmp  AL,"9"           ;is it a decimal digit?                |
    Jbe  Decimal          ;yes, go stick it in the output string |
    Add  AL,7             ;no, bump it up to "A" through "F"     |
                          ;                                      |
Decimal:                  ;                                      |
    Stosb                 ;store the output byte                 |
    Pop  AX               ;get our work back again --------------+
    Push CX               ;save CX while we loop below -------------------+
    Xor  CH,CH            ;looping also requires CH to be clear           |
                          ;(Xor conveniently clears the carry flag too)   |
Shift:                    ;                                               |
    Rcr  DX,1             ;shift all bits in DX:AX the appropriate amount |
    Rcr  AX,1             ;consider the next nybble or part-nybble        |
    Clc                   ;don't let the shifted bits from AL affect DX   |
    Loop Shift            ;this is done either three times or four times  |
                          ;                                               |
    Inc  BX               ;show the string being one digit longer         |
    Mov  CX,AX            ;a trial OR with AX and DX tells if we're done  |
    Or   CX,DX            ;using CX preserves both AX and DX              |
    Pop  CX               ;get the AND mask and shift count back again ---+
    Jnz  More             ;the OR above shows we still have more work to do

    Mov  CX,BX            ;the number of bytes to request has to be in CX
    Mov  SI,DI            ;transfer the address of the first char. for Movsb
    Inc  SI               ;DI actually went one past it
    Call P$MakeTemp       ;ask for that many bytes in the string pool
    Rep  Movsb            ;copy the output into the pool
    Mov  AX,BX            ;transfer the address P$MakeTemp returned to AX
    Ret                   ;return to BASIC

P$HEXOCT Endp
End
