;********* HUGARRAY.ASM - PDQ support for huge (>64K) arrays and /d debugging

;Copyright (c) 1990 Ethan Winer


;This routine is called to obtain the segmented address for an element in a
;huge (/ah) array.  It is also called when the /d debug switch is used with
;BC.EXE, to ensure that the specified element number is valid.  B$HARY is set
;up and called by BASIC as follows:
;
;V% = Array(X, Y, Z)
;
;   Push Word Ptr [X]       ;push the specified subscript values
;   Push Word Ptr [Y]
;   Push Word Ptr [Z]
;   Mov  AX,3               ;there are three subscripts in this array
;   Push AX
;   Mov  BX,Offset Array    ;load BX with the address of the array descriptor
;   Call B$HARY             ;B$HARY returns ES:[BX] pointing at the element
;   Mov  AX,ES:[BX]         ;retrieve the element from the array
;   Mov  V%,AX              ;assign it to V%


.Model Medium, Basic
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM
    
.Data
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    
.Code

B$HAR1 Proc                 ;this is the name BASIC 7 uses for this procedure
B$HAR1 Endp                 ;fall into the code below

B$HARY Proc Uses AX CX DX SI DI, Subscripts:Word

    Mov  CX,Subscripts      ;see how many subscripts there are in this array
    Push CX                 ;(this is also the number of incoming parameters)
    Inc  CX                 ;consider the Subscripts parameter too
    Shl  CX,1               ;times 2 for the Ret n value (2 bytes per param)
    Mov  Word Ptr CS:Patch,CX   ;patch the code for later
    Pop  CX                     ;get the Subscripts parameter back again

    Push BX                 ;save BX/BP while we derive the element's address
    Push BP

    Xor  SI,SI              ;clear SI for walking through the array descriptor
    Mov  DI,SI              ;clear DI too
    Cmp  [BX+02],SI         ;check the starting data segment for the array
    Jz   BadSubscript       ;if it's 0 then the array was never dimensioned!
    
    Add  BP,8               ;point BP at the last incoming subscript (Z above)
    Add  BX,0Eh             ;point BX at the number of elements entry for
                            ;  that subscript in the array descriptor
    Cmp  CL,[BX-0Eh+08]     ;does Subscripts agree with what's in the
    Jz   CalcEl             ;  array descriptor?  skip ahead if they do

BadSubscript:               ;this code is out of the main "line of fire"
;   Add  SP,16              ;clean up BP, BX, the 5 "Uses" registers (and BP)
;   Pop  AX                 ;retrieve the caller's address
;   Pop  DX                 ;and segment too
;   Add  SP,Word Ptr CS:Patch   ;clean up the incoming parameters
;   Push DX                     ;stuff the address back so B$LINA can report
;   Push AX                     ;  where the error occurred
    Mov  P$PDQErr,9         ;force a "Subscript out of range" error
;   Call B$LINA             ;jump into the DEUBG.ASM handler
    Pop  DX                 ;discard BP and BX now on the stack
    Pop  DX
    Mov  SI,0F000h          ;assign a segment of &HF000, so the worst that'll
                            ;  happen is they'll try to overwrite ROM
    Call P$DoError          ;see if ON ERROR is in effect
    Jmp  Short NoSpan       ;and exit if not

NextSubscript:
    Inc  BP                 ;point BP to the previous subscript (Y, then X)
    Inc  BP
    Add  BX,4               ;BX to the number of elements for that subscript
    Mov  AX,DI              ;start AX with what we've accumulated so far
    Mul  Word Ptr [BX]      ;times the number of elements in this subscript
    
    Mov  DI,AX              ;save that in DI
    Mov  AX,SI              ;consider the address portion that exceeds 64K
    Mov  SI,DX              ;and save it in SI
    Mul  Word Ptr [BX]      ;as above
    Add  SI,AX              ;update what we're accumulating in SI

CalcEl:
    Mov  AX,[BP+00]         ;get the incoming subscript value
    Sub  AX,[BX+02]         ;subtract from that the LBOUND for this subscript
    Jl   BadSubscript       ;if we came out negative, the element was illegal
    Cmp  AX,Word Ptr [BX]   ;now check against the total number of elements
    Jge  BadSubscript       ;the element number was illegally large
    Add  DI,AX              ;update the lower 64K in DI
    Adc  SI,0               ;and the excess in DI
    Loop NextSubscript      ;until all subscripts have been considered
    
    Pop  BP                 ;retrieve BP/BX to get at the array descriptor
    Pop  BX
    Mov  AX,DI              ;as above
    Mul  Word Ptr [BX+0Ch]
    Mov  DI,AX
    Mov  AX,SI
    Mov  SI,DX
    
    Mul  Word Ptr [BX+0Ch]
    Add  SI,AX
    Add  DI,[BX]
    Adc  SI,CX              ;(CX is guaranteed to be 0)
    
    Mov  CL,12              ;QB uses a variable, but it seems to always be 12
    Shl  SI,CL              ;compute the final segment value
    Add  SI,[BX+02]

    Test Byte Ptr [BX+09],3 ;is this a far or huge (non-DGROUP) array?
    Jz   NoSpan             ;bits 1 and 2 clear means it's a string, skip

    Or   DI,DI              ;are we dangerously close to a segment boundary?
    Jns  NoSpan             ;no, skip ahead
    And  DI,7FFFh           ;yes, subtract 32K from the address
    Add  SI,800h            ;and fudge the segment to account for that

NoSpan:
    Mov  ES,SI              ;assign the segment for this array element to ES
    Mov  BX,DI              ;and the address to BX

Exit:
    Ret                     ;return with ES:[BX] pointing to the element
    Patch Equ $-2           ;specify the patch point for self-modification

B$HARY Endp
End
