;********** DEBUG.ASM - PDQ support for the BC.EXE /d Debug option

;Copyright (c) 1990 Ethan Winer


;This routine is called prior to each BASIC statement when the BC /d debug
;switch has been used.  Although it will make your programs run as slow as
;molassis, it can be invaluable as a debugging aid when your program crashes
;mysteriously.  This routine first checks to see if it has ever been called,
;and if not installs an Interrupt 4 handler (Int 4 is the Overflow interrupt)
;to catch errors caused by, say, a multiplication that cannot fit into the
;destination variable.
;
;Each time BC compiles a program fragment that could result in an overflow
;condition, it also generates an 8088 INTO instruction.  INTO is an often-
;overlooked instruction that checks the 8088 Overflow flag, and generates an
;Interrupt 4 if it is set.  Because we are installing a temporary interrupt
;handler, it must be able to uninstall itself automatically when your program
;ends.  And that's the fun part!
;
;We have designed P.D.Q. to allow one or more routines to chain themselves
;into the "exit path" just for this purpose.  Beginning with version 2.12 a
;routine may easily do this by calling the B_OnExit routine with the segment
;and address of a routine to be called automatically when the program ends.
;See the source listing for B_ONEXIT.ASM for details of how this works.

.Model Medium, Basic
    Extrn B$CEND: Proc    ;this is in PDQ.ASM
    Extrn B$ENRA: Proc    ;this is in SUBRECUR.ASM
    Extrn B$ENSA: Proc    ;this is in SUBSTAT.ASM
    Extrn B$FERR: Proc    ;this is in ERR.ASM
    Extrn B$FHEX: Proc    ;this is in HEX$.ASM
    Extrn B$PESD: Proc    ;this is in PRINT.ASM
    Extrn B$PSI2: Proc    ;this is in PRINTINT.ASM
    Extrn B$PSSD: Proc    ;this is in PRINT.ASM
    Extrn B_OnExit:Proc   ;this is in B_ONEXIT.ASM
    Extrn PDQMessage:Proc ;this is in PDQMSG.ASM
    Extrn PoolOkay:Proc   ;this is in POOLOKAY.ASM

.Data?
    Extrn PDQ_Stack_Foot:Byte   ;this is in PDQ.ASM
    Old4Adr DW 1 Dup(?)         ;saves the original Int4 address
    Old4Seg DW 1 Dup(?)         ;and segment

.Data
    Extrn P$TermCode:Byte       ;this is in PDQ.ASM
    Extrn P$PDQErr:Word         ;this is in ERRDATA.ASM
    Extrn P$BytesFree:Word      ;this is in STR#####.ASM
    Extrn P$BytesUsed:Word      ;this is in STR#####.ASM

    GOSUBLevel  DB 0        ;this tracks GOSUB levels, used by B$GOSA et. al.
    SaveErr     DW 0        ;this saves the error while PRINT is used

    ErrNum      DW 8, Offset ErrNumMsg
    ErrNumMsg   DB 13, 10, "Error "

    SCorrupt    DW 22, Offset SCorruptMsg   ;handled separate from PDQMessage
    SCorruptMsg  DB 13, 10, "String space corrupt"  ;(there's no BASIC error
                                                    ;  number for this)
    FCorrupt    DW 18, Offset FCorruptMsg   ;ditto for "Far heap corrupt"
    FCorruptMsg DB 13, 10, "Far heap corrupt"

    Error       DW 12, Offset ErrorMsg
    ErrorMsg    DB " at address "

    Colon       DW 1, Offset ColonMsg
    ColonMsg    DB ":"

    Colon2      DW 2, Offset Colon2Msg
    Colon2Msg   DB ": "

    BeenHere    DB 0

.Code

;---- This routine is called prior to each statement when /d is used.
;

B$LINA Proc Uses AX BX CX DX ES     ;save ALL registers used

    Cmp  BeenHere,0       ;have we ever been called?
    Jne  NoInit           ;yes, so we don't have to initialize again

    Dec  BeenHere         ;no, show that we have done this
    Mov  AX,3504h         ;ask DOS for the current Interrupt 4 address
    Int  21h
    Mov  Old4Adr,BX       ;save it so we can reinstate it when we end later
    Mov  Old4Seg,ES

    Push CS               ;chain the routine that unhooks Int 4 via B_OnExit
    Mov  AX,Offset Restore4
    Push AX
    Call B_OnExit

    Mov  AX,2504h         ;point Interrupt 4 to our local handler below
    Mov  DX,Offset P$Int4
    Push DS               ;save DS while we do this
    Push CS
    Pop  DS
    Int  21h
    Pop  DS

NoInit:
    Call PoolOkay         ;first see if the string pool is intact
    Or   AX,AX            ;test the return value
    Jnz  CheckFar         ;if it's non-zero (true) then we passed this test

    Mov  AX,Offset SCorrupt ;print "String space corrupt"
    Push AX               ;pass that on to PRINT
    Call B$PSSD           ;print it
    Jmp  Short PrintAdr   ;and go print the rest of the message

CheckFar:                 ;check the integrity of the "DOS far heap"
    Mov  AH,48h           ;allocate memory service
    Mov  BX,-1            ;ask for everything
    Int  21h              ;call DOS to do the hard stuff
    Cmp  AL,8             ;did DOS report an "insufficient memory" error
    Je   CheckErr         ;yes, and that's what we expected, continue

    Mov  AX,Offset FCorrupt ;no, print "Far heap corrupt"
    Push AX               ;pass that on to PRINT
    Call B$PSSD           ;print it
    Jmp  Short PrintAdr   ;and go print the rest of the message

CheckErr:
    Cmp  P$PDQErr,0       ;is there an error condition?
    Jne  IsError          ;yes, skip over the "lilly pad"
    Mov  AH,0Bh           ;ask DOS if a key is waiting to be read, so we can
    Int  21h              ;  abort if Ctrl-C or Ctrl-Break were pressed
    Jmp  Exit             ;no errors, get out now and avoid the rush

IsError:
    Mov  AX,P$BytesUsed   ;free up all string space so HEX$ and STR$ can work
                          ;  (in case the error was "Out of string space"
    Add  P$BytesFree,AX   ;show the entire pool as being free
    Xor  AX,AX            ;and zero bytes in use
    Mov  P$BytesUsed,AX   ;otherwise "Out of string space" would cripple HEX$

    Call B$FERR           ;call the ERR function to translate the error value
    Mov  SaveErr,AX       ;save it locally because PRINT keeps clearing it

    Mov  AX,Offset ErrNum ;print "Error "
    Push AX               ;pass that on to PRINT
    Call B$PSSD           ;print the message

    Push SaveErr          ;pass the error to the "integer print" routine
    Call B$PSI2           ;print the error number
    
    Mov  AX,Offset Colon2 ;print ": "
    Push AX
    Call B$PSSD           ;do it to it

    Mov  AX,Offset SaveErr;show PDQMessage where the error number is
    Push AX
    Call PDQMessage       ;this returns a descriptor address to the message
    Push AX               ;pass that on to PRINT
    Call B$PSSD           ;print the message

;-- The address in the program just past where the error occurred is now on
;   the stack, so use Hex$ to convert that to a displayable message.  Start
;   by retrieving the segment, and then get the address.  Subtract 5 from the
;   address to account for the five bytes comprising the call to us.
;
PrintAdr:
    Mov  AX,Offset Error  ;print " at address "
    Push AX
    Call B$PSSD

    Add  SP,10            ;clear the 5 "Uses" registers from the stack so we
                          ;  can find the address where the error occurred
    Pop  DX               ;get the address where the error happened
    Pop  AX               ;and then the segment
    Push DX               ;save the address again for later
    
    Xor  DX,DX            ;make a long integer
    Push DX               ;pass that on to Hex$
    Push AX
    Call B$FHEX           ;convert the segment to a Hex string
    Push AX               ;pass the descriptor address HEX$ returns to PRINT
    Call B$PSSD           ;print it

    Mov  AX,Offset Colon  ;print the separating colon
    Push AX
    Call B$PSSD

    Pop  AX               ;retrieve the address from the stack
    Sub  AX,5             ;point back just before the call to us in the code
    Xor  DX,DX            ;make a long integer
    Push DX               ;pass that on to Hex$
    Push AX
    Call B$FHEX           ;convert the segment to a Hex string
    Push AX               ;pass the descriptor address Hex$ returns to PRINT
    Call B$PESD           ;print it

    Mov  AX,SaveErr       ;get the ERR we saved earlier (PRINT trashed it)
    Mov  P$TermCode,AL    ;and use that for the ERRORLEVEL (we only need AL)
    Call B$CEND           ;end the program

Exit:
    Ret                   ;return to BASIC

B$LINA Endp



Restore4 Proc             ;this is called via B_OnExit when the program ends

    Mov  AX,2504h         ;restore the original Int 4 address
    Mov  DX,Old4Adr       ;and then chain to any other "exit handlers"
    Push DS               ;preserve DS for a moment
    Mov  DS,Old4Seg
    Int  21h
    Pop  DS
    Ret
    
Restore4 Endp



;The following routines are used to handle GOSUB and RETURN when /d is used.
;Normally, QuickBASIC compiles GOSUB and RETURN statements directly to the
;equivalent Call and Ret assembler commands.  However, if your program were
;to encounter a RETURN without a preceding GOSUB, a crash is the most likely
;result.  Therefore, these routines manipulate a variable (GOSUBLevel) that
;tracks each GOSUB and RETURN, and jumps to the error handler (in B$LINA
;above) if a RETURN is encountered when there wasn't a GOSUB.
;
B$GOSA Proc               ;this is called when GOSUB is used

    Pop  BX               ;retrieve the caller's return address
    Pop  DX               ;and segment
    Push BX               ;store the address higher on the stack for later
    Push DX               ;stuff the segment back
    Push AX               ;and the address to GOSUB to that BASIC set up
    Inc  GOSUBLevel       ;track this GOSUB level
    Ret                   ;"return" to the GOSUB target

B$GOSA Endp



B$RELA Proc               ;this is called when RETURN [Linenumber] is used

    Pop  CX               ;retrieve the caller's return address
    Pop  DX               ;and the segment too
    Pop  BX               ;discard the return address saved before by B$GOSA
    Dec  GOSUBLevel       ;show that we are doing a RETURN
    Js   Oops             ;there was no preceding GOSUB, crash hard now
    Push DX               ;stuff the caller's segment back onto the stack
    Push CX               ;and the address
    Ret                   ;return there

Oops:
    Jmp  P$OOPS

B$RELA Endp



B$RETA Proc               ;this is called when RETURN is used

    Dec  GOSUBLevel       ;show that we are doing a RETURN
    Js   Oops             ;there was no preceding GOSUB, crash hard now
    Pop  CX               ;as above in B$RELA, except discard the return
    Pop  DX               ;  address that was saved earlier
    Pop  CX
    Push DX
    Push CX
    Ret

Oops:
   ;Jmp P$OOPS            ;fall through into B$OOPS below

B$RETA Endp



P$OOPS Proc Near          ;this provides a clean way to crash (an oxymoron?)
                          ;127 is our replacement for QB's ERROR 3
    Mov  P$PDQErr,127     ;  (3 = "RETURN without GOSUB")
    Jmp  Far Ptr B$LINA   ;let the other guy handle this

P$OOPS Endp



;When /d is used, BC calls this to enter a static sub instead of the usual
;B$ENSA routine.  This checks to see if there's enough stack space to handle
;the number of variables being used.  In regular QB, this code is placed just
;before the B$ENSA routine, so it falls into B$ENSA when it's finished.  We
;don't want to bloat all programs with this code, so it is added only when
;you use /d and this file is included in your program.  That's why we must
;exit by jumping manually into B$ENSA.
;
B$ENSD Proc

    Mov  AX,SP            ;calculate the free stack space in AX
    Sub  AX,Offset PDQ_Stack_Foot
    Sub  AX,10            ;we'll need an extra ten bytes for overhead
    
    Cmp  AX,CX            ;is there enough to satisfy the request in CX?
    Jge  Exit             ;yes, we're outa here
    Mov  P$PDQErr,126     ;no, assign our own "Out of stack space" error
    Jmp  Far Ptr B$LINA   ;and let B$LINA do the rest

Exit:
    Jmp  Far Ptr B$ENSA   ;jump into the code that actually handles the entry

B$ENSD Endp



;When /d is used, BC calls this to enter a non-static sub.  The comments
;above are relevant here too, except that we jump into B$ENRA.  That's the
;equivalent to B$ENSA, except for recursive subprograms and functions.
;
B$ENRD Proc

    Mov  AX,SP            ;calculate the free stack space in AX
    Sub  AX,Offset PDQ_Stack_Foot
    Sub  AX,10            ;we'll need an extra ten bytes for overhead

    Cmp  AX,CX            ;is there enough to satisfy the request in CX?
    Jge  Exit             ;yes
    Mov  P$PDQErr,126     ;no, assign our own "Out of stack space" error
    Jmp  Far Ptr B$LINA   ;and let B$LINA do the rest

Exit:
    Jmp  Far Ptr B$ENRA   ;jump into the code that actually handles the entry

B$ENRD Endp



P$Int4 Proc               ;this procedure handles the "overflow" Interrupt 4

    Sti                   ;reenable further interrupts
    Mov  SS:P$PDQErr,125  ;this is the P.D.Q. "Overflow" error number
    IRet                  ;the next time B$LINA is called we'll trap this
    
P$Int4 Endp
End
