;******** _DIM.ASM - DIM stub allows only up to 64K elements

;Copyright (c) 1990 Ethan Winer

;Although BASIC allows only 32,767 elements in a single dimension, it is
;possible to have more elements than that by using a multi-dimensioned array.
;The default P.D.Q. DIM statement accommodates this, but at the expense of
;added code.  This file trades reduced code size (about 100 bytes) for a
;limit of 65,535 total elements in an array.
;
;Please see the comments in DIM.ASM for more information about how dynamic
;arrays are dimensioned.


.Model Medium, Basic
    Extrn B$ERAS: Proc      ;this is in ERASE.ASM
    Extrn P$TempStr:Proc    ;this is in TEMPSTR.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

.Data?
    Extrn P$StrPool: Byte   ;this is in STR#####.ASM
    ArraySize DW 1 Dup (?)  ;tracks the total number of elements in the array

.Data
    Extrn P$PDQErr: Word    ;this is in ERRDATA.ASM
    Extrn P$BytesUsed: Word ;this is in STR#####.ASM
    Extrn P$BytesFree: Word ;this is in STR#####.ASM

.Code

B$DDIM Proc                 ;this is the DIM (for dynamic arrays) entry point
B$DDIM Endp                 ;in P.D.Q. it is the same as REDIM below
                            ;that is, DIM (dynamic) is the same as REDIM
                            ;no error is created if the array already exists

B$RDIM Proc Uses DI SI, LBound:Word, UBound:Word, ElSize:Word, Features:Word, Array:Word

    Push Array              ;show ERASE where the array descriptor is located
    Call B$ERAS             ;erase the array if necessary
    Mov  ArraySize,1        ;seed the array size accumulator with a 1

;-- Copy the incoming array features and element size to the array descriptor.
;
    Mov  BX,Array           ;get the array descriptor address 
    Mov  CX,Features        ;and the features (number of dimensions and type)
    Mov  [BX+08],CX         ;save the features in the array descriptor
    Mov  AX,ElSize          ;get the length (in bytes) of each element
    Mov  [BX+12],AX         ;and save that in the descriptor too

;-- Self-modify the code to accommodate a varying number of passed parameters
;
    Xor  CH,CH              ;consider just the number of dimensions now in CL
    Push CX                 ;save CX for a moment
    Shl  CL,1               ;two parameters (LBOUND and UBOUND) per dimension
    Add  CL,3               ;include the three other mandatory parameters
    Shl  CL,1               ;times 2 to derive the "Ret n" count
    Mov  Word Ptr CS:Patch,CX   ;patch the Ret instruction for the correct
    Pop  CX                     ;  number of incoming parameters

;-- Accumulate the total number of elements in the array, calculate the
;   Adjusted Offset value, and assign the LBOUND and "Number of elements"
;   entries to the array descriptor.
;
    Lea  SI,UBound          ;point to the "last" incoming UBOUND parameter
    Push BX                 ;save the descriptor address for a moment ÄÄÄÄÄ¿
    Xor  DX,DX              ;clear DX for accumulating the Adjusted Offset ³
    Mov  P$PDQErr,DX        ;clear P$PDQErr too while there's a zero handy ³
                            ;                                              ³
BoundsLoop:                 ;                                              ³
    Lodsw                   ;load the UBOUND value for the current subscript
    Sub  AX,[SI]            ;subtract from that the current LBOUND value   ³
    Inc  AX                 ;add 1 because NumElements = UBOUND - LBOUND + 1
    Mov  [BX+14],AX         ;save the number of elements in the descriptor ³
                            ;                                              ³
    Push AX                 ;save the number of elements for a moment      ³
    Mul  DX                 ;accumulate the Adjusted Offset value          ³
    Mov  DX,AX              ;save it in DX as we go                        ³
    Pop  AX                 ;retrieve the number of elements in this subscript
                            ;                                              ³
    Push DX                 ;save DX while we multiply                     ³
    Mul  ArraySize          ;accumulate the total elements by multiplying  ³
    Mov  ArraySize,AX       ;resave the accumulated information            ³
    Or   DX,DX              ;did we overflow 64K elements?                 ³
    Pop  DX                 ;retrieve DX to balance the stack              ³
    Pop  AX                 ;balance the stack again just in case          ³
    Jnz  BadSubscript       ;yes, exit with a "Subscript out of range" error
    Push AX                 ;no, re-balance the stack                      ³
                            ;                                              ³
    Lodsw                   ;load the LBOUND value for the current subscript
    Mov  [BX+16],AX         ;store that in the array descriptor            ³
    Sub  DX,AX              ;adjust the Adjusted Offset accordingly        ³
    Add  BX,4               ;point to the next bounds entry in the descriptor
    Loop BoundsLoop         ;until all of the dimensions are accounted for ³
                            ;                                              ³
    Pop  BX                 ;retrieve the base address of the descriptor ÄÄÙ
    Mov  AX,DX              ;copy the Adjusted Offset derived thus far to AX
    Mul  Word Ptr [BX+12]   ;multiply times the size (bytes) of each element
    Mov  [BX+10],AX         ;this is the final Adjusted Offset, store it
                            ;  in the array descriptor
    Mov  AX,ArraySize       ;get the total number of elements in the array
    Mul  Word Ptr [BX+12]   ;multiply that times the size of each element
    Mov  [BX+06],AX         ;save the total array size in the descriptor
    Mov  [BX],CX            ;assign the starting data address there too
                            ;  (most dynamic arrays start at 0, CX is now 0)

;-- See if this array exceeds 64K, and ensure that /ah was used if it does.
;   The multiplication above will assign any excess beyond 64K to DX.  Also,
;   fixed-length and TYPE arrays whose element length is not a power of two
;   and whose size exceeds 64K must have the starting address fudged so that
;   an element will not be split at the first 64K boundary.  Derive the fudge
;   value by calculating 64K MOD ElementSize if needed.  Data whose length is
;   in fact a power of two will simply result in a fudge value of zero.
;
    Or   DX,DX              ;is this array in fact greater than 64K in size?
    Jz   Not64K             ;no, skip ahead
    Test Byte Ptr [BX+09],2     ;it does exceed 64K, but is /ah in effect?
    Jnz  HugeOkay               ;yes, the "Huge" bit is indeed set

BadSubscript:
    Mov  Byte Ptr P$PDQErr,9    ;no, assign a "Subscript out of range" error
    Jmp  ErrExit                ;and exit now

HugeOkay:
    Push DX                 ;save DX/AX while we calculate the start fudge
    Push AX
    Xor  AX,AX              ;create the value 65536 in DX:AX
    Mov  DX,AX
    Inc  DX                 ;now divide this by the length of each element
    Div  Word Ptr ElSize    ;the start offset fudge is in DX (64K MOD ElSize)
    Mov  [BX],DX            ;use this as the starting data memory address
    Add  [BX+10],DX         ;and fudge the Adjusted Offset too
    
    Pop  AX                 ;retrieve AX and DX again
    Pop  DX
    Add  AX,[BX]            ;include the Fudge count in the memory request
    Adc  DX,CX              ;now DX:AX holds the total number of bytes needed
                            ;  (CX is still zero) - fall into the code below,
                            ;  though we know it will simply pass through
Not64K:
    Test Byte Ptr [BX+09],2 ;is this an /ah array?
    Jz   TestAlloc          ;no, but see if it's a string or other array

    Mov  CL,16              ;yes, divide DX:AX by 16 to get a paragraph count
    Div  CX                 ;now AX holds the number of 16-byte paragraphs
    Inc  AX                 ;bump one more in case it's an odd-length TYPE
    Mov  [BX+06],AX         ;save the paragraph count in the array descriptor
    Push BX                 ;save BX before we trash it; DoAlloc pops it off
    Mov  BX,AX              ;DOS expects the requested paragraph count in BX
    Jmp  Short DoAlloc      ;jump into the DOS allocation part of this proc.

TestAlloc:
    Test Byte Ptr [BX+09],3 ;is this a far or huge (non-DGROUP) array?
    Jnz  FarAlloc           ;if bits 1 or 2 are set it is, go grab far memory

;-- Dimension a dynamic conventional (not fixed-length) string array.
;
    Inc  AX                 ;add two more bytes to include the back-pointer
    Inc  AX
    Mov  CX,AX              ;P$TempStr wants the number of bytes needed in CX
    Call P$TempStr          ;request CX bytes (P$TempStr also sets ES to DS,
                            ;  points DI to the next available string pool
                            ;  address, and clears the direction flag)
    Cmp  CX,AX              ;were there enough bytes available?
    Jne  ErrExit            ;no, and P$TempStr already set the ERR variable
                            ;  to 14 ("Out of string space"), so simply exit
    Add  DI,P$BytesFree     ;now DI points to the current top of the pool
    Mov  [DI-02],BX         ;create the back-pointer at the top of this block
    Sub  DI,AX              ;now DI points to where the array will start
    Sub  P$BytesFree,AX     ;show that many fewer bytes available (notice
                            ;  we're not increasing BytesUsed on purpose)
    Mov  [BX],DI            ;assign the first address to the array descriptor
    Mov  [BX+02],DS         ;and the segment for the array too (always DS)
    Add  [BX+10],DI         ;tweak the Adjusted Offset to the start address
    
    Xor  AL,AL              ;make a zero
    Dec  CX                 ;we don't want to overwrite the back pointer
    Dec  CX
    Rep  Stosb              ;clear the new descriptors to null values
    Jmp  Short Exit         ;all done, skip over the dynamic allocation

;-- Allocate far DOS memory for the array.  DOS expects a paragraph count in
;   BX, so convert the byte count to paragraphs.  Bump one extra for safety
;   to account for the odd-bytes that may have rolled off the right.  That
;   is, 17 bytes needs (17 \ 16) + 1 paragraphs.
;
FarAlloc:
    Push BX                 ;save the array descriptor address for a moment
    Mov  BX,AX              ;transfer the number of bytes needed to BX
    Mov  CL,4               ;divide by 16 to derive the number of paragraphs
    Shr  BX,CL              ;now BX holds the memory needs in terms DOS knows
    Inc  BX                 ;bump one additional to account for Bytes MOD 16

DoAlloc:
    Mov  AH,48h             ;DOS allocate memory service
    Int  21h                ;call DOS to do the hard stuff
    Pop  BX                 ;retrieve the descriptor address
    Jnc  GoodAlloc          ;no carry, no error
    Mov  Byte Ptr P$PDQErr,7;assign an "Out of memory" error
    Jmp  Short ErrExit      ;and exit now without zeroing out any memory

;-- Memory allocation was successful.  Store the segment DOS returned in the
;   array descriptor, and initialize the memory by filling it with zeros.
;
GoodAlloc:
    Mov  [BX+02],AX         ;fill in the segment where the array will reside
    Mov  CX,[BX+06]         ;load CX with the total size of the array
    Mov  ES,AX              ;prepare to zero-out the array memory
    Xor  AX,AX              ;make a zero
    Mov  DI,AX              ;this is also our starting address

    Test Byte Ptr [BX+09],2 ;is this array /ah with a paragraph size in CX?
    Jz   ClearBytes         ;no, CX holds the number of bytes, go clear it
    
ClearHuge:                  ;yes, CX holds the number of 16-byte paragraphs
    Push CX                 ;save the current paragraph count now in CX
    Mov  CX,8               ;clear another 16 bytes of memory (using words)
    Or   DI,DI              ;are we about to span a 32K boundary?
    Jns  NoSpan             ;no, continue

    And  DI,7FFFh           ;yes, subtract 32K from the address in DI
    Mov  DX,ES              ;and add 800h to the segment in ES to compensate
    Add  DX,800h            ;by copying through DX
    Mov  ES,DX              ;(wouldn't segment math capability be wonderful?)

NoSpan:
    Rep  Stosw              ;clear 16 bytes (8 words) at a time
    Pop  CX                 ;retrieve the loop counter
    Loop ClearHuge          ;continue until exhausted
    Jmp  Short Exit         ;and we're all done

ClearBytes:
    Rep  Stosb              ;clear the memory (<=64K) to all zeros
    Jmp  Short Exit         ;skip over the error handling

ErrExit:
    Call P$DoError          ;handle ON ERROR if necessary

Exit:
    Ret                     ;return to BASIC
    Patch Equ $-2           ;this lets us self-modify the code

B$RDIM Endp
End
