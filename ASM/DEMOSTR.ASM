;********** DEMOSTR.ASM - P.D.Q. demonstration assembler program

.Model Medium, Basic


;Compile and link this program using the C.BAT file with the "s" option:
;
;   C demostr s

Include MACROS.ASM          ;this holds the various macros used here

    Extrn B$CEND:Proc       ;ends the program, in STARTUP.ASM
    Extrn B$PCSD:Proc       ;prints a string w/Tab, in PRINT.ASM
    Extrn B$PCI4:Proc       ;prints a long integer w/Tab, in PRINTLNG.ASM
    Extrn B$PESD:Proc       ;prints a string w/CRLF, in PRINT.ASM
    Extrn B$PSSD:Proc       ;prints a string w/o CRLF, in PRINT.ASM
    Extrn B$SASS:Proc       ;assigns a string, in ASSIGN$.ASM

.Data
    DefStr TestMsg, "This is a test of using P.D.Q. with assembly language."
    DefStr Hello, <34, "Hello", 34>
    DefStr Assignee
    LongInt DD 12345

.Code

Main Proc

    PrintStr TestMsg, CRLF
    PrintStr Hello
    PrintStr Hello, Tab
    PrintLong LongInt, Tab
    AssignStr Assignee, Hello
    PrintStr Assignee
    Quit
    
Main Endp
End
