;********** CURDIR$.ASM - P.D.Q. replacement for BASIC 7's CURDIR$ function

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
    Extrn P$MakeTemp:Proc   ;this is in MAKETEMP.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Extrn P$NullDesc:Word   ;this is in PRINTDAT.ASM

.Code

B$FCD0 Proc                 ;arrive here when CURDIR$ is used with no argument

    Mov  AX,Offset P$NullDesc ;get the address of the dummy null descriptor
    Push AX                 ;pass it on to B$FCD1
    Call Far Ptr B$FCD1     ;let B$FCD1 do the work
    Ret                     ;return to BASIC

B$FCD0 Endp



B$FCD1 Proc Uses SI DI, Drive$:Word     ;arrive here when an argument is used

    Local Buffer[80]:Byte   ;this is where the output will be placed by DOS

    Mov  P$PDQErr,0         ;assume no errors will happen
    
    Cld                     ;clear direction flag so string moves are forward
    Push DS                 ;assign ES=DS for the string operations below
    Pop  ES
    Lea  DI,Buffer          ;point DI to the start of the output buffer

    Mov  BX,Drive$          ;put address of Drive$ descriptor into BX
    Mov  DL,[BX]            ;assume they want the default drive for now
    Or   DL,DL              ;check LEN(Drive$)
    Jnz  NotNull            ;it's not null, skip ahead

    Mov  AH,19h             ;get the current drive
    Int  21h                ;through DOS
    Add  AL,"A"             ;adjust to an ASCII character
    Stosb                   ;store it into the output buffer
    Jmp  Short Do_It        ;ands null, leave DL holding 0 and call DOS

NotNull:
    Mov  BX,[BX+02]         ;put address of first character in Drive$ into BX
    Mov  DL,[BX]            ;put ASC(Drive$) into DL

    Cmp  DL,"a"             ;is it less than "a"?
    Jb   NoCap              ;yes, skip
    Sub  DL,32              ;no, convert to upper case

NoCap:
    Mov  AL,DL              ;copy the drive they want to AL
    Stosb                   ;and stuff it into the output buffer
    Sub  DL,64              ;"A" now equals 1, "B" = 2, etc. for DOS

Do_It:
    Mov  AL,":"             ;create the colon
    Stosb                   ;assign it
    Mov  AL,"\"             ;next comes the backslash
    Stosb                   ;and assign that too

    Mov  SI,DI              ;DOS places the path name at DS:SI
    Mov  AH,47h             ;get current directory service
    Int  21h                ;call DOS
    Jnc  CopyString         ;if no carry we're okay
    
    Call P$DoError          ;else handle the error
    Xor  CX,CX              ;show that we're returning a null string
    Jmp  Short Done         ;and make a null string

    
CopyString:
    Push SI                 ;save where we are in the output buffer
    Mov  CX,2               ;we already have three characters ("C:\")
                            ;  (CX is pre-incremented below)
CountIt:
    Lodsb                   ;get a character from the directory string
    Inc  CX                 ;show that there's another one
    Or   AL,AL              ;are we at the end of the directory name?
    Jnz  CountIt            ;no, keep going
    Pop  SI                 ;restore SI to the stack buffer address
    Sub  SI,3               ;back up SI to the drive letter

Done:
    Call P$MakeTemp         ;yes, request a string CX bytes long
    Rep  Movsb              ;copy it from the buffer to the string pool
    Mov  AX,BX              ;show BASIC where the descriptor is located
    Ret                     ;return to BASIC

B$FCD1 Endp
End
