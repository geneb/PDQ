;********** SETUP.ASM - Epson printer setup program

;Copyright (c) 1989 Ethan Winer


;assemble and link as follows (or use C.BAT with the "s" option):
;
;   MASM setup;
;   LINK /noe /nod /far /packc setup startup _noerror, , nul , smalldos pdq
;   EXE2COM setup


.Model Medium               ;all P.D.Q. programs are medium model
Public Main                 ;make the main public (must use the name Main)
Include MACROS.ASM          ;this holds all the necessary Macro definitions

    Extrn B$CEND:Proc       ;ends the program, in STARTUP.ASM
    Extrn B$PEI2:Proc       ;prints an integer w/CRLF, in PRINTINT.ASM
    Extrn B$PESD:Proc       ;prints a string w/CRLF, in PRINT.ASM
    Extrn B$PSSD:Proc       ;prints a string w/o CRLF, in PRINT.ASM
    Extrn PDQInkey:Proc     ;returns a keypress from STDIN, in PDQINKEY.ASM

.Data
    Extrn P$PrintHandle:Word    ;this is in PHANDLE.ASM

    DefStr Prompt, "Enter your selection: "

    Choice  DW Offset ChEnd - Offset ChText, Offset ChText
    ChText  DB 13, 10
            DB "1) Compressed print", 13, 10
            DB "2) Enhanced print", 13, 10
            DB "3) Tiny print", 13, 10
            DB "4) Reset", 13, 10
            DB "5) Quit"
    ChEnd Label Byte

    ;------ Create an array with a descriptor for each printer control code.
    ;       The last one is a null string so printing Choice 5 will be legal.
    Codes   DW Offset Code2 - Offset Code1, Offset Code1
            DW Offset Code3 - Offset Code2, Offset Code2
            DW Offset Code4 - Offset Code3, Offset Code3
            DW Offset CodeEnd - Offset Code4, Offset Code4
            DW 0

    Code1 DB 27, "@"
    Code2 DB 27, "@", 27, "E", 27, "G"
    Code3 DB 27, "@", 27, "S1", 27, "3"
    Code4 DB 27, "@"
    CodeEnd Label Byte

.Code

Main Proc

    PrintStr Choice, CRLF           ;print the prompt messages
    PrintStr Prompt                 ;print the prompt

@@:
    Call PDQInkey                   ;call for a key press
    Cmp  AX,"1"                     ;is it at least a "1"?
    Jb   @B                         ;no, keep looking
    Cmp  AX,"5"                     ;is it greater than "5"?
    Ja   @B                         ;no, keep looking
    Sub  AX,"0"                     ;yes, convert from ASCII to an integer

    Push AX                         ;save the value
    Push AX                         ;print the choice number for clarity
    Call B$PEI2
    Pop  AX                         ;retrieve the value

    Dec  AX                         ;convert from 1-based to 0-based
    Shl  AX,1                       ;multiply times 4 to index the array
    Shl  AX,1
    Add  AX,Offset Codes            ;point to appropriate code array element

    Mov  P$PrintHandle,4            ;show that the next PRINT goes to LPT1
    Push AX                         ;pass the array element address
    Call B$PSSD                     ;print it (to the printer)
    Quit

Main Endp
End
