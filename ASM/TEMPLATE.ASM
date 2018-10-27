;********** TEMPLATE.ASM - start with this template to create a new program

;Copyright (c) 1990 Ethan Winer


.Model Medium               ;all P.D.Q. programs are medium model

Public Main                 ;make the Main public (must use the name Main)
Include MACROS.ASM          ;this holds the macro definitions

Extrn B$CEND: Proc          ;this is called by the Quit macro
    ;Your other Extrn procedure declarations go here.
    

.Data?
    ;Your uninitialized data goes here, be sure to always use xx Dup (?).

.Data
    ;Your initialized data goes here.

.Code

Main Proc                   ;you must use the name MAIN

    ;Your code goes here.
    Quit                    ;this ends the program

Main Endp
End
