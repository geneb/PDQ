;********** INSTR.ASM - PDQ replacement for BASIC's B$INS3 routine

;Copyright (c) 1989 Ethan Winer
; 11/2/92  Thomas G. Hanlin III   added far string support

;This is called when you use INSTR with three arguments:
;
;   X = INSTR(Start, Source$, Search$)


.Model Medium, Basic
    Extrn P$FixStr:Proc   ;this is in FIXSTR.ASM
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM

.Code

B$INS3 Proc Uses SI DI, Start:Word, Source:Word, Search:Word

    Push Source           ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Source,AX        ;

    Push Search           ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Search,AX        ;

    Cld                   ;insure that string instructions are forward
    Push DS               ;assign ES=DS
    Pop  ES
    Mov  AX,Start         ;put Start% into AX

    Mov  DI,Source        ;get the address for the Source$ descriptor
    Mov  CX,[DI]          ;put its length into CX
    Mov  DI,[DI+02]       ;and its address into DI
    Mov  BX,DI            ;save that in BX to see how far we searched later

    Mov  SI,Search        ;get the address for the Search$ descriptor
    Mov  DX,[SI]          ;put its length into DX
    Mov  SI,[SI+02]       ;and its address into SI
    Dec  DX               ;we'll handle the first character using Scasb
    Jns  NotNull          ;the string we're looking for is not null, continue

    Cmp  AX,CX            ;it is null, but is Start past the end of Source?
    Jna  Exit             ;no, return Start as the result
    Xor  AX,AX            ;yes, return zero (after Dec'ing below and jumping)

NotNull:
    Dec  AX               ;adjust Start% so 1st character = 0 offset
    Js   NotFound         ;Start% was zero or negative, get out and return 0
    Add  DI,AX            ;advance Start% bytes into the string
    Sub  CX,AX            ;and consider that many fewer characters to search
    Jbe  NotFound         ;they tried to start past the end

    Lodsb                 ;get and skip over the first character in Search$

Scan:
    Repne Scasb           ;find the first character in Source$
    Jne  NotFound         ;if it's not there, we can't possibly find a match
    Cmp  CX,DX            ;are we less than LEN(Search$) bytes from the end?
    Jb   NotFound         ;yes, so there's no point in looking further
    Or   DX,DX            ;was the string only one character long?
    Jz   Found            ;yes, so this must be it!

    Push SI               ;save the current scanning context
    Push DI
    Push CX
    Mov  CX,DX            ;search LEN(Search$) characters
    Repe Cmpsb            ;compare the two strings
    Pop  CX               ;restore the context in case we have to scan again
    Pop  DI
    Pop  SI
    Jne  Scan             ;we didn't find it, keep trying

Found:                    ;we found one!
    Sub  DI,BX            ;calculate how far into the string we found a match
    Mov  AX,DI            ;leave the result in AX for the function output

Exit:
    Push Source           ;delete the string(s) if necessary
    Call P$FreeTemp
    Push Search
    Call P$FreeTemp
    Ret                   ;return to caller

NotFound:
    Xor  AX,AX            ;return zero to show we didn't find it
    Jmp  Short Exit       ;and exit

B$INS3 Endp
End
