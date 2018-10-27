;********* ENABLEFP.ASM - enables/disables floating point math in a TSR

;Copyright (c) 1991 Ethan Winer

;DO NOT USE THE /E SWITCH WHEN ASSEMBLING THIS FILE


.8087                       ;allow coprocessor instructions
.Model Medium, Basic
    Extrn P$HookFP:Proc     ;these are in P$HOOKFP.ASM
    Extrn P$UnhookFP:Proc   ;  and also in _87ONLY.ASM and _EMONLY.ASM
                            ;  when those files are stubbed in
.Data
    Extrn P$87Used:Byte     ;this is in P$HOOKFP.ASM (and _87ONLY and _EMONLY)
    
    FPEnabled DB 0          ;this remembers if we're enabled or not to
                            ;  prevent a disaster from enabling/disabling
.Code                       ;  when not appropriate

EnableFP Proc

    Cmp  FPEnabled,0        ;are we currently enabled?
    Jne  Exit               ;yes, so get out without doing anything
    Call P$HookFP           ;no, hook the floating point interrupts
    Mov  FPEnabled,-1       ;and show that we are enabled

    Cmp  P$87Used,0         ;is there an 80x87 running?
    Je   Exit               ;no, so we're all done
    FSave CS:Save87         ;yes, save the state of the coprocessor
    FWait                   ;wait for the coprocessor to finish

Exit:
    Ret                     ;return to BASIC

EnableFP Endp



DisableFP Proc

    Cmp  FPEnabled,0        ;are we currently enabled?
    Je   Exit               ;yes, so get out without doing anything
    Call P$UnhookFP         ;no, unhook the floating point interrupts
    Mov  FPEnabled,0        ;show that we are disabled

    Cmp  P$87Used,0         ;is there an 80x87 running?
    Je   Exit               ;no, so we're all done
    Frstor CS:Save87        ;yes, restore the state of the coprocessor
    FWait                   ;and wait for the coprocessor to finish

Exit:
    Ret                     ;return to BASIC

DisableFP Endp

    Save87 DB 108 Dup (?)   ;this holds the entire 80x87 status

End
