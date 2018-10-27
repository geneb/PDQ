;********** SCRNCAP.ASM - .ASM translation of SCRNCAP.BAS w/BASIC as comments

;Copyright (c) 1991 Ethan Winer


;To take as little DOS memory as possible when this program is installed as
;a TSR, you should link it with the STR00512.OBJ and other "stub" files:
;
;   masm scrncap;
;   link /ex/noe/far/packc scrncap startup str00512 _noerror, , nul, pdq;
;   exe2com scrncap


.Model Medium               ;all P.D.Q. programs are medium model

Public Main                 ;the main must be public and named Main
Include MACROS.ASM          ;this helps define data

Extrn B$BSAV: Proc          ;in BSAVE.ASM
Extrn B$CEND: Proc          ;in PDQ.ASM
Extrn B$FCMD: Proc          ;in COMMAND$.ASM

Extrn BIOSInput: Proc       ;in BIOSINPT.ASM
Extrn CursorRest: Proc      ;in CURSORSR.ASM
Extrn CursorSave: Proc      ;in CURSORSR.ASM
Extrn EndTSR: Proc          ;in ENDTSR.ASM
Extrn PDQPrint: Proc        ;in PDQPRINT.ASM
Extrn PopDeinstall: Proc    ;in POPUP.ASM
Extrn PopDown: Proc         ;in POPUP.ASM
Extrn PopUpHere: Proc       ;in POPUP.ASM
Extrn TSRInstalled: Proc    ;in TSRINST.ASM

ScrCols = 80                ;default to 80 columns
ScrnSize = 3 * ScrCols * 2  ;3 lines * 80 columns for prompt and input field

.Data?
  DeeGroup  DW 1 Dup (?)    ;DGROUP is a reserved word to MASM
  BufSeg    DW 1 Dup (?)
  SaveCsr   DW 2 Dup (?)

.Data
  Extrn B$SEG:Word          ;in PDQDATA.ASM

  One       DW 1            ;One = 1
  Two       DW 2
  Three     DW 3
  Seven     DW 7            ;Seven = 7
  Inverse   DW 112
  HotKey    DW 41Fh         ;Ctrl-S
  ScrSeg    DW 0B000h       ;assume monochrome
  ScrRows   DB 25           ;assume 25 rows

  DefStr ID$,"ScrnCap (c) 1991 Crescent Software - press Ctrl-S to activate$"
  DefStr Top$,     "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿"
  DefStr Prompt$,  "³ Enter a name for the screen:                                    ³"
  DefStr Bottom$,  "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ"
  DefStr FileName$,"                                  "
  Unable$   DB "Unable to de-install SCRNCAP$"
  NotRes$   DB "SCRNCAP is not resident - try again without /U$"
  Already$  DB "SCRNCAP already installed - use /U to deinstall$"

.Code

Main Proc

;DGROUP = TSRInstalled%(ID$)
  Mov  AX,Offset ID$
  Push AX
  Call TSRInstalled
  Mov  DeeGroup,AX

;IF INSTR(UCASE$(COMMAND$), "/U") THEN
  Call B$FCMD               ;call COMMAND$
  Mov  BX,AX                ;copy the descriptor address to BX
  Mov  CX,[BX]              ;search COMMAND$ looking for "/" only
  Mov  DI,[BX+02]           ;skip the UCASE$ and the "U" nonsense
  Mov  AL,"/"
  Repne Scasb               ;search for the "/", STARTUP.ASM sets ES = DS
  Jne  NoCmd                ;it's not in there

  ;IF DGROUP THEN
  Cmp  DeeGroup,0
  Je   NotResident
  
    ;Okay = PopDeinstall%(DGROUP, ID$)
  Mov  AX,Offset DeeGroup
  Push AX
  Mov  AX,Offset ID$
  Push AX
  Call PopDeinstall
  
    ;IF NOT Okay THEN
  Or   AX,AX                ;test AX directly, skip assigning it to Okay
  Jnz  EndNow

      ;PRINT "Unable to de-install SCRNCAP"
  Mov  AH,9                 ;use the DOS print service
  Mov  DX,Offset Unable$
  Int  21h
  Jmp  Short EndNow

    ;END IF
  ;ELSE
NotResident:
    ;PRINT "SCRNCAP is not resident -- try again without /U"
  Mov  AH,9                 ;use the DOS print service
  Mov  DX,Offset NotRes$
  Int  21h
  
  ;END IF
  
EndNow:
  ;END
  CALL B$CEND

;ELSE
NoCmd:
  ;IF DGROUP THEN
  Cmp  DeeGroup,0
  Je   SayHello
  
    ;PRINT "SCRNCAP already installed - use /U to deinstall"
  Mov  AH,9
  Mov  DX,Offset Already$
  Int  21h

    ;END
  Jmp  Short EndNow
  
  ;END IF
;END IF


SayHello:
;PRINT ID$
  Mov  AH,9
  Mov  DX,Offset ID$ + 4    ;add 4 to bump past the descriptor
  Int  21h

;BufSeg = AllocMem%(ScrnSize)
  Mov  BX,ScrnSize / 16     ;480 bytes = 30 16-byte paragraphs
  Mov  AH,48h
  Int  21h
  Mov  BufSeg,AX

;CALL PopUpHere(&H41F, ID$)
  Mov  AX,Offset HotKey
  Push AX
  Mov  AX,Offset ID$
  Push AX
  Call PopUpHere

;GOTO EndIt
  Jmp  EndIt
  Nop                       ;this is just in case MASM uses a 2-byte jump!

;DEF SEG = 0
;IF PEEK(&H463) <> &HB4 THEN
  Xor  AX,AX
  Mov  ES,AX
  Cmp  Byte Ptr ES:[463h],0B4h
  Je   DoBlockCopy
  
  ;ScrSeg = &HB800
  Mov  ScrSeg,0B800h
  
  ;Registers.AX = &H1200
  ;Registers.BX = &H10
  ;Interrupt &H10, Registers
  Mov  AX,1200h
  Mov  BL,10h
  Int  10h
  
  ;IF (Registers.BX AND &HFF) <> &H10 THEN
  Cmp  BL,10h
  Je   DoBlockCopy
  
    ;ScrRows = PEEK(&H484) + 1
  Mov  AL,ES:[484h]
  Inc  AL
  Mov  ScrRows,AL
  
  ;END IF
;END IF

DoBlockCopy:
;BlockCopy ScrSeg, Zero, BufSeg, Zero, ScrnSize
  Push DS
  Xor  SI,SI
  Xor  DI,DI
  Mov  ES,BufSeg
  Mov  CX,ScrnSize / 2
  Mov  DS,ScrSeg
  Rep  Movsw
  Pop  DS

;SaveCsr& = CursorSave&
  Call CursorSave
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

;LOCATE 2, 32
  Mov  AH,0Fh               ;get current page
  Int  10h
  Mov  AH,2
  Mov  DH,1
  Mov  DL,31
  Int  10h

;BIOSInput FileName$, 112
  Mov  AX,Offset FileName$
  Push AX
  Mov  AX,Offset Inverse
  Push AX
  Call BIOSInput

;IF INSTR(FileName$, ".") = 0 THEN              ;why bother with this....
  ;LSET FileName$ = RTRIM$(FileName$) + ".SCR"
;END IF

;BlockCopy BufSeg, Zero, ScrSeg, Zero, ScrnSize
  Push DS
  Xor  SI,SI
  Xor  DI,DI
  Mov  ES,ScrSeg
  Mov  CX,ScrnSize / 2
  Mov  DS,BufSeg
  Rep  Movsw
  Pop  DS

;CursorRest SaveCsr&
  Mov  AX,Offset SaveCsr
  Push AX
  Call CursorRest

;DEF SEG = ScrSeg
  Mov  B$SEG,ES             ;ScrSeg is still in ES
  
;BSAVE RTRIM$(FileName$), 0, ScrRows * ScrCols * 2
  Mov  BX,Offset FileName$
  Push BX                   ;send this parameter now while we have it
  
  Push DS
  Pop  ES
  Mov  DI,[BX+02]
  Mov  CX,[BX]
  Mov  AL," "
  Repne Scasb
  Xor  AX,AX                ;make a zero
  Mov  Byte Ptr [DI-01],AL  ;make an ASCIIZ string instead of using RTRIM$
  Push AX                   ;pass the 0 to BSAVE
  Mov  AL,ScrCols           ;calculate ScrRows * ScrCols * 2
  Mul  ScrRows
  Shl  AX,1
  Push AX                   ;pass that on to BSAVE too
  Call B$BSAV               ;save the file

;CALL PopDown
  Call PopDown

EndIt:
;CALL EndTSR(ID$)
  Mov  AX,Offset ID$
  Push AX
  Call EndTsr

Main Endp
End
