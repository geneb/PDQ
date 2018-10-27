;********** HOOKINT0.ASM - takes over the divide by zero interrupt

;Copyright (c) 1991 Ethan Winer


;4-22-91 as an experiment we'll return 0 in AX rather than what it held.
;(see remmed out code below)


;Syntax:
;
;   CALL HookInt0(Option)
;   CALL UnhookInt0
;
;Where Option is zero to show that UnHookInt0 is to be called automatically,
;or non-zero if you intend to unhook it manually using UnhookInt0.

;Note that a different method of returning to the called program is needed,
;depending on the type of CPU that is installed.  When an Interrupt 0 occurs
;on an 8086 or 8088 processor, a subsequent Iret returns to the instruction
;following the one that caused the interrupt.  This is the normal way an
;interrupt returns.  However, 80286 and later processors return to the same
;instruction that caused the interrupt.  Therefore, the interrupt handler
;must know which type of CPU is installed, and react accordingly.  This messy
;situation is further complicated because the length of the IDIV instruction
;varies, depending upon whether a register or variable is used as a divisor.


.Model Medium, Basic
    Extrn B_ONEXIT:Proc     ;this is in B_ONEXIT.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Data?
    Old0Adr DW 1 Dup (?)    ;this saves the original Interrupt 0 address
    Old0Seg DW 1 Dup (?)

.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    
.Code

HookInt0 Proc, Option:Word

    Cmp  CS:BeenHere,0      ;is the Interrupt 0 handler already resident?
    Jne  Exit               ;yes, skip ahead
    Dec  CS:BeenHere        ;no, decrement BeenHere to -1 as a flag

    Push SP                 ;see if we have an 8086/88 CPU, or a later model
    Pop  AX                 ;by seeing when SP is decremented during a Push
    Cmp  AX,SP              ;compare the results
    Mov  AL,-1              ;assume it's not an 8086/88
    Je   Not88              ;we were right
    Inc  AX                 ;increment AL up to zero (Inc AX is less code)

Not88:
    Mov  CS:CPUType,AL      ;in either case, assign CPUType accordingly
    Mov  AX,3500h           ;ask DOS for the current Interrupt 0 address
    Int  21h
    Mov  Old0Adr,BX         ;save it so we can reinstate it when we end later
    Mov  Old0Seg,ES

    Mov  AX,2500h           ;point Interrupt 0 to our local handler below
    Mov  DX,Offset P$TrapInt0
    Push DS                 ;save DS because DOS needs the address in DS:DX
    Push CS                 ;copy CS to DS
    Pop  DS
    Int  21h                ;let DOS do the dirty work
    Pop  DS                 ;and then restore DS

    Mov  BX,Option          ;get the address for the option parameter
    Cmp  Word Ptr [BX],0    ;do they want to use B_ONEXIT?
    Jne  Exit               ;no, exit now
    
    Push CS                 ;yes, register UnhookInt0 with B_ONEXIT
    Mov  AX,Offset UnhookInt0
    Push AX
    Call B_OnExit           ;tell B_ONEXIT to call UnhookInt0 upon ending

Exit:
    Ret                     ;return to BASIC

HookInt0 Endp



UnhookInt0 Proc

    Cmp  CS:BeenHere,0      ;is the Interrupt 0 handler already installed?
    Je   Exit               ;no, skip ahead
    Inc  CS:BeenHere        ;yes, increment BeenHere to clear it to 0

    Mov  AX,2500h           ;restore the original Interrupt 0 address
    Mov  DX,Old0Adr         ;DOS expects the new interrupt address in DS:DX
    Push DS                 ;preserve DS for a moment
    Mov  DS,Old0Seg
    Int  21h                ;let DOS do the actual work
    Pop  DS                 ;restore DS

Exit:
    Ret                     ;return to caller

UnhookInt0 Endp



P$TrapInt0 Proc

    Sti                     ;enable further interrupts
    Mov  SS:P$PDQErr,11     ;assign a "Division by zero" error
    
    Cmp  CS:CPUType,0       ;are we running on an 8086 or 8088?
    Je   DoneInt0           ;yes, a simple IRet will get us out

    Mov  CS:SaveBX,BX       ;save BX in case we have to trash it
   ;Mov  CS:SaveAX,AX       ;and AX too
    Mov  CS:SaveES,ES       ;and ES too

    Pop  BX                 ;no, retrieve the address to return to
    Pop  ES                 ;and the segment too
    Inc  BX                 ;skip past the first byte of the IDIV (or DIV)
    Mov  AL,ES:[BX]         ;load the instruction byte that failed
    Inc  BX                 ;then skip over the second instruction byte

    And  AL,0F0h            ;mask off the low nybble
    Cmp  AL,0F0h            ;see if it's a register or memory divide
    Je   @F                 ;it's a register divide, so we're all done
    Inc  BX                 ;it's memory, so skip over the next two bytes
    Inc  BX                 ;(A register IDIV or DIV is a 2-byte instruction,
                            ;  a memory byte or word DIV occupies 4 bytes.)
@@:
    Push ES                 ;restore the segment to return to
    Push BX                 ;and the address

   ;Mov  AX,CS:SaveAX       ;restore the saved registers
    Mov  BX,CS:SaveBX
    Mov  ES,CS:SaveES

DoneInt0:
    Call P$DoError          ;see if ON ERROR is in effect and handle it if so
    Xor  AX,AX              ;return AX set to 0
    IRet                    ;return to whomever screwed up

P$TrapInt0 Endp

    BeenHere DB 0           ;this remembers if we've been here before
    CPUType  DB 0           ;this saves the CPU type (0 = 8086, -1 = later)
   ;SaveAX   DW 0           ;these save the registers we'll trash
    SaveBX   DW 0
    SaveES   DW 0

End
