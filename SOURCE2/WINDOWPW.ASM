;******** WINDOWPW.ASM - Window Print Wrap routine

;Copyright (c) 1991 Ethan Winer


;Syntax:
;
;  CALL WindowPrintW(Text$)

Comment |

The code in this file is based upon the following outline written in BASIC:

SUB PrintWrap (Work$) STATIC

  Tmp$ = Work$                          'work with a copy of the string

  DO

    Space = INSTR(Tmp$, " ")            'find the next space
    IF Space THEN                       'we found one
      Word$ = LEFT$(Tmp$, Space - 1)    'isolate this word
      Tmp$ = LTRIM$(MID$(Tmp$, Space))  'strip it from what remains
    ELSE
      Word$ = Tmp$                      'no space, so there's only one word
      Tmp$ = ""                         '  (or this was the last), erase Tmp$
    END IF

    Word$ = LTRIM$(RTRIM$(Word$))       'strip leading/trailing blanks

    Have = LRCol - WindowCol% - ULCol + 2       'how much room do we have?
    Need = LEN(Word$)                           'and how much do we need?

    IF Have < Need THEN CALL WindowPrintCR("")  'it won't fit, advance a line
    CALL WindowPrint(Word$)                     'either way print this word

    'add a trailing space if the last Print didn't wrap to the first column
    IF WindowCol% > 1 THEN CALL WindowPrint(" ")

  LOOP WHILE LEN(Tmp$)

END SUB

End Comment |


.Model Medium, Basic
    Extrn WindowCol:Proc    ;these are in WINDOW.ASM
    Extrn WindowPrint:Proc
    Extrn WindowPrintCR:Proc

;-- Using internal routines lets this work with both near and far strings
    Extrn B$FLEN:Proc       ;this is in LEN.ASM
    Extrn B$FMID:Proc       ;this is in MID$.ASM
    Extrn B$INS2:Proc       ;this is in INSTR2.ASM
    Extrn B$LEFT:Proc       ;this is in LEFT$.ASM
    Extrn B$LTRM:Proc       ;this is in LTRIM$.ASM
    Extrn B$RTRM:Proc       ;this is in RTRIM$.ASM
    Extrn B$SASS:Proc       ;this is in ASSIGN$.ASM
    Extrn B$SPAC:Proc       ;this is in SPACE$.ASM
    Extrn B$STDL:Proc       ;this is in STRDELET.ASM

.Data
    Extrn _ULCol:Byte       ;these are in WINDOW.ASM
    Extrn _LRCol:Byte
    
    Tmp$  DD 0              ;we'll work with a copy of the incoming string
    Spc$  DD 0              ;we need a single space string a few times below
    Word$ DD 0              ;this receives each word as it is isolated
    Spac  DW 0              ;this is the Space variable used with INSTR
    Null$ DD 0              ;this is an empty (null) string descriptor

.Code

WindowPrintW Proc, Work$:Word

    Sub  AX,AX              ;make a 1 as fast/small as possible
    Inc  AX                 ;  (Sub followed by Inc is smaller than Mov AX,1)
    Push AX
    Call B$SPAC             ;create a single space
    
    Push AX                 ;then assign it to Spc$ for use later
    Mov  AX,Offset Spc$
    Push AX
    Call B$SASS

    Mov  AX,Work$           ;assign the incoming string to a copy
    Push AX
    Mov  AX,Offset Tmp$
    Push AX
    Call B$SASS

Do:
    Mov  AX,Offset Tmp$     ;look for a space in Tmp$
    Push AX
    Mov  AX,Offset Spc$
    Push AX
    Call B$INS2             ;this is the two-argument form of INSTR
    Mov  Spac,AX            ;save the result for later

    Or   AX,AX              ;did INSTR find a space?
    Jz   NoSpace            ;no, skip ahead
    Mov  BX,Offset Tmp$     ;yes, Word$ = LEFT$(Tmp$, Space - 1)
    Push BX
    Dec  AX                 ;here's the Space - 1 code
    Push AX
    Call B$LEFT
    Push AX
    Mov  AX,Offset Word$
    Push AX
    Call B$SASS

    Mov  AX,Offset Tmp$     ;Tmp$ = LTRIM$(MID$(Tmp$, Space))
    Push AX
    Push Spac
    Mov  AX,32767           ;MID$ needs this parameter!
    Push AX                 ;thus: Tmp$ = LTRIM$(MID$(Tmp$, Space, 32767))
    Call B$FMID
    Push AX
    Call B$LTRM
    Push AX
    Mov  AX,Offset Tmp$
    Push AX
    Call B$SASS
    Jmp  Short DoneSpace    ;skip over the ELSE part of the code
    
NoSpace:                    ;this is the ELSE part of the code
    Mov  AX,Offset Tmp$
    Push AX                 ;push this now in anticipation of calling B$STDL
    Push AX                 ;and once again for the assignment to Word$
    Mov  AX,Offset Word$    ;Word$ = Tmp$
    Push AX
    Call B$SASS
    Call B$STDL             ;Tmp$ = "" (uses AX that's already on the stack)

DoneSpace:
    Mov  AX,Offset Word$    ;Word$ = LTRIM$(RTRIM$(Word$))
    Push AX
    Call B$RTRM
    Push AX
    Call B$LTRM
    Push AX
    Mov  AX,Offset Word$
    Push AX
    Call B$SASS
    
    Mov  BL,_LRCol          ;Have = LRCol - WindowCol% - ULCol + 2
    Call WindowCol
    Sub  BL,AL
    Sub  BL,_ULCol
    Inc  BL
    Inc  BL                 ;now BL holds the value of Have
    Mov  BH,0               ;clear BH so we can use all of BX below
    Push BX                 ;save it for a moment

    Mov  AX,Offset Word$    ;Need = LEN(Word$)
    Push AX
    Call B$FLEN
    Pop  BX                 ;retrieve Have
    Cmp  BX,AX              ;IF Have < Need THEN...
    Jnb  @F                 ;wrong, skip ahead

    Mov  AX,Offset Null$    ;CALL WindowPrintCR("")
    Push AX
    Call WindowPrintCR

@@:
    Mov  AX,Offset Word$    ;CALL WindowPrint(Word$)
    Push AX
    Call WindowPrint

    Call WindowCol          ;IF WindowCol% > 1 THEN CALL WindowPrint(" ")
    Cmp  AL,1
    Je   @F
    Mov  AX,Offset Spc$
    Push AX
    Call WindowPrint

@@:
    Mov  AX,Offset Tmp$     ;LOOP WHILE LEN(Tmp$)
    Push AX
    Call B$FLEN
    Or   AX,AX
    Jz   @F
    Jmp  Do

@@:
    Ret                     ;return to BASIC

WindowPrintW Endp
End
