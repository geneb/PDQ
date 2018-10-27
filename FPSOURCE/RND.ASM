;********* RND.ASM - P.D.Q. replacement for BASIC's B$RND0 and B$RND1

;Copyright (c) 1991 Ethan Winer

;NOTE: Assemble this file with the /e math emulator switch.


.8087
.Model Medium, Basic
    Extrn PDQRand:Proc          ;this is in PDQRAND.ASM

.Data?
    Output  DD 1 Dup (?)        ;this is where the final output value will go
    RandRet DW 1 Dup (?)        ;we'll store PDQRand's returned value here

.Data
    RandArg DW 32767            ;this is the high limit argument to PDQRand
    Divisor DD 32767.0          ;and this is what we divide the return by
    
.Code

B$RND1 Proc, Dummy:Word         ;ignore the argument and always return the
    Call Far Ptr B$RND0         ;  next random number in sequence
    Ret
B$RND1 Endp



B$RND0 Proc

    Mov  AX,Offset RandArg      ;get the address for RandArg
    Push AX                     ;pass it to PDQRand
    Call PDQRand                ;this returns a random integer number in AX
    Mov  RandRet,AX             ;save it here for FILD below
    
    FILD Word Ptr RandRet       ;load the random number PDQRand returned
    FDIV DWord Ptr Divisor      ;divide the number by 32767.0
    FSTP DWord Ptr Output       ;assign the result to local storage
    FWAIT                       ;wait until the 8087 is finished

    Mov  AX,Offset Output       ;show the caller where the output is
    Ret                         ;return to BASIC
    
B$RND0 Endp
End
