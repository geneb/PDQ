;********* ASK.ASM - allows keyboard input in a batch file via ERRORLEVEL

;Copyright (c) 1990 Ethan Winer


;This program is like ASK.BAS, and is used in the same way (see MENU.BAT).

;Assemble and link as follows:
;
;   MASM ask;
;   LINK /noe/far/packc ask startup _noerror, , nul , smalldos pdq
;   EXE2COM ask


.Model Medium               ;all P.D.Q. programs are medium model
Public Main                 ;make the main public (must use the name Main)

    Extrn B$CEND:Proc       ;ends the program, in STARTUP.ASM
    Extrn B$FCMD:Proc       ;returns DOS command line, in COMMAND$.ASM
    Extrn B$PESD:Proc       ;prints a string w/CRLF, in PRINT.ASM
    Extrn B$PSSD:Proc       ;prints a string w/o CRLF, in PRINT.ASM
    Extrn PDQInkey:Proc     ;return a keypress as an integer, in PDQINKEY.ASM

Include MACROS.ASM          ;defines some useful assembly language macros    

.Data
    Extrn P$TermCode:Byte   ;holds the exit code (DOS Errorlevel)
    Null$ DW 0              ;"half" of a null string descriptor

.Code

Main Proc

    Call B$FCMD             ;retrieve the command line as a string
    Push AX                 ;pass that on to PRINT
    Call B$PSSD             ;print it without a terminating CRLF

Do:
    Call PDQInkey           ;get a keypress
    Or   AX,AX              ;was anything pressed yet?
    Jz   Do                 ;no, keep waiting

    Sub  AL,"0"             ;convert from ASCII to decimal
    Mov  P$TermCode,AL      ;save it as the exit code (error level)

    Mov  AX,Offset Null$    ;print an empty CRLF for appearance only
    Push AX
    Call B$PESD
    
    Quit

Main Endp
End
