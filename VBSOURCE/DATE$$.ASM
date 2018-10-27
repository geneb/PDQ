;********** DATE$$.ASM - PDQ replacement for BASIC's B$SDAT routine

;Copyright (c) 1989 Crescent Software
;written by Paul Passarelli
; 11/3/92  Thomas G. Hanlin III   added far string support


;This routine provides the statement form of DATE$.


.Model Medium, BASIC
    Extrn P$FixStr:Proc      ;this is in FIXSTR.ASM
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM

.Code

B$SDAT Proc Uses SI DI, NewDate:Word

    Push NewDate          ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  NewDate,AX       ;

    Mov  SI,NewDate       ;get the address of the incoming descriptor
    Mov  BX,[SI]          ;get the length of the string
    Mov  SI,[SI+02]       ;have SI point to the actual string data

    Cld                   ;ensure forward string operations
    Call Smdy             ;do the Months
    Mov  DH,AL            ;place them where DOS expects it

    Call Smdy             ;do the Days
    Mov  DL,AL            ;position for DOS

    Mov  CX,1900          ;set a practical minimum
    Cmp  BL,2             ;how many year digits
    Je   Cent20th         ;"6-14-89" I'd jump on this too.
    Call Smdy             ;get the century
    Dec  SI               ;no delimiter here
    Cmp  AL,19            ;this one or the next
    Jna  Cent20th         ;handle as "19xx"
    Add  CX,100           ;bump it up to "20xx"--what's a film company to do?

Cent20th:
    Call Smdy             ;finally get the decade and year
    Add  CX,AX            ;DOS wants em' all

Function43:
    Mov  AH,43            ;where CX holds the years, DL holds the day, and
                          ;  DH holds the month
    Int  21h              ;set the time via DOS

    Push NewDate          ;delete the incoming string if it was a temporary
    Call P$FreeTemp
    Ret                   ;return to BASIC

B$SDAT EndP



Smdy Proc Near

    Lodsw                 ;grab the first 2 characters of the string
    Sub  AX,3030h         ;normalize them to unpacked BCD digits
    Cmp  AH,10            ;see if we grabbed a delimiter
    Jb   Standard         ;no delimiter, do it the normal way (below)
    Mov  AH,0             ;yes, zap the dash or slash
    Sub  BL,2             ;mark only 2 characters as read (digit & delimiter)
    Ret                   ;leave the procedure

Standard:                 ;it was properly formatted
    Inc  SI               ;bump past the colon
    Xchg AH,AL            ;put the digits in their proper order
    Aad                   ;compress them to binary format
    Sub  BL,3             ;show 3 characters as read (2 digits and delimiter)
    Ret                   ;return to the caller

Smdy Endp
End
