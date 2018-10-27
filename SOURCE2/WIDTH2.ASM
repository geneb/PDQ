;********* WIDTH2.ASM - PDQ dummy for BASIC's B$DWID and B$FWID routines

;Copyright (c) 1989 Ethan Winer


;These routines do absolutely nothing, except satisfy LINK when you use the
;WIDTH (device) or WIDTH (filenumber) statements.  Because P.D.Q. doesn't add
;that annoying carriage return and line feed every 80 characters like BASIC
;does, using WIDTH xxx, 255 is not necessary.  B$DWID is for devices such as
;[WIDTH "LPT1:", 255], and B$FWID is for files as in [WIDTH #1, 255].

.Model Medium, Basic
.Code

B$DWID Proc ;, Device:Word, Wide:Word
B$DWID Endp                 ;fall into the code below


B$FWID Proc ;, FileNum:Word, Wide:Word
    Retf 4                  ;return to BASIC, pop the device and WIDTH args
B$FWID Endp


B$LWID Proc ;, Device:Word, Wide:Word
    Retf 2                  ;return to BASIC, pop the WIDTH argument
B$LWID Endp


End
