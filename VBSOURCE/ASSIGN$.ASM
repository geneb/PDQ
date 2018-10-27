;********** ASSIGN$.ASM - PDQ replacement for BASIC's B$SASS routine

;Copyright (c) 1989 Ethan Winer
;11/01/92 Thomas G. Hanlin III added far string support
;12/01/92 Thomas G. Hanlin III switched to P$FIXSTR far string call
;  for consistency and ease of maintenance

COMMENT |

This routine handles BASIC's string assignments.

As each string is assigned to the string pool, a back pointer is created that
holds the address of its descriptor.  This is immediately followed by the
actual string data.  Each time a string is assigned to a non-null value, new
memory is allocated and the string's descriptor is set to point to that data.
If the string being assigned was already holding data, then the old data is
abandoned by calling the B$STDL (String Delete) routine.

String data is marked as being free by placing its length into its own back
pointer.  The back pointer is further identified as an "abandoned string
length" by shifting the length word left one position, and then setting its
lowest bit.  Since an odd numbered descriptor address is illegal, this is a
simple yet effective method to mark the data as abandoned, while retaining
its length for later string pool compaction.

When no more string memory is available or when the user asks for FRE(""),
the string compaction routine is called.  Compact walks through the string
pool by examining each back pointer, to see if the associated data is valid
or not.  If it is not valid, Compact continues the search until it finds the
next piece of active string data.  Once found, that data is copied downward
on top of the abandoned data lower in memory, and the descriptor that points
to the data is adjusted accordingly.  This process continues until the entire
active portion of the string pool has been examined and compacted.

B$SASS also calls the P$FreeTemp routine to clear the source string in case
it was a "temporary string".  Temporary strings are created during string
concatenation, as well as by SPACE$, STRING$, and COMMAND$, and the other
BASIC string functions.  These temporary strings must not be freed until
B$SASS gets called to do an assignment.  If a multiple concatenation is in
progress (X$ = A$ + B$ + C$), the temporary results created thus far must be
protected against compaction (also known as garbage collection).

The temporary descriptors are contained in a separate file (TEMPDESC.ASM), so
they can be shared by B$SASS and the other routines that need to access them.
Note that all of the BASIC internal routines that accept an incoming string
argument make a call to P$FreeTemp, just in case that string is temporary.
Therefore, in the example below it is up to OPEN to erase the result of the
concatenation.  Otherwise the combined string [Drive$ + ":"] would forever
occupy string pool memory:

   OPEN Drive$ + ":" + FileName$ FOR OUTPUT AS #1

Beginning with P.D.Q. version 1.30, if the source string is a temporary, then
the source and destination are simply swapped.  This is many times faster
than claiming new memory and then deleting the old string, especially since
many assignments are in fact from a temporary string, ie: X$ = LEFT$(Y$, 10).

END COMMENT |


.Model Medium, Basic
    Extrn P$FixStr  :Proc   ;this is in FIXSTR.ASM
    Extrn B$STDL    :Proc   ;this is in STRDELET.ASM
    Extrn B$SWSD    :Proc   ;this is in SWAP$.ASM
    Extrn P$TempStr :Proc   ;this is in TEMPSTR.ASM

.Data?
    OldDescr DW 1 Dup (?)   ;save the To descriptor address to delete it later

.Data
    Extrn P$BytesFree :Word ;this is in STR#####.ASM
    Extrn P$BytesUsed :Word ;this is in STR#####.ASM
    Extrn P$TempDesc  :Word ;this is in TEMPDESC.ASM

.Code

B$SAS1 Proc                 ;this is the public name BASIC 7.0 uses
    Nop                     ;this forces CodeView to show the correct name
B$SAS1 Endp                 ;fall into the code below


B$SASF Proc                 ;this is another name BASIC 7.0 uses for B$SASS
    Nop
B$SASF Endp                 ;fall into the code below

B$SASS Proc Uses SI DI, FromString:Word, ToString:Word

;-- Get the incoming string addresses, see how many bytes are needed.
;
    Mov  DI,ToString      ;get the address for the destination descriptor
    Mov  OldDescr,DI      ;save the address so we can delete it later

    Push FromString       ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  FromString,AX    ;

    Mov  SI,FromString    ;get the source string descriptor address
    Mov  CX,[SI]          ;see how many bytes we'll be needing
    Jcxz MakeString       ;we're just clearing the string, skip this mess

;-- See if we're assigning from a temporary string.
;
    Mov  BX,Offset P$TempDesc ;get the address for the temporary descriptors
    Cmp  SI,BX                ;is the incoming string below that?
    Jb   NotTemp          ;yes, so we're not coming from a temporary string
    Add  BX,76            ;point to the last temporary descriptor
    Cmp  SI,BX            ;is the incoming string above it?
    Ja   NotTemp          ;yes, so assign the string in the usual manner

;-- We are, swap the strings instead of claiming new space and copying.
;   B$SWSD (swap string descriptors) expects the descriptor addresses in SI
;   and DI, which is already the case.
;
    CALL B$SWSD           ;call the string swap routine
    Push FromString       ;pass the address of the source string to delete it
    CALL B$STDL           ;and call the string delete routine
    Jmp  Short Exit       ;all done

NotTemp:
    Push DI               ;save DI on the stack for a moment
    Inc  CX               ;don't forget we need an extra 2 for a back pointer
    Inc  CX               ;2 Inc's is less code and faster than an Add
    Call P$TempStr        ;request that many bytes from the string pool
    Pop  AX               ;get the incoming string back (was DI when pushed)
    Cmp  CX,2             ;do we have enough for the back pointer at least?
    Jbe  Exit             ;no, so bag out in a big hurry!

;-- Create a back pointer for the new string.
;
    Stosw                 ;assign the back pointer
    Mov  SI,FromString    ;get the source again in case Compact moved it
    Mov  SI,[SI+02]       ;  (guess how long it took to find THAT one!)

;-- Adjust the string pool Free and Used variables.
;
    Sub  P$BytesFree,CX   ;show that much less available in the string pool
    Add  P$BytesUsed,CX   ;and that much more in use
    Dec  CX               ;the string length doesn't include the back pointer
    Dec  CX               ;so adjust it back down before assigning it below

MakeString:
;-- Delete the old string contents and assign the replacement string.
;
    Push OldDescr         ;show B$STDL where the ToString descriptor is
    Call B$STDL           ;delete it just before making the new assignment

    Mov  [BX],CX          ;now assign the destination length
    Mov  [BX+02],DI       ;and its address within the string pool
    Rep  Movsb            ;copy the source string data into the string pool

Exit:
    Ret                   ;return to BASIC
B$SASS Endp
End
