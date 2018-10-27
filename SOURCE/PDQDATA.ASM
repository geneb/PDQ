;********* PDQDATA.ASM - common PDQ data area

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn P$UnhookFP:Proc   ;this is in P$UNHOOKFP.ASM, but it can be stubbed
                            ;  out by linking with _NOVAL.OBJ.

    Public B$Seg            ;so DEF SEG, PEEK, BLOAD, etc. can find it
    Public __PSP            ;for compatibility with other MS languages
    Public P$PSPSeg         ;so COMMAND$ can find the Program Segment Prefix
    Public P$DOSVer         ;so anyone can access the DOS version
    Public P$TermCode       ;so ExitLevel can set it
    Public P$DirtyFlag      ;so Compact only cleans up when it has to
    Public _SPSave          ;save the stack pointer for TSR & ON EROR support
    Public _Resident        ;non-zero if current copy of program is resident
    Public _Swapper         ;indicates if the stack has been swapped in a TSR
    Public P$ExitAdr        ;this allows chaining "On Exit" routines

    Public B$DevUsed        ;this satisfies BC, not used by P.D.Q.
    Public B$EvtFlg         ;this satisfies BASIC 7, not used by P.D.Q.
    Public B$MpsBps         ;this satisfies BASIC 7, not used by P.D.Q.

.Data
    P$TermCode  DB 0        ;default to DOS ERRORLEVEL of zero
    Even                    ;force all of the following on a word boundary
    B$Seg       DW 1 Dup(?) ;the current DEF SEG setting
    __PSP Label Word        ;this is what Microsoft calls the PSP
    P$PSPSeg    DW 1 Dup(?) ;assigned at startup in PDQ.ASM
    P$DOSVer    DW 1 Dup(?) ;also assigned at startup

    P$DirtyFlag DW 0        ;default to no compaction necessary
    _SPSave     DW 0        ;this holds SP at program entry
    _Resident   DW 0        ;default to TSR not resident
    _Swapper    DW 0        ;default to TSR not swapped
    P$ExitAdr   DW Offset P$UnhookFP, Seg P$UnhookFP

    B$DevUsed   Label Word  ;this satisfies a BC.EXE Extrn directive
    B$EvtFlg    Label Word  ;this satisfies BASIC 7
    B$MpsBps    Label Word  ;this is for BASIC 7 too

End
