;********** DEMOSWAP.ASM - swapping version of SCRNCAP.ASM

;Copyright (c) 1991 Ethan Winer


;See DEMOSWAP.BAS for an overview of how this program works.
;
;To use this file as a template for other swapping TSR programs of your own,
;delete the portions of this file marked with the word "template".
;
;To take as little DOS memory as possible when this program is installed as
;a TSR, you should link it with the STR00512.OBJ and other "stub" files:
;
;  masm demoswap;
;  link /ex/noe +
;    popswap demoswap startup _str$ str00512 _noerror, demoswap, nul, pdq;
;  exe2com demoswap


.Model Medium               ;all P.D.Q. programs are medium model

Public Main                 ;the main must be public and named Main
Include MACROS.ASM          ;this helps define data

Extrn B$BSAV: Proc          ;in BSAVE.ASM
Extrn B$CEND: Proc          ;in PDQ.ASM
Extrn B$FCMD: Proc          ;in COMMAND$.ASM
Extrn B$FERR: Proc          ;in ERR.ASM
Extrn B$PESD: Proc          ;in PRINT.ASM
Extrn B$STI2: Proc          ;in STR$.ASM

Extrn BIOSInput: Proc       ;in BIOSINPT.ASM
Extrn CursorRest: Proc      ;in CURSORSR.ASM
Extrn CursorSave: Proc      ;in CURSORSR.ASM
Extrn EndTSR: Proc          ;in ENDTSR.ASM
Extrn PDQPrint: Proc        ;in PDQPRINT.ASM
Extrn PopDeinstall: Proc    ;in POPUP.ASM
Extrn PopDown: Proc         ;in POPUP.ASM
Extrn PopUpHere: Proc       ;in POPUP.ASM
Extrn SwapCode: Proc        ;in SWAPCODE.ASM
Extrn Swap2Disk: Proc       ;in SWAPDISK.ASM
Extrn Swap2EMS: Proc        ;in SWAPEMS.ASM
Extrn TSRInstalled: Proc    ;in TSRINST.ASM

ScrCols = 80                ;default to 80 columns
ScrnSize = 3 * ScrCols * 2  ;3 lines * 80 columns for prompt and input field

.Data?
  DeeGroup  DW 1 Dup (?)    ;DGROUP is a reserved word to MASM
  BufSeg    DW 1 Dup (?)
  SaveCsr   DW 2 Dup (?)

.Data
  Extrn B$SEG:Word          ;this is in PDQDATA.ASM

  Zero      DW 0
  One       DW 1
  Two       DW 2
  Three     DW 3
  Seven     DW 7
  Inverse   DW 112
  HotKey    DW 830h         ;Alt-B (Both EMS and Disk swapping)
  ScrSeg    DW 0B000h       ;assume monochrome
  ScrRows   DB 25           ;assume 25 rows

  DefStr ID$,"DemoSwap (c) 1991 Crescent Software, press Alt-B to activate$"
  DefStr Top$,     "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿"
  DefStr Prompt$,  "³ Enter a name for the screen:                                    ³"
  DefStr Bottom$,  "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ"
  DefStr FileName$,"                                  "
  DefStr SwapFile$, "C:\DEMOSWAP.SWP"
  
  Unable$   DB "Unable to deinstall DEMOSWAP$"
  NotRes$   DB "DEMOSWAP is not resident - try again without /U$"
  Already$  DB "DEMOSWAP is already installed, press ALT-B to activate$"
  Removed$  DB "DEMOSWAP removed$"
  Reboot$   DB "Deinstallation failed, reboot now!$"
  EMSInst$  DB "EMS swapping installed", 13, 10, "$"
  NoEMS$    DB "EMS not available, error$"
  DiskInst$ DB "DISK swapping installed", 13, 10, "$"
  NoDisk$   DB "Disk swapping failed -- installing as a normal TSR, error $"

.Code

Main Proc

  Mov  AX,Offset ID$        ;first see if we're already installed
  Push AX
  Call TSRInstalled
  Mov  DeeGroup,AX

  Call B$FCMD               ;call COMMAND$
  Mov  BX,AX                ;copy the descriptor address to BX
  Mov  CX,[BX]              ;search COMMAND$ looking for "/" only
  Mov  DI,[BX+02]           ;skip the UCASE$ and the "U" nonsense
  Mov  AL,"/"
  Push DS                   ;set ES = DS for searching
  Pop  ES
  Repne Scasb               ;search for the "/"
  Jne  NoCmd                ;it's not in there

  Cmp  DeeGroup,0           ;are we already installed?
  Je   NotResident          ;no, report the error
  
  Sub  AX,AX                ;yes, now see if Int 0AAh has a valid segment
  Mov  ES,AX                ;by looking in the interrupt vector table

  Cmp  Word Ptr ES:[0AAh * 4 + 2],0 ;is the segment zero?
  Je   NoAA                         ;yes, it was not installed to swap

  Mov  DX,Offset Removed$   ;assume the deinstall request will work
  Call PrintMsg             ;PRINT "DEMOSWAP removed"
  
  Mov  AX,830h              ;the program's ID (its hot key too)
  Mov  BX,1                 ;pass the code to deinstall
  Mov  CX,18 * 5            ;try to get control for 5 seconds
  Int  0AAh                 ;call the kernal telling it to pop up
  Call B$CEND               ;and end normally (not as a TSR)

PrintRemoved:
  Mov  DX,Offset Removed$   ;assume the deinstall request worked
                            ;PRINT "DEMOSWAP removed"
PrintEnd:
  Call PrintMsg
  Call B$CEND               ;and end normally (not as a TSR)

NoAA:                       ;swapping failed at installation
  Mov  AX,Offset DeeGroup   ;so deinstall the usual way
  Push AX
  Mov  AX,Offset ID$
  Push AX
  Call PopDeinstall

  Or   AX,AX                ;test the PopDeinstall return code
  Jz   BadDeinstall         ;oops, it failed
  Mov  DX,Offset Removed$   ;the program deinstalled okay
  Jmp  Short PrintEnd       ;print "DEMOSWAP removed" and end

BadDeinstall:
  Mov  DX,Offset Reboot$    ;PRINT "Deinstallation failed, reboot now!"
  Jmp  Short PrintEnd       ;and then end
  
NotResident:
  Mov  DX,Offset NotRes$    ;PRINT "DEMOSWAP is not resident"
  Jmp  Short PrintEnd       ;and end
  
NoCmd:
  Cmp  DeeGroup,0           ;no command-line switch, but are we resident?
  Je   TryToSwap            ;no, so go try to swap

  Mov  DX,Offset Already$   ;print "already installed, press ALT-B" message
  Jmp  Short PrintEnd       ;and end
  
TryToSwap:
;-- TO CREATE AN EMPTY TEMPLATE REMOVE THE NEXT FOUR LINES
  Mov  BX,ScrnSize / 16     ;480 bytes = 30 16-byte paragraphs
  Mov  AH,48h               ;allocate memory to save the screen before
  Int  21h                  ;  calling the swap routines
  Mov  BufSeg,AX

  Mov  AX,Offset HotKey     ;try to swap to expanded memory
  Push AX                   ;using the hot key as a program ID
  Call Swap2EMS
  Or   AX,AX                ;see what happened
  Jz   EMSFailed            ;it didn't work
  
  Mov  DX,Offset EMSInst$   ;PRINT "EMS swapping installed"
  Call PrintMsg
  Jmp  Short SayHello
  
EMSFailed:
  Mov  DX,Offset NoEMS$     ;report that EMS is not available, and why
  Call PrintMsg
  Call B$FERR               ;BASIC's ERR function tells why
  Push AX                   ;pass that on to STR$
  Call B$STI2
  Push AX                   ;pass the returned string on to PRINT
  Call B$PESD
  
  Mov  AX,Offset SwapFile$  ;pass the name of the swap file to Swap2Disk
  Push AX
  Mov  AX,Offset HotKey     ;and the program ID (we're using the hot key)
  Push AX
  Call Swap2Disk
  Or   AX,AX                ;see what happened
  Jz   DiskFailed           ;it didn't work
  
  Mov  DX,Offset DiskInst$  ;it did work, print "DISK swapping installed"
  Call PrintMsg
  Jmp  Short SayHello
    
DiskFailed:
  Mov  DX,Offset NoDisk$    ;report that the disk is not available, and why
  Call PrintMsg
  Call B$FERR               ;BASIC's ERR function tells why
  Push AX                   ;pass that on to STR$
  Call B$STI2
  Push AX                   ;pass the returned string on to PRINT
  Call B$PESD

SayHello:
  Mov  AH,9                 ;PRINT ID$
  Mov  DX,Offset ID$ + 4    ;add 4 to bump past the descriptor
  Int  21h

  Mov  AX,Offset HotKey     ;CALL PopUpHere(&H41F, ID$)
  Push AX
  Mov  AX,Offset ID$
  Push AX
  Call PopUpHere

  Jmp  EndIt                ;skip over the popup code
  Nop                       ;this is just in case MASM uses a 2-byte jump!

;-- TO CREATE AN EMPTY TEMPLATE REMOVE THE REMAINING CODE TO THE ENDIT LABEL
;   The following code gets control when the hot key is pressed or Interrupt
;   0AAh is called.

  Call SwapCode             ;see if we were popped up via Interrupt 0AAh
  Dec  AX                   ;a quick way to see if AX = 1
  Jnz  NotAA                ;no, so we got here via the hot key

  Mov  AX,Offset Zero       ;call PopDeinstall
  Push AX
  Mov  AX,Offset ID$
  Push AX
  Call PopDeinstall

  Call PopDown              ;then pop down to complete deinstallation

NotAA:
  Xor  AX,AX                ;see if the monitor is color or monochrome
  Mov  ES,AX
  Cmp  Byte Ptr ES:[463h],0B4h
  Je   DoBlockCopy          ;mono, skip ahead knowing there's only 25 lines
  
  Mov  ScrSeg,0B800h        ;color, set the video segment to 0B800h
  
  Mov  AX,1200h             ;see if it's an EGA or VGA
  Mov  BL,10h
  Int  10h
  
  Cmp  BL,10h               ;if BL is still 10h then it's neither EGA nor VGA
  Je   DoBlockCopy          ;and we know the screen has only 25 lines
  
  Mov  AL,ES:[484h]         ;EGA or VGA stores the screen rows at 0:484h
  Inc  AL
  Mov  ScrRows,AL           ;save the number of rows
  
DoBlockCopy:                ;save the top three lines to memory we allocated
  Push DS
  Xor  SI,SI
  Xor  DI,DI
  Mov  ES,BufSeg
  Mov  CX,ScrnSize / 2
  Mov  DS,ScrSeg
  Rep  Movsw
  Pop  DS

  Call CursorSave           ;save the current cursor state
  Mov  SaveCsr,AX
  Mov  SaveCsr+2,DX

;PDQPrint "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿", One, One, Seven
;PDQPrint "³ Enter a name for the screen:                                    ³", 2, One, Seven
;PDQPrint "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ", 3, One, Seven
  Mov  AX,Offset Top$
  Push AX
  Mov  AX,Offset One
  Push AX
  Push AX
  Mov  AX,Offset Seven
  Push AX
  Call PDQPrint

  Mov  AX,Offset Prompt$
  Push AX
  Mov  AX,Offset Two
  Push AX
  Dec  AX                   ;one byte less code than [Mov AX,Offset One]
  Dec  AX
  Push AX
  Mov  AX,Offset Seven
  Push AX
  Call PDQPrint

  Mov  AX,Offset Bottom$
  Push AX
  Mov  AX,Offset Three
  Push AX
  Mov  AX,Offset One
  Push AX
  Mov  AX,Offset Seven
  Push AX
  Call PDQPrint

  Mov  AH,0Fh               ;get the current video page
  Int  10h
  Mov  AH,2                 ;LOCATE 2, 32
  Mov  DH,1
  Mov  DL,31
  Int  10h

  Mov  AX,Offset FileName$  ;BIOSInput FileName$, 112
  Push AX
  Mov  AX,Offset Inverse
  Push AX
  Call BIOSInput

  Push DS                   ;restore the top three lines
  Xor  SI,SI
  Xor  DI,DI
  Mov  ES,ScrSeg
  Mov  CX,ScrnSize / 2
  Mov  DS,BufSeg
  Rep  Movsw
  Pop  DS

  Mov  AX,Offset SaveCsr    ;restore the cursor
  Push AX
  Call CursorRest

  Mov  B$SEG,ES             ;set the video segment for BSAVE
                            ;(ScrSeg is still in ES)

  Mov  BX,Offset FileName$  ;save the screen to a file
  Push BX                   ;send this parameter now while we have it
  
  Push DS                   ;find the end of the file name (the space)
  Pop  ES
  Mov  DI,[BX+02]
  Mov  CX,[BX]
  Mov  AL," "
  Repne Scasb
  
  Xor  AX,AX                ;make a zero
  Mov  Byte Ptr [DI-01],AL  ;make an ASCIIZ string (SCRNCAP.BAS uses RTRIM$)
  Push AX                   ;pass the 0 to BSAVE for the address
  Mov  AL,ScrCols           ;calculate ScrRows * ScrCols * 2
  Mul  ScrRows
  Shl  AX,1                 ;now AX holds the size of the screen in bytes
  Push AX                   ;pass that on to BSAVE too
  Call B$BSAV               ;save the file

  Call PopDown              ;and pop down

;-- TO CREATE AN EMPTY TEMPLATE REMOVE THE CODE ABOVE TO THE PREVIOUS REMARK

EndIt:
  Mov  AX,Offset ID$        ;CALL EndTSR(ID$)
  Push AX
  Call EndTsr

Main Endp


;-- TO CREATE AN EMPTY TEMPLATE REMOVE THE FOLLOWING PROCEDURE, LEAVE "END"
PrintMsg Proc Near          ;prints a "$"-terminated message pointed to by DX
  Mov  AH,9                 ;use DOS function 9
  Int  21h
  Ret                       ;return to caller
PrintMsg Endp

End
