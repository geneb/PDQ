;********** _NOFIELD.ASM - stub excludes support for FIELD, saves 50 bytes

.Model Medium, Basic
.Code

P$CloseField Proc           ;an empty proc with nothing but a Ret statement
    Ret                     ;the routine this stubs out is in FIELD2.ASM
P$CloseField Endp
End
