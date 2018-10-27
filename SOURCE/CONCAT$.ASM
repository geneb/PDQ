;********* CONCAT$.ASM - PDQ replacement for BASIC's B$SCAT routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$TempStr:Proc    ;this is in TEMPSTR.ASM
    Extrn P$GetTemp:Proc    ;this is in GETTEMP.ASM
    Extrn P$FreeTemp:Proc   ;this is in FREETEMP.ASM

.Data?
    SaveAddr DW 1 Dup (?)   ;this is a temporary scratch variable

.Data
    Extrn P$BytesFree:Word  ;these are in STR#####.ASM
    Extrn P$BytesUsed:Word

.Code

B$SCT1 Proc                 ;this is the same as B$SCAT below
    Nop                     ;this forces CodeView to show the correct name
B$SCT1 Endp                 ;fall into the code below


B$SCAT Proc Uses SI DI, Str1:Word, Str2:Word

    Call P$GetTemp        ;get the next temporary descriptor address (in BX)
    
    Mov  SI,Str1          ;get the address for the first string
    Mov  AX,[SI]          ;put its length into AX
    Mov  DI,Str2          ;get the address for the second string
    Mov  DX,[DI]          ;put its length into DX

    Mov  CX,AX            ;add the lengths in CX so we'll know what's needed
    Add  CX,DX            ;now CX holds the combined length of the strings
    Jcxz Exit             ;there's nothing to combine, exit
    Inc  CX               ;add two more for a back pointer
    Inc  CX               ;(two Inc's are faster and less code than an Add)

    Call P$TempStr        ;allocate free space, compact memory if necessary
    Push DI               ;save DI for a moment
    Mov  SI,Str1          ;get the address for the first string again
    Mov  SI,[SI+02]       ;in case it moved
    Mov  DI,Str2          ;get the address for the second string again too
    Mov  DI,[DI+02]       ;save its address for a moment
    Mov  SaveAddr,DI
    Pop  DI               ;get DI back again

    Cmp  CX,2             ;is there at least enough for the back pointer?
    Jb   Exit             ;no, get out in a big hurry!
    Mov  [DI],BX          ;create a back pointer for the temporary descriptor
    Sub  P$BytesFree,CX   ;show that much less available in the string pool
    Add  P$BytesUsed,CX   ;and that much more in use

    Dec  CX               ;adjust CX back down to the actual length requested
    Dec  CX
    Inc  DI               ;and bump DI past the back pointer
    Inc  DI
    Mov  [BX],CX          ;assign the current temporary descriptor's length
    Mov  [BX+02],DI       ;and its address portion too

    Push CX               ;save CX while we copy the first string to the pool
    Cmp  AX,CX            ;is the first string longer than what's available?
    Jbe  Len1Okay         ;no, continue
    Mov  AX,CX            ;yes, restrict it to what we actually have

Len1Okay:
    Mov  CX,AX            ;load the number of characters to copy
    Rep  Movsb            ;copy the first string into the P.D.Q. string pool
    Pop  CX               ;and get CX back again
    Sub  CX,AX            ;show that many characters as having been copied

    Cmp  DX,CX            ;is the second string longer than what's available?
    Jbe  Len2Okay         ;no, continue
    Mov  DX,CX            ;yes, restrict it to what we actually have

Len2Okay:
    Mov  CX,DX            ;load the number of characters to copy
    Mov  SI,SaveAddr      ;and retrieve the address to copy from
    Rep  Movsb            ;this completes the concatenation

Exit:
    Mov  AX,BX            ;show BASIC where the output descriptor is
    Push Str1             ;delete these strings if necessary
    Call P$FreeTemp
    Push Str2
    Call P$FreeTemp
    Ret                   ;return to BASIC

B$SCAT Endp
End
