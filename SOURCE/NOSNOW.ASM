;********* NOSNOW.ASM - controls CGA "snow suppression" in PDQPrint/PDQCPrint

;Copyright (c) 1990 Ethan Winer


;Syntax: CALL NoSnow(SnowFlag)
;
;where SnowFlag = 0 to disable snow suppression and produce very fast CGA
;printing, or non-zero to enable/reenable snow suppression.


.Model Medium, Basic
    Extrn P$MonSetup:Proc   ;this is in MONSETUP.ASM

.Data
    Extrn P$CGAPort:Word    ;this is in MONSETUP.ASM

.Code

NoSnow Proc, SnowFlag:Word

    Call P$MonSetup         ;ensure that P$CGAPort won't be overwritten later

    Xor  AX,AX              ;make a zero quickly
    Mov  BX,SnowFlag        ;get the address for SnowFlag
    Cmp  [BX],AX            ;is it 0 to disable snow suppression?
    Je   Enable             ;yes, assign the zero to P$CGAPort
    Mov  AX,3DAh            ;no, enable it using the CGA port address

Enable:
    Mov  P$CGAPort,AX       ;assign the value as appropriate
    Ret                     ;return to BASIC

NoSnow Endp
End
