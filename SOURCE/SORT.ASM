;********** SORT.ASM - sorts all or part of a BASIC string array

;Copyright (c) 1989 Ethan Winer


;Syntax - CALL Sort(BYVAL VARPTR(Array$(Start)), Size, Direction)

;Where Array$(Start) specifies the lowest element in the array to include in
;the sort, Size% is the total number of elements to be sorted, and Direction
;is 0 for ascending (normal), or anything else for descending (backwards).

.Model Medium, Basic
    Extrn B$SWSD:Proc    ;this is in SWAP.ASM

.Data?

    S          DW 1 Dup(?)
    F          DW 1 Dup(?)
    L          DW 1 Dup(?)
    I          DW 1 Dup(?)
    J          DW 1 Dup(?)
    MidPoint   DW 1 Dup(?)

.Code

Sort Proc Uses SI DI, Array:Word, Siz:Word, Dir:Word

    Cld                  ;all fills and compares are forward
    Push DS              ;ensure that ES = DS for string compares below
    Pop  ES
    
    Xor  CX,CX           ;clear CX for comparing and assigning below
    Mov  AX,7376h        ;load AL and AH with the opcodes for "Jae" and "Jbe"
                         ;  in preparation for code self-modification
    Mov  BX,Dir          ;get the sorting direction
    Cmp  [BX],CX         ;is it zero meaning an ascending sort?
    Je   Ascending       ;yes, skip ahead
    Xchg AL,AH           ;no exchange the "Jbe" and "Jae" opcodes

Ascending:
    Mov  CS:[X1],AH      ;install the correct comparison opcodes based on
    Mov  CS:[X2],AL      ;  the sort direction

    Mov  BX,Siz          ;put address of Size% into BX
    Mov  AX,[BX]         ;put value of Size% into AX
    Dec  AX              ;adjust the number of elements to zero-based
    Jns  L0              ;at least 1 element was specified, continue
    Jmp  L4              ;we can't sort 0 (or less!) elements, get out now!

L0:
    Mov  BX,Array        ;save the address of Array$(Start) descriptor in BX
    Mov  S,SP            ;S = 0 (really normalized to current stack pointer)
    Mov  F,CX            ;F = 0
    Mov  L,AX            ;L = Size%

L1:
    ;----- calculate MidPoint

    Mov  DI,L            ;MidPoint = (L + F) \ 2
    Add  DI,F
    Shr  DI,1
    Mov  MidPoint,DI

    Mov  AX,F            ;I = F
    Mov  I,AX

    Mov  AX,L            ;J = L
    Mov  J,AX

L1_9:
    ;----- calculate offset into the descriptor table for Array$(MidPoint)

    Shl  DI,1            ;multiply MidPoint in DI times 4
                         ;  (4 bytes per descriptor) by shifting twice
    Shl  DI,1            ;now DI holds how far beyond Array$(Start)
                         ;  Array$(MidPoint)'s descriptor is
    Add  DI,BX           ;add the array base address to produce the final
                         ;  descriptor address for Array$(MidPoint)

L2:
    ;----- calculate descriptor offset for Array$(I)

    Mov  SI,I            ;put I into SI
    Shl  SI,1            ;as above
    Shl  SI,1            ;now SI holds how far beyond Array$(Start)
                         ;  Array$(I)'s descriptor is
    Add  SI,BX           ;add base to produce the final descriptor address

    ;IF Array$(I) < Array$(MidPoint) THEN I = I + 1: GOTO L2
    Call P$Compare       ;do the compare

X1 Label Byte            ;modify the code below to "Jbe" if descending sort
    Jae  L2_1            ;Array$(I) isn't less, continue on

    Inc  Word Ptr I      ;I = I + 1
    Jmp  Short L2        ;GOTO L2


L2_1:
    ;----- calculate descriptor offset for Array$(J)

    Mov  SI,J            ;put J into SI
    Shl  SI,1            ;as above
    Shl  SI,1            ;now SI holds how far beyond Array$(Start)
                         ;  Array$(J)'s descriptor is
    Add  SI,BX           ;add base to produce the final descriptor address

    ;IF Array$(J) > Array$(MidPoint) THEN J = J - 1: GOTO L2.1
    Call P$Compare       ;do the compare

X2 Label Byte            ;modify the code below to "Jae" if descending sort
    Jbe  L2_2            ;Array$(J) isn't greater, continue on

    Dec  Word Ptr J      ;J = J - 1
    Jmp  Short L2_1      ;GOTO L2.1

L2_2:
    Mov  AX,I            ;IF I > J GOTO L3
    Cmp  AX,J
    Jg   L3              ;J is greater, go directly to L3
    Je   L2_3            ;they're the same, just skip the swap


    ;Swap Array$(I), Array$(J) - must also reassign MidPoint to
    ;                            follow the changes in I and J

    Mov  SI,I            ;put I into SI
    Mov  DI,J            ;put J into DI

    Cmp  SI,MidPoint     ;IF I = MidPoint THEN MidPoint = J
    Jne  No_Mid1         ;not equal, skip ahead
    Mov  MidPoint,DI     ;equal, assign MidPoint = J
    Jmp  Short No_Mid2   ;don't waste time comparing again

No_Mid1:
    Cmp  DI,MidPoint     ;IF J = MidPoint THEN MidPoint = I
    Jne  No_Mid2         ;not equal, skip ahead
    Mov  MidPoint,SI     ;equal, assign MidPoint = I

No_Mid2:
    Mov  SI,I            ;put I into SI
    Shl  SI,1            ;multiply times four for the descriptors
    Shl  SI,1
    Add  SI,BX           ;add the address for the first descriptor

    Mov  DI,J            ;do the same for J in DI
    Shl  DI,1
    Shl  DI,1
    Add  DI,BX

    Call B$SWSD          ;and swap 'em good

L2_3:
    Inc  Word Ptr I      ;I = I + 1
    Dec  Word Ptr J      ;J = J - 1

    Mov  AX,I            ;IF I <= J GOTO L2
    Cmp  AX,J
    Jg   L3              ;it's greater, skip to L3
    Mov  DI,MidPoint     ;get MidPoint again
    Jmp  L1_9            ;go back to just before L2


L3:
    Mov  AX,I            ;IF I < L THEN PUSH I: PUSH L
    Cmp  AX,L
    Jnl  L3_1            ;it's not less, so skip Pushes

    Push I               ;Push I
    Push L               ;Push L

L3_1:
    Mov  AX,J            ;L = J
    Mov  L,AX

    Mov  AX,F            ;IF F < L GOTO L1
    Cmp  AX,L
    Jnl  L3_2            ;it's not less, so jump ahead to L3_2
    Jmp  L1              ;it's less, go to L1

L3_2:
    Cmp  S,SP            ;IF S = 0 GOTO L4
    Je   L4

    Pop  L               ;Pop L
    Pop  F               ;Pop F
    Jmp  L1              ;GOTO L1

L4:
    Ret                  ;return to BASIC

Sort Endp



P$Compare Proc Near Uses SI DI

    Mov  AX,[SI]          ;put the length of the first string into AX
    Mov  SI,[SI+02]       ;and its address into SI

    Mov  DX,[DI]          ;put the length of the second string into DX
    Mov  DI,[DI+02]       ;and its address into DI

    Mov  CX,DX            ;put the length of the second string into CX
    Cmp  AX,DX            ;compare it against the length of the first string
    Ja   Comp1            ;DX was shorter, so CX is already correct
    Mov  CX,AX            ;we guessed wrong, AX is shorter so use it instead

Comp1:
    Repz Cmpsb            ;do the comparison
    Jz   Comp2            ;strings are equal thus far, decide based on length
    Jmp  Short ExitComp   ;they're different so the flags are already correct

Comp2:
    Sub  AX,DX            ;set the flags based on the original lengths

ExitComp:
    Ret                   ;return to Sort

P$Compare Endp
End
