;**** PRINTLNG.ASM - PDQ replacements for B$PEI4, B$PSI4, and B$PCI4 routines

;Copyright (c) 1989 Ethan Winer


;These routines handle printing long integers.

.Model Medium, Basic
    Extrn B$STI4:Proc       ;this is in STR$.ASM, converts long int to string
    Extrn B$PESD:Proc       ;this is in PRINT.ASM, prints a string w/CRLF
    Extrn B$PSSD:Proc       ;this is in PRINT.ASM, prints a string w/o CRLF
    Extrn B$PCSD:Proc       ;this is in PRNCOMMA.ASM, prints a string and Tab

.Data?
    WhichProc DB 1 Dup (?)  ;this tracks which procedure was called
                            ;  so we can use common code below
.Data
    Extrn P$1Space:Word     ;this is in PRINTDAT.ASM

.Code

B$PEI4 Proc                 ;this prints long integers with CRLF
                            ;PEI4 = Print End-of-line Integer 4-byte
    Mov  WhichProc,1        ;flag that we're B$PEI4
    Jmp  P$PrintLng         ;and jump into the common code

B$PEI4 Endp



B$PSI4 Proc                 ;this prints long integers w/o CRLF
                            ;PSI4 = Print Semicolon Integer 4-byte
    Mov  WhichProc,2        ;flag that we're B$PSI4
    Jmp  P$PrintLng         ;and jump into the common code

B$PSI4 Endp



B$PCI4 Proc                 ;prints long integers with a Tab (,)
                            ;PCI4 = Print Comma Integer 4-byte
    Mov  WhichProc,3        ;flag that we're B$PCI4
;   Jmp  P$PrintLng         ;and fall into the common code

B$PCI4 Endp



P$PrintLng Proc, HiWord:Word, LoWord:Word

    Push HiWord             ;pass the values on to P$STI4
    Push LoWord
    Call B$STI4             ;this then calls Jay to make a string
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

P$PrintLng Endp


End
