;********** GETCPU.ASM - returns the CPU type as 86, 286, 386, or 486

;Copyright (c) 1989, 1992 Ethan Winer

;This routine is based on an example in the March/April 1989 issue of
;Programmer's Journal, which in turn is based on guidelines from Intel.
;Updated 1-9-92 using code from Rob Hummel's book, "The Processor and
;Coprocessor", published by Ziff-Davis Press.

;Syntax - PRINT "This PC has an 80"; GetCPU%; "CPU in it"


.Model Medium,BASIC
.Code

GetCPU Proc 

    Pushf                 ;save the flags before we trash them
    Pop  AX               ;get the flags into AX
    Push AX               ;and save them again for later
    And  AX,0FFFh         ;clear the high nibble (top four bits)
    Push AX               ;save that on the stack
    Popf                  ;and attempt to pop it into the flag register
    Pushf                 ;save what happened
    Pop  AX               ;and then pop the result into AX

    And  AX,0F000h        ;examine just the high nibble
    Cmp  AX,0F000h        ;did the CPU force the top bits on again?
    Je   CPU86            ;only an 8086/88 does that

    Pop  AX               ;get the original flags again into AX
    Push AX               ;and save 'em for later
    Or   AX,0F000h        ;force the high nibble on
    Push AX               ;move that into the flags
    Popf                  ;through the stack
    Pushf                 ;save it again
    Pop  AX               ;and get it into AX so we can examine it
    And  AX,0F000h        ;are the bits still set?
    Je   CPU286           ;yes, so it must be an 80286

.386                      ;it's either a 386 or 486, determine which
    Mov  ECX,ESP          ;save the current stack pointer
    And  ESP,Not 3        ;align it to a double word
    Pushfd                ;load the extended flags
    Pop  EAX              ;  into EAX

    Mov  EBX,EAX          ;save this so we can test it later
    Xor  EAX,40000h       ;complement the AC bit
    Push EAX              ;and copy it back into the extended flags
    Popfd

    Pushfd                ;copy the flags into EAX
    Pop  EAX
    
    Xor  EAX,EBX          ;did the bit change?
    Mov  ESP,ECX          ;(first restore the full stack pointer)
    Jz   CPU386           ;no, so it must be a 386
    Mov  AX,486           ;yes, return 486
    Push EBX              ;but also restore the AC bit in the extended flags
    Popfd
    Jmp  Short Exit

CPU386:
    Mov  AX,386           ;assign 80286 as the function output
    Jmp  Short Exit

CPU286:
    Mov  AX,286           ;assign 80286 as the function output
    Jmp  Short Exit

CPU86:
    Mov  AX,86            ;it's a plain old 8086/88

Exit:
    Popf                  ;restore the original flags setting
    Ret                   ;and return to BASIC

GetCPU Endp
End
