;********* DEMOBUF.ASM - performs fast buffered line input from a file

;Copyright (c) 1991 Ethan Winer

;Assemble and link as follows (DEMOBUF is too small for link's /ex switch!):
;
;   MASM demobuf;
;   LINK /noe/far/packc demobuf startup _noerror, , nul , smalldos pdq
;   EXE2COM demobuf


.Model Medium               ;all P.D.Q. programs are medium model
Public Main                 ;make the main public (must use the name Main)

    Extrn BufIn:Proc        ;reads a file very quickly, in BUFIN.ASM
    Extrn B$CEND:Proc       ;ends the program, in STARTUP.ASM
    Extrn B$PESD:Proc       ;prints strings with a CRLF, in PRINT.ASM

Include MACROS.ASM          ;defines some useful assembly language macros

.Data
    Done    DW 0            ;tracks when BufIn is finished
    Color   DW 7            ;print in white on black
    Row     DW 1
    Column  DW 1
    DefStr FileName$, "MACROS.ASM"  ;we'll read this file and print it

.Code

Main Proc

@@:
    Mov  AX,Offset FileName$    ;pass the file name and done flag to BufIn
    Push AX
    Mov  AX,Offset Done
    Push AX

    Call BufIn                  ;read a line of text from the file
    Cmp  Done,-1                ;are we done?
    Je   @F                     ;yes, go end
    Push AX                     ;no, print this line
    Call B$PESD
    Jmp  @B                     ;and go again

@@:
    Call B$CEND

Main Endp
End
