;********** ERASE.ASM - PDQ replacement for BASIC's B$ERAS

;Copyright (c) 1989 Ethan Winer

;Please see the comments in the DIM.ASM and COMPACT.ASM source files.


.Model Medium, Basic
    Extrn B$STDL: Proc      ;this is in STRDELET.ASM
    
.Data?
    Extrn P$StrPool  : Byte ;this is in STR#####.ASM

.Data
    Extrn P$BytesUsed: Word ;these are in STR#####.ASM
    Extrn P$BytesFree: Word

.Code

B$ERAS Proc Uses SI DI, Array:Word

    Cld                     ;all string ops forward (this serves for DIM too)
    
    Mov  BX,Array           ;get the array descriptor address
    Mov  CL,[BX+08]         ;get the total number of dimensions in the array
    Xor  CH,CH              ;clear CH so we can use all of CX
    Jcxz LillyPad           ;this array has never been dimensioned, exit

    Mov  AX,1               ;"seed" AX to accumulate the number of elements
    Mov  DI,14              ;get the offset to the last subscript

;-- Calculate the total number of bytes occupied by the array by multiplying
;   the number of elements in each subscript together, and then multiplying
;   that by the length of each element.  Leave the answer in CX.
;
SizeLoop:
    Mul  Word Ptr [BX+DI]   ;consider the number of elements in the subscript
    Add  DI,4               ;point to the next subscript's number of elements
    Loop SizeLoop           ;until all of the subscripts have been considered
    Mul  Word Ptr [BX+12]   ;multiply that times the size of each element
    Mov  CX,AX              ;and now CX holds the total size of the array

;-- Determine the type of array being erased (dynamic, static, string, etc.)
;   and branch to the appropriate code.
;
    Mov  AL,[BX+09]         ;load the features flag
    Test AL,10000000b       ;is it a string array?
    Jnz  String             ;yes, the "String" bit is set

    Test AL,1000000b        ;no, but is it a static array?
    Jnz  Static             ;yes, the "Static" bit is set

;-- Erase a dynamic array in far memory by calling DOS to release the memory
;   belonging to the array's segment.  If the segment is zero, the array was
;   never dimensioned and we can skip the erase code.
;
    Mov  CX,[BX+02]         ;get the segment from the array descriptor
LillyPad:                   ;(this label supports Jcxz earlier in this file)
    Jcxz Exit               ;the array is undefined (Segment = 0), so exit
    
    Mov  ES,CX              ;show DOS where the segment is located
    Mov  AH,49h             ;DOS release memory service
    Int  21h                ;call DOS to do the hard stuff
    Xor  AX,AX              ;make a zero
    Mov  [BX+08],AL         ;clear number of dimensions to show it's erased
    Mov  [BX+02],AX         ;clear the segment too
    Jmp  Short Exit         ;all done, skip over the code below

;-- Erase a static numeric or TYPE array by filling its entire data space
;   with zeros.
;
Static:
    Les  DI,[BX]            ;load the segmented address of the array data
    Xor  AL,AL              ;make a zero
    Rep  Stosb              ;clear the array to all zeros
    Jmp  Short Exit         ;all done, skip over the code below

;-- Erase a static string array by deleting every string.
;
String:
    Shr  CX,1               ;convert number of bytes to number of words
    Shr  CX,1               ;convert number of words to number of descriptors
    Mov  DI,[BX]            ;get the address for the first string descriptor
    Push BX                 ;save BX because B$STDL trashes it

DeleteLoop:
    Push DI                 ;show B$STDL where this string descriptor is
    Call B$STDL             ;delete this string
    Add  DI,4               ;point to the next string
    Loop DeleteLoop         ;loop until done

;-- See if we just erased a static or dynamic string array.
;
    Pop  BX                        ;retrieve the array descriptor address
    Test Byte Ptr [BX+09],1000000b ;are we erasing a static array?
    Jnz  Exit                      ;yes, so we're all done

;-- Clear the "number of dimensions" portion of this array's array descriptor
;   to show that the array has been erased.  Then compact the descriptors at
;   the top of the string pool.  Begin with the current array that was just
;   erased, and work downward until we hit the bottom of the most recently-
;   dimensioned table of string descriptors.
;
    Mov  [BX+08],CL         ;clear number of dimensions to show it's erased
    Mov  CX,[BX+06]         ;get the total size (in bytes) to free
    Inc  CX                 ;consider the bytes in this array's back pointer
    Inc  CX
    Mov  SI,DI              ;copy it to SI for walking through the pool
    Sub  SI,CX              ;now SI points to the next lower back pointer

;-- Find where the dynamic array string descriptors begin in the string pool.
;
    Mov  DX,Offset P$StrPool;start at the bottom of the string pool
    Add  DX,P$BytesUsed     ;now DX points to the top of all active strings
    Add  DX,P$BytesFree     ;and now it points to the first string descriptor
    Add  P$BytesFree,CX     ;show the top of the pool being that much higher
    Mov  BP,CX              ;make a copy to adjust each string's back pointer
    
    Std                     ;walk backwards through the string pool
    Push DS                 ;assign ES=DS for the Stosw operations below
    Pop  ES
    
PackIt:
    Cmp  SI,DX              ;have we hit the bottom?
    Jbe  Exit               ;yes, so we're all done
    Lodsw                   ;no, get this array's back pointer
    Mov  BX,AX              ;copy it to BX for accessing the array descriptor
    Stosw                   ;place the back pointer in its new home
    
    Add  [BX],BP            ;this block of descriptors starts BP bytes higher
    Add  [BX+10],BP         ;ditto for the array's Adjusted Offset value
    Mov  CX,[BX+06]         ;put the size of this block of descriptors in CX
    Shr  CX,1               ;divide by four to get the number of descriptors
    Shr  CX,1
    
SlideEm:
    Lodsw                   ;get this string's data address
    Mov  BX,AX              ;transfer it to BX for accessing the back pointer
    Stosw                   ;copy the length word to the new location
    Lodsw                   ;now get the string's length
    Stosw                   ;and copy that as well
    
    Or   AX,AX              ;is it a null string?
    Jz   SkipNull           ;yes, so there's no back pointer to deal with
    Add  [BX-02],BP         ;no, adjust the back pointer to point to the new
                            ;  descriptor address
SkipNull:
    Loop SlideEm            ;loop until all of the descriptors are moved
    Jmp  Short PackIt       ;loop until all of the active arrays are moved
    
Exit:
    Cld                     ;force the direction flag to forward
    Ret                     ;return to caller

B$ERAS Endp
End
