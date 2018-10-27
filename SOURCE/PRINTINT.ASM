;**** PRINTINT.ASM - PDQ replacements for B$PEI2, B$PSI2, and B$PCI2 routines

;Copyright (c) 1989 Ethan Winer


;These routines handle printing integer values.


.Model Medium, Basic
    Extrn B$STI2:Proc       ;this is in STR$.ASM, converts integer to string
    Extrn B$PESD:Proc       ;this is in PRINT.ASM, prints a string w/CRLF
    Extrn B$PSSD:Proc       ;this is in PRINT.ASM, prints a string w/o a CRLF
    Extrn B$PCSD:Proc       ;this is in PRNCOMMA.ASM, prints a string and Tab

.Data?
    WhichProc DB 1 Dup (?)  ;this tracks which procedure was called
                            ;  so we can use common code below
.Data
    Extrn P$1Space:Word     ;this is in PRINTDAT.ASM

.Code

B$PEI2 Proc                 ;this routine prints integer numbers with a CRLF
                            ;PEI2 = Print End-of-line Integer 2-byte
    Mov  WhichProc,1        ;flag that we're B$PEI2
    Jmp  P$PrintInt         ;and jump into the common code
    
B$PEI2 Endp



B$PSI2 Proc                 ;this routine prints integer numbers w/o a CRLF
                            ;PSI2 = Print Semicolon Integer 2-byte
    Mov  WhichProc,2        ;flag that we're B$PSI2
    Jmp  P$PrintInt         ;jump into the code below

B$PSI2 Endp



B$PCI2 Proc                 ;this routine prints integers and then Tabs (,)
                            ;PCI2 = Print Comma Integer 2-byte
    Mov  WhichProc,3        ;flag that we're B$PCI2
;   Jmp  P$PrintInt         ;fall into the code below

B$PCI2 Endp



P$PrintInt Proc, Value:Word

    Push Value              ;pass the value on to P$STI2
    Call B$STI2             ;this then calls Jay to make a string
    Push AX                 ;push the descriptor address B$STI2 returns
    Call B$PSSD             ;print the number as a string without a CRLF
    Mov  AX,Offset P$1Space ;show the print routine where the blank space is
    Push AX                 ;push the descriptor in anticipation of printing

    Dec  WhichProc          ;if they called B$PEI2 this'll make WhichProc 0
    Jnz  TrySemi            ;nope, see if they called B$PSI2
    Call B$PESD             ;print the blank and end the line with a CRLF
    Jmp  Short Exit         ;and exit

TrySemi:
    Dec  WhichProc          ;if they called B$PSI2 this'll make WhichProc 0
    Jnz  WasComma           ;no, they must have used a trailing comma
    Call B$PSSD             ;yes, print a blank and leave the cursor hanging
    Jmp  Short Exit         ;all done

WasComma:
    Call B$PCSD             ;print the blank and advance to the next Tab stop

Exit:
    Ret                     ;return to caller

P$PrintInt Endp
End
