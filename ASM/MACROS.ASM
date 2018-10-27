;********* MACROS.ASM -- macro definitions for use with P.D.Q.

;Copyright (c) 1990 Ethan Winer


;----- Use this with TSR and int. handlers

RegType Struc
     RegAX      DW 1 Dup (?)
     RegBX      DW 1 Dup (?)
     RegCX      DW 1 Dup (?)
     RegDX      DW 1 Dup (?)
     RegBP      DW 1 Dup (?)
     RegSI      DW 1 Dup (?)
     RegDI      DW 1 Dup (?)
     Flags      DW 1 Dup (?)
     RegDS      DW 1 Dup (?)
     RegES      DW 1 Dup (?)
     RegSS      DW 1 Dup (?)
     RegSP      DW 1 Dup (?)
     BusyFlag   DW 1 Dup (?)
     Address    DW 1 Dup (?)
     Segmentx   DW 1 Dup (?)
     ProcAdr    DW 1 Dup (?)
     ProcSeg    DW 1 Dup (?)
     IntNum     DW 1 Dup (?)
RegType Ends


;NOTE: All of the following macros assume that it is okay to destroy AX only.
;
;
;----- PushM, Pushes multiple arguments in one statement
;
;Usage:
;   PushM AX, DI, <Word Ptr [BP+06]>, whatever, [...]
;
;Comments:
;PushM accepts a varying number of arguments (up to 10), and pushes each in
;the order entered.  Notice that to pass an argument comprised of more than
;one word (like the Word Ptr [BP+06] above) requires enclosing the argument
;in angled brackets as shown.
;
PushM Macro A,B,C,D,E,F,G,H,I,J         ;;add more placeholders as needed
    IRP CurArg, <A,B,C,D,E,F,G,H,I,J>   ;;repeat for each argument passed
        IFNB <CurArg>                   ;;if current argument is not blank
            Push CurArg                 ;;push it
        ENDIF
    Endm                                ;;end of repeat block
Endm                                    ;;end of this macro



;----- PopM, Pops multiple arguments in one statement
;
;Usage:
;   PopM AX, DI, ES:[SI], whatever, [...]
;
;Comments:
;PopM is the complement to PushM above, and also accepts multiple parameters.
;
PopM Macro A,B,C,D,E,F,G,H,I,J          ;;as above
    IRP CurArg, <A,B,C,D,E,F,G,H,I,J>   ;;repeat for each argument passed
        IFNB <CurArg>                   ;;if current argument is not blank
            Pop CurArg                  ;;pop it
        ENDIF
    Endm                                ;;end of repeat block
Endm                                    ;;end of this macro



;----- AssignStr, assigns one conventional (descriptor) string to another
;
;Usage:
;   AssignStr Destination, Source
;
;Comments:
;AssignStr operates as if you had written Destination$ = Source$
;
AssignStr Macro Destination, Source     
    Mov  AX,Offset Source           ;;get the address of the source descriptor
    Push AX                         ;;pass it on the the assign routine
    Mov  AX,Offset Destination      ;;ditto for the destination descriptor
    Push AX
    Call B$SASS                     ;;B$SASS assigns conventional strings
Endm



;----- DefStr, defines a dynamic string descriptor with optional text
;
;Usage:
;   DefStr StringName [, "this is optional initial text"]
;
;Comments:
;   You may also pass a mix of character values and quoted text by enclosing
;   the entire string in angled brackets like this:
;
;   DefStr StringName, <34, "This is quoted text", 34>
;
DefStr Macro StrName, StrText
    Even                            ;;word-align all string descriptors
    IFB <StrText>                   ;;if no text is defined
        &StrName DW 0, 0            ;;just create a named descriptor
    ELSE                            ;;else create an entire string
        &StrName DW End&StrName - Data&StrName, Offset Data&StrName
        Data&StrName DB StrText
        End&StrName Label Byte
    ENDIF
Endm



;----- DimSArray, dimensions a static string array
;
;Usage:
;   DimSArray StringName, NumElements
;
;Comments:
;   The number of elements is the actual number of strings to be created,
;   so there is no implied element 0.  This macro merely creates a table of
;   string descriptors.  It does not create a BASIC array descriptor.
;
DimSArray Macro SArrayName, NumEls
    &SArrayName DW 0, 0             ;;use the array name for the base element
    Rept NumEls - 1                 ;;repeat NumEls - 1 times for the rest
      DW 0, 0
    Endm
Endm



;----- PrintInt, prints an integer through STDOUT
;
;Usage:
;   PrintInt IntName [,Action]
;
;Comments:
;   The optional Action argument may be either Tab or CRLF.  If Tab is
;   specified, the cursor is advanced to the next print zone after the value
;   is printed.  If CRLF is given, then a terminating CRLF is also printed.
;
PrintInt Macro IntName, Action      ;;macro to print an integer
    Push Word Ptr IntName
    IFB <Action>                    ;;if no action, print and leave cursor
        Call B$PSI2
    ENDIF
    IFIDNI <Action>,<Tab>           ;;if they specified Tab, do that
        Call B$PCI2
    ENDIF
    IFIDNI <Action>,<CRLF>          ;;if they used CRLF, do that instead
        Call B$PEI2
    ENDIF
Endm



;----- PrintLong, prints a long integer through STDOUT
;
;Usage:
;   PrintLong LongName [,Action]
;
;Comments:
;   The optional Action argument may be either Tab or CRLF.  If Tab is
;   specified, the cursor is advanced to the next print zone after the value
;   is printed.  If CRLF is given, then a terminating CRLF is also printed.
;
;   To print a long integer that is in a register pair as opposed to a memory
;   variable, you must call the print routine manually.  First push the high
;   word and then the low word, and call B$PxI4 directly, as shown below:
;
;   Push DX
;   Push AX
;   Call B$PEI4     ;B$PEI4 prints a long integer with "End of line" (CRLF)
;
PrintLong Macro LongName, Action    ;;macro to print a long integer
    Push Word Ptr LongName + 2
    Push Word Ptr LongName
    IFB <Action>                    ;;if no action, print and leave cursor
        Call B$PSI4
    ENDIF
    IFIDNI <Action>,<Tab>           ;;if they specified Tab, do that
        Call B$PCI4
    ENDIF
    IFIDNI <Action>,<CRLF>          ;;if they used CRLF, do that instead
        Call B$PEI4
    ENDIF
Endm



;----- PrintStr, prints a descriptor string through STDOUT
;
;Usage:
;   PrintStr IntName [,Action]
;
;Comments:
;   The optional Action argument may be either Tab or CRLF.  If Tab is
;   specified, the cursor is advanced to the next print zone after the value
;   is printed.  If CRLF is given, then a terminating CRLF is also printed.
;
;   To print an integer value that is in a register as opposed to in a memory
;   variable, you must push the register and then call B$PxI2 directly.
;
PrintStr Macro StrName, Action      ;;macro to print a string
    Mov  AX,Offset StrName          ;;locate the named string
    Push AX                         ;;pass its address
    
    IFB <Action>                    ;;if no action, print and leave cursor
        Call B$PSSD
    ENDIF
    
    IFIDNI <Action>,<Tab>           ;;if they specified Tab, do that
        Call B$PCSD
    ENDIF
    
    IFIDNI <Action>,<CRLF>          ;;if they used CRLF, do that instead
        Call B$PESD
    ENDIF
Endm



;----- Quit, ends the program with an optional DOS ErrorLevel
;
;Usage:
;   Quit [ErrorLevel]
;
;Where ErrorLevel may be a constant, a register, or a memory variable
;
;NOTE: It is up to you to have declared P$TermCode as external within .Data.
;
Quit Macro ErrorLevel
   IFNB <ErrorLevel>                ;;if an error level was given
      Mov  AL,ErrorLevel            ;;move it into AL
      Mov  Byte Ptr P$TermCode,AL   ;;and assign it where P.D.Q. can find it
   ENDIF
   Call B$CEND                      ;;either way, end the program
Endm
