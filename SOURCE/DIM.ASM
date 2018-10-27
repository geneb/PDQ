;********** DIM.ASM - PDQ replacement for BASIC's B$DDIM and B$RDIM routines

;Copyright (c) 1990 Ethan Winer

COMMENT |

This file provides support for both the DIM (dynamic) and REDIM statements.
These are handled identically, in that either causes the array to be erased
if it was active, and then dimensioned.  Where regular BASIC generates an
error if you use DIM on an existing array, P.D.Q. simply treats it as REDIM.

The only "fly in the ointment" in supporting REDIM occurs with dynamic
conventional (not fixed-length) string arrays.  A string array is a table of
four-byte string descriptors, with each descriptor holding the length and
address of the string it represents.  For static string arrays and non-array
strings, the string descriptors are kept in near memory which has been
assigned by the BC compiler.  However, with dynamic string arrays the table
of descriptors is stored by P.D.Q. in the P.D.Q. string pool (defined in the
various STR#####.ASM files).

P.D.Q. string data is assigned beginning at the bottom of the pool, and as
new strings are assigned they are stored in ever higher locations.  When no
more pool memory is available, the compaction routine is called, and the
active strings are moved downward on top of older strings that have since
been deleted.  The table of dynamic string array descriptors is instead
allocated at the top of the string pool, and as new arrays are dimensioned
each added table of descriptors is stored in ever lower addresses.  This way
the normal string compaction process (which can occur frequently) does not
extend into the upper portion of the string pool.  Now let's see why that's
important.

When a dynamic string array is erased, memory that had held the descriptors
must be released back to the string pool for use by other arrays or regular
strings.  (This is, of course, after each of the strings in the array has
been cleared to "".)  Further, active arrays that are lower in memory than
the one being erased must be moved upward to avoid string pool fragmentation
(creating a hole in memory that can never be used).  But a lot of work--and
thus time--is involved whenever a descriptor is moved.

For each string that is pointed to by a descriptor (that is, all strings), an
integer word called a "back pointer" is stored just before the actual string
data.  This assembly language "variable" holds the address of the string's
own descriptor.  It is called a back pointer because it points back to the
original string descriptor.  By knowing the descriptor address for each piece
of string data as it is encountered, the routine that compacts the string
pool (P$Compact, in COMPACT.ASM) can walk through string pool memory, and
find the descriptor that points to each string.  This is necessary because
after each string has been moved, its descriptor must be adjusted to point to
the new address of its string data.

A similar method is used for maintaining the upper portion of the string
pool that comprises the table of descriptors used by dynamic string arrays.
But when a table of string descriptors is moved, all of the back pointers
used by the array's strings must be adjusted to point to the new descriptor
address.  As with regular string compaction, this takes a fair amount of
code to implement, and a corresponding amount of time.  Therefore, the area
in memory used to store the string descriptors used by dynamic arrays is
"cleaned up" only when an array is erased, rather than every time a normal
string pool compaction takes place.  Storing dynamic string array descriptors
at the top of the string pool also lets us keep the code to support ERASE
separate from the regular string pool routines.  This way, that code is not
added to programs that don't need use REDIM or ERASE.

One final note related to REDIM, ERASE, and string descriptors is the use of
an array descriptor.  The term "descriptor" is mentioned frequently in the
comments for these files, and it is important to point out that an array
descriptor is not at all related to a string descriptor.  I have been very
careful to use wording that is clear in these comments, to avoid confusion
over which type of descriptor is being referred to.  An array descriptor is
a table that contains information about the array, and it varies in size
based on the number of dimensions in the array.  A string descriptor is a
four-byte table that holds the length and address for a string, regardless of
whether or not that string is an element in an array.

Added to this file in P.D.Q. version 2.00 is full support for huge dynamic
arrays.  Like regular (less than 64K) numeric, TYPE, and fixed-length string
arrays, huge arrays also use the DOS memory allocation services to claim far
memory outside of the normal 64K DGROUP data area.  Therefore, once this
memory has been claimed for an array, it must be cleared to all zero values
before it is usable by BASIC.

Also see the array descriptor information in the UBOUND.ASM file, as well as
the string pool discussion in ASSIGN$.ASM.

END COMMENT |


.Model Medium, Basic
    Extrn B$ERAS: Proc      ;this is in ERASE.ASM
    Extrn P$TempStr:Proc    ;this is in TEMPSTR.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM
    Extrn B$MUI4:Proc       ;this is in MULTLONG.ASM

.Data?
    Extrn P$StrPool: Byte   ;this is in STR#####.ASM
    ArraySize DW 2 Dup (?)  ;tracks the total number of elements in the array

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
    Mov  ArraySize+2,DX     ;as a long integer (allow >64K elements)       ³
    Pop  DX                 ;retrieve DX                                   ³
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

    Push BX                 ;save BX because B$MUI4 trashes it
    Push ArraySize+2        ;multiply the total number of elements in the
    Push ArraySize          ;  array times
    Mov  AX,[BX+12]         ;  the length of each element
    Cwd
    Push DX
    Push AX
    Call B$MUI4             ;using the existing multiply routine
    Pop  BX                 ;retrieve BX (the array descriptor base address)

    Xor  CX,CX              ;make a zero for repeated use below
    Mov  [BX+06],AX         ;and save the total array size in the descriptor
    Mov  [BX],CX            ;assign the starting data address there too
                            ;(most dynamic arrays start at 0, assume that)

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
                            ;fall into the code below, though we know it will
                            ;  simply pass through
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
