;********** CLOCK.ASM - perpetual time display program

;Copyright (c) 1990 Ethan Winer


;Assemble and link as follows:
;
;   MASM clock;
;   LINK /noe /far /packc clock startup , , nul , pdq
;   EXE2COM clock


.Model Medium               ;all P.D.Q. programs are medium model

Public Main                 ;make the main public (must use the name Main)
Include MACROS.ASM          ;this holds the DefStr macro and RegType Struc

Extrn B$CSRL: Proc      ;CSRLIN.ASM     Returns the current cursor line
Extrn B$FPOS: Proc      ;POS0.ASM       Returns the current cursor column
Extrn B$FTIM: Proc      ;TIME$.ASM      Returns the current system time
Extrn CallOldInt: Proc  ;CALLINT.ASM    The first step in any interrupt code
Extrn EndTSR: Proc      ;ENDTSR.ASM     Ends a programs and stays resident
Extrn IntEntry1: Proc   ;POINTINT.ASM   The first step in any interrupt code
Extrn IntEntry2: Proc   ;POINTINT.ASM   The second mandatory step
Extrn PDQPrint: Proc    ;PDQPRINT.ASM   Prints directly to screen memory
Extrn PointIntHere:Proc ;POINTINT.ASM   Sets up an interrupt handler
Extrn ReturnFromInt:Proc;RETINT.ASM     Returns to the underlying application

.Data?
    Reg8    RegType <>      ;create a RegType structure for trapping Int. 8
    CurRow  DW 1 Dup (?)    ;saves the current row and column for sign-on
    CurCol  DW 1 Dup (?)

.Data
    DefStr  ID$, "Clock 1.0 (c) Crescent Software"
    Tick    DB 0            ;tracks the timer ticks
    Even                    ;force word alignment for speed
    Zero    DW 0            ;for use by IntEntry2
    Row     DW 1            ;the row to print on
    Seven   DW 7            ;default white on black color
    Color   DW 9            ;bright blue on black (or underlined if mono)
    Column  DW 73           ;the column to print at

.Code

Main Proc
    Call B$CSRL             ;get and save the current cursor row and column
    Mov  CurRow,AX
    Push AX                 ;B$FPOS needs a dummy argument, any value will do
    Call B$FPOS
    Mov  CurCol,AX
    
    Mov  AX,Offset ID$      ;print the sign-on message, use PDQPrint once
    Push AX
    Mov  AX,Offset CurRow
    Push AX
    Inc  AX                 ;bump past to the current column
    Inc  AX
    Push AX
    Mov  AX,Offset Seven
    Push AX
    Call PDQPrint

    Mov  Reg8.IntNum,8      ;specify trapping timer Interrupt 8
    Mov  AX,Offset Reg8
    Push AX
    Call PointIntHere
    Jmp  EndIt              ;skip over the interrupt handler code

;----- this code gets executed with each timer tick (18.2 times per second)
    Call IntEntry1
    Mov  AX,Offset Reg8
    Push AX
    Mov  AX,Offset Zero
    Push AX
    Call IntEntry2

    Mov  AX,Offset Reg8
    Push AX
    Call CallOldInt         ;service the interrupt before doing anything else

    Inc  Tick               ;work only once per second
    Cmp  Tick,18            ;has one second passed?
    Jb   Done               ;no, so we're all done for now

    Mov  Tick,0             ;yes, reset Tick for next time
    Call B$FTIM             ;get the current time
    Push AX
    Mov  AX,Offset Row      ;pass the row, column, and color to print at
    Push AX
    Mov  AX,Offset Column
    Push AX
    Mov  AX,Offset Color
    Push AX
    Call PDQPrint           ;print it
    
Done:
    Mov  AX,Offset Reg8     ;return to the underlying application
    Push AX
    Call ReturnFromInt

EndIt:
    Mov  AX,Offset ID$
    Push AX
    Call EndTSR             ;terminate and stay resident

Main Endp
End
