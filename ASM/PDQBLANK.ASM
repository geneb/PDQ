;********** PDQBLANK.ASM - shows how to take over interrupts manually

;Copyright (c) 1991 Crescent Software
;Written by Nash Bly and Ethan Winer, translated from PDQBLNK2.BAS


;For the smallest code size and memory use assemble this file as follows:
;
;  masm pdqblank ;
;  link /far/packc startup pdqblank, , nul, pdq ;
;  exe2com pdqblank


.Model Medium, Basic

Public Main                     ;the main Proc must be public and named Main
Include MACROS.ASM              ;this helps define data

Extrn EndTSR: Proc              ;this is in ENDTSR.ASM
Extrn ResetKeyboard:Proc        ;this is in RESETKBD.ASM
   
;CONST DelayTime% = 2 * 60 * 18
;CONST NumBytes% = 25 * 80 * 2
    DelayTime = 2 * (60 * 18)   ;2 minute blanking delay: Min * (Sec * Ticks)
    NumBytes = 25 * 80 * 2      ;the number of bytes of video memory to save
                                ;change the 25 to 43 or 50, but that will
.Data                           ;  take more memory when resident
    Even
    DefStr ID$, "PDQBLANK 1.00" ;every TSR needs an ID string

.Code
;-- This data must be in the code segment because when an interrupt handler
;   receives control, only the contents of the CS register is known.
;
    ArraySeg DW 0               ;the segment to save the screen contents into
    VideoSeg DW 0B800h          ;the video segment, assume a color display
    OldInt8  DD 0               ;save the original Interrupt 8 address here
    OldInt9  DD 0               ;save the original Interrupt 9 address here
    TicksPassed DW 0            ;this counts the timer ticks as they occur
    ScrnBlanked DB 0            ;this tracks if the screen is blanked or not


Main Proc                       ;this is main program entry point as startup

;CALL PDQPrint(Descriptor&, CSRLIN, POS(0), 7)
    Mov  BX,1                   ;print the sign-on message to the CON device
    Mov  CX,[ID$]               ;show DOS how long the ID$ is
    Mov  DX,[ID$+2]             ;and also where the string data begins
    Mov  AH,40h                 ;service 40h = Write to file or device
    Int  21h                    ;print the sign-on message
    

;ArraySeg = AllocMem%(NumBytes)
    Mov  BX,NumBytes / 16       ;allocate NumBytes / 16 paragraphs of memory
    Mov  AH,48h                 ;allocate memory service
    Int  21h                    ;call DOS to do the work
    Mov  CS:ArraySeg,AX         ;save the segment DOS returned for later


;DEF SEG = 0
;IF PEEK(&H463) = &HB4 THEN VideoSeg = &HB000 ELSE VideoSeg = &HB800
    Xor  AX,AX                  ;look in low memory to know the video segment
    Mov  ES,AX
    Cmp  Byte Ptr ES:[463h],0B4h    ;is it monochrome?
    Jne  @F                         ;no, so the default is already correct
    Mov  CS:VideoSeg,0B000h         ;yes, change the segment to reflect that


;-------- Set up the intercept for keyboard Interrupt 9.
;
;Registers9.IntNum = 9: CALL PointIntHere(Registers9): GOTO Install8
@@:
    Mov  AX,3509h               ;get address for the current Int 9 handler
    Int  21h                        ;DOS service 35h does this for us
    Mov  Word Ptr CS:[OldInt9],BX   ;save the old address
    Mov  Word Ptr CS:[OldInt9+2],ES ;and the old segment

    Push DS                     ;save DS for a moment while we change it
    Push CS                     ;copy CS into DS to set the new vector
    Pop  DS
    Mov  DX,Offset CS:NewInt9   ;the new handler's address goes in DX
    Mov  AX,2509h               ;set Int 9 to point to the new handler
    Int  21h                    ;DOS service 25h does this for us
   ;Pop  DS                     ;restore DS (not truly needed until below)


;-------- Set up the intercept for timer Interrupt 8.
;
;Registers8.IntNum = 8: CALL PointIntHere(Registers8): GOTO EndIt
    Mov  AX,3508h               ;get address for the current Int 8 handler
    Int  21h                        ;DOS service 35h does this for us
    Mov  Word Ptr CS:[OldInt8],BX   ;save the old address
    Mov  Word Ptr CS:[OldInt8+2],ES ;and the old segment

   ;Push DS                     ;save DS for a moment while we change it
   ;Push CS                     ;copy CS into DS to set the new vector
   ;Pop  DS                     ;(these three lines aren't really necessary)
    Mov  DX,Offset CS:NewInt8   ;the new handler's address goes in DX
    Mov  AX,2508h               ;set Int 8 to point to the new handler
    Int  21h                    ;DOS service 25h does this for us
    Pop  DS                     ;restore DS


;-------- Terminate and stay resident.
;
;EndIt:
;CALL EndTSR(Descriptor&)
    Mov  AX,Offset ID$          ;show EndTSR where the descriptor for ID$ is
    Push AX
    Call EndTSR                 ;terminate and stay resident


;---------------------------------------------------------------------------
; This block of code receives control each time a key is pressed.
;---------------------------------------------------------------------------
NewInt9:
    Sti                         ;always enable further interrupts first
    Pushf                       ;save the flags before making a comparison

;TicksPassed = 0
    Mov  CS:[TicksPassed],0     ;we arrived here because they pressed a key,
                                ;  so reset the counter
;IF ScrnBlanked THEN
    Cmp  CS:[ScrnBlanked],0     ;is the screen currently blanked?
    Je   @F                     ;no, so skip ahead to handle the key normally
    
;CALL BlockCopy(ArraySeg, Zero, VideoSeg, Zero, NumBytes)
    Pushm AX,CX,SI,DI,DS,ES     ;save the registers we'll use
    Sub  SI,SI                  ;we're reading from address 0 in ArraySeg
    Sub  DI,DI                  ;and writing to address 0 in video memory
    Mov  DS,CS:[ArraySeg]       ;we're reading from the buffer segment
    Mov  ES,CS:[VideoSeg]       ;and writing to video memory
    Mov  CX,NumBytes / 2        ;we'll copy words instead of bytes ( / 2)
    Cld                         ;copy forward
    Rep  Movsw                  ;this restores the screen

;ScrnBlanked = 0
    Mov  CS:[ScrnBlanked],0     ;show that the screen is not blanked anymore

;Dummy = INP(&H60)
    In   AL,60h                 ;eat the keypress (optional, okay to rem out)

;CALL ResetKeyboard
    Call ResetKeyboard          ;reset the keyboard hardware and PIC chip

;CALL ReturnFromInt(Registers9)
    Popm ES,DS,DI,SI,CX,AX      ;restore the registers we saved
    Popf                        ;and the original flags too
    Iret                        ;and return to the underlying program
;END IF

@@:
;CALL GotoOldInt(Registers9)
    Popf                        ;restore the flags
    Jmp  DWord Ptr CS:[OldInt9] ;continue on to the original Int 9 handler


;---------------------------------------------------------------------------
; This block of code receives control each time a timer tick occurs.
;---------------------------------------------------------------------------
NewInt8:
    Sti                         ;always enable further interrupts first
    Pushf                       ;save the flags before making a comparison
    
;IF ScrnBlanked THEN CALL GotoOldInt(Registers8)
    Cmp  CS:[ScrnBlanked],0     ;is the screen currently blanked?
    Je   @F                     ;no, go see if it's time to blank it
    Popf                        ;the screen is now blanked, do nothing and
    Jmp  DWord Ptr CS:[OldInt8] ;  continue on to the original Int 8 handler

;CALL CallOldInt(Registers8)    ;the screen is not blanked
@@:
    Call DWord Ptr CS:[OldInt8] ;call the original Interrupt 8 handler
    Pushf                       ;then save the flags again

;TicksPassed = TicksPassed + 1
    Inc  CS:[TicksPassed]       ;show that another timer tick occurred

;IF TicksPassed > DelayTime% THEN
    Cmp  CS:[TicksPassed],DelayTime ;time to save the screen automatically?
    Jna  Exit                       ;no, skip ahead

;CALL BlockCopy(VideoSeg, Zero, ArraySeg, Zero, NumBytes)
    Pushm AX,CX,SI,DI,DS,ES     ;save the registers we'll use
    Sub  SI,SI                  ;we're reading from address 0 in video memory
    Sub  DI,DI                  ;and writing to address 0 in a DOS buffer
    Mov  DS,CS:[VideoSeg]       ;we're reading from the video memory segment
    Mov  ES,CS:[ArraySeg]       ;and writing to the DOS buffer segment
    Mov  CX,NumBytes / 2        ;we'll copy words instead of bytes ( / 2)
    Cld                         ;copy forward
    Rep  Movsw                  ;this saves the screen
   
;ScrnBlanked = -1
    Mov  CS:[ScrnBlanked],-1    ;show that the screen is now blanked

;FOR X = 0 TO NumBytes - 1 STEP 2: CALL PDQPoke2(X, Zero): NEXT
    Sub  AX,AX                  ;clear video memory to CHR$(0) bytes on black
    Push DS                     ;DS already holds the video memory segment
    Pop  ES                     ;so copy that to ES
    Sub  DI,DI                  ;reset DI to the start of video memory
    Mov  CX,NumBytes / 2        ;fill this many words in memory
    Rep  Stosw                  ;clear the screen
;END IF

;CALL ReturnFromInt(Registers8)
    Popm ES,DS,DI,SI,CX,AX      ;restore the registers we saved

Exit:
    Popf                        ;and the original flags too
    Retf 2                      ;return to the underlying application

Main Endp
End
