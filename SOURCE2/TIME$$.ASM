;********** TIME$$.ASM - PDQ replacement for BASIC's B$STIM routine

;Copyright (c) 1989 Crescent Software
;written by Paul Passarelli


;This routine handles the statement form of TIME$.


.Model Medium, BASIC
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM
    
.Code

B$STIM Proc Uses SI DI, NewTime:Word

    Mov  SI,NewTime       ;get the pointer to the incoming descriptor
    Mov  BX,[SI]          ;get the length of the string
    Mov  SI,[SI+02]       ;have SI point to the actual string data

    Cld                   ;ensure forward string operations
    Call Shms             ;do the hours
    Mov  CH,AL            ;place them where DOS expects it

    Call Shms             ;do the minutes
    Mov  Cl,AL            ;position for DOS

    Xor  DX,DX            ;clear seconds just in case
    Or   BL,BL            ;see if there are any seconds
    Jle  Function45       ;no, set the clock
    Call Shms             ;yes, do the seconds
    Mov  DH,AL            ;DOS wants em' all

Function45:
    Mov AH,45             ;where CH holds the hours, CL holds the minutes,
                          ;and DH holds the seconds, DL set to 0 hundredths
    Int 21h               ;set the time
    Push NewTime          ;delete the incoming string if necessary
    Call P$FreeTemp
    Ret                   ;were done, return to BASIC

B$STIM EndP



Shms Proc Near

    Lodsw                 ;grab the first 2 characters of the string
    Sub  AX,3030h         ;normalize them to unpacked BCD digits
    Cmp  AH,10            ;see if we grabed a delimiter
    Jb   Standard         ;no delimiter, do it the normal way (below)
    Mov  AH,0             ;yes, zap the colon
    Sub  BL,2             ;mark only 2 characters as read (digit & delimiter)
    Ret                   ;leave the procedure

Standard:                 ;it was properly formatted
    Inc  SI               ;bump past the colon
    Xchg AH,AL            ;put the digits in their proper order
    Aad                   ;compress them to binary format
    Sub  BL,3             ;show 3 characters as read (2 digits and delimiter)
    Ret                   ;return to the caller

Shms Endp
End
