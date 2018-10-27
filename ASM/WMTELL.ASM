;********** WMTELL.ASM

;Assemble and link as follows (it's too small to use link's /ex switch!):
;
;   MASM wmtell ;
;   LINK /noe/far/packc wmtell startup, , nul , pdq ;
;   EXE2COM wmtell


.Model Medium               ;all P.D.Q. programs are medium model
Public Main                 ;make the main public (must use the name Main)

    Extrn B$CEND:Proc       ;ends the program, in STARTUP.ASM
    Extrn B$ASSN:Proc       ;assigns strings, in ASSIGN.ASM
    Extrn B$SPLY:Proc       ;plays a tune, in PLAY.ASM
    Extrn PDQInkey:Proc     ;fetches a keystroke, in PDQINKEY.ASM

Include MACROS.ASM          ;defines some useful assembly language macros
NumLines Equ 100            ;there's 100 lines of tune

.Data
    String DW 2 Dup (0)     ;copy each DATA string here before playing
    
.Code

Main Proc

    Mov  CX,NumLines            ;do this NumLines times
    Mov  DI,Offset CS:[Tune]    ;point to the first line in the code segment

Do:
    Call PDQInkey           ;bail out if Escape is pressed
    Cmp  AL,27              ;well, was it pressed?
    Je   Exit               ;yes, go end
    Push CX                 ;no, save the line count for a moment
    Mov  DX,DI              ;and save the starting address for this string
    
    Push CS                 ;scan the strings which are in the code segment
    Pop  ES
    Mov  CX,65535           ;this helps us calculate the string length later
    Mov  AL,0               ;search for a zero byte
    Repne Scasb             ;go find it
    Not  CX                 ;convert to a positive number
    Dec  CX                 ;exclude the zero byte, now CX holds the length

    Push CS                 ;pass the source segment
    Push DX                 ;and the source address
    Push CX                 ;and the source length
    Push DS                 ;pass the destination segment
    Mov  AX,Offset String   ;and the destination descriptor address
    Push AX
    Sub  AX,AX              ;a zero means we're assigning to a regular string
    Push AX
    Call B$ASSN             ;copy the current line to the String variable

    Mov  AX,Offset String   ;now play the line
    Push AX
    Call B$SPLY

    Pop  CX                 ;retrieve the line counter
    Loop Do                 ;and go again

Exit:
    Call B$CEND

Main Endp

Tune:

DB "l16t155", 0
DB "o2mnb4p8msbbmnb4p8msbbb8g#8", 0
DB "e8g#8b8g#8b8o3e8o2b8g#8e8g#8", 0
DB "b8g#8b8o3e8o2mnb4p8msbbmnb4", 0
DB "p8msbbmnb4p8msbbmnb4p8msbb", 0
DB "b8bbb8b8b8bbb8b8b8bb", 0
DB "b8b8b8bbb8b8mlb2b2b8p8p4p4", 0
DB "p8mso1bbb8bbb8bbo2e8f#8g#8o1bb", 0
DB "b8bbo2e8g#g#f#8d#8o1b8bbb8bb", 0
DB "b8bbo2e8f#8g#8eg#mlb4bmsag#f#", 0
DB "e8g#8e8o3bbb8bbb8bbo4e8f#8", 0
DB "g#8o3bbb8bbo4e8g#g#f#8d#8o3b8bb", 0
DB "b8bbb8bbo4e8f#8g#8mleg#b4", 0
DB "bag#f#mse8g#8e8o3g#g#g#8g#g#g#8g#g#", 0
DB "g#8o4c#8o3g#8o4c#8o3g#8o4c#8o3g#8f#8e8d#8", 0
DB "c#8g#g#g#8g#g#g#8g#g#g#8o4c#8o3g#8o4c#8", 0
DB "o3g#8o4c#8o3b8a#8b8a#8b8g#g#g#8g#g#", 0
DB "g#8g#g#g#8o4c#8o3g#8o4c#8o3g#8o4c#8o3g#8f#8", 0
DB "e8d#8c#8g#g#g#8g#g#g#8g#g#g#8o4c#8", 0
DB "o3g#8o4c#8o3g#8o4c#8o3b8a#8b8o2bbb8f#f#", 0
DB "f#8f#f#f#8g#8a8f#4mna8msg#8mne4", 0
DB "msg#8f#8f#8f#8o3f#f#f#8f#f#f#8g#8", 0
DB "a8mnf#4msa8g#8mne4msg#8f#8o2bb", 0
DB "b8o1bbb8bbb8bbo2mne8f#8g#8o1bb", 0
DB "b8bbo2e8g#g#f#8d#8o1b8bbb8bb", 0
DB "b8bbo2e8f#8g#8eg#mlb4mnbag#f#", 0
DB "e8g#8e8o3bbb8bbb8bbo4e8f#8", 0
DB "g#8o3bbb8bbo4e8g#g#f#8d#8o3b8bb", 0
DB "b8bbb8bbo4e8f#8g#8mleg#mlb4", 0
DB "mnbag#f#mne8g#8e8o3mle56f56g56a56b56o4c56d56mne8eee8e8mlg#4g#8", 0
DB "mnf#8e8d#8e8c#8mso3bo4c#o3bo4c#o3b", 0
DB "o4c#d#eo3abababo4c#d#o3g#ag#ag#abo4c#o3f#", 0
DB "g#f#g#f#g#f#g#f#g#f#d#o2bo3mlbo4c#d#e8d#8e8", 0
DB "c#8o3msbo4c#o3bo4c#o3bo4c#d#eo3abababo4c#d#o3g#", 0
DB "ag#ag#abo4c#o3f#g#f#g#f#af#emne8p8mlc#4", 0
DB "mnc#o2cmso3c#o2co3d#c#o2baag#ec#c#c#c#c#e", 0
DB "d#o1cg#g#g#g#g#g#o2c#eg#o3c#c#c#c#c#o2co3c#o2co3d#", 0
DB "c#o2baag#ec#c#c#c#c#ed#o1cg#g#g#g#g#mng#", 0
DB "o2c#eg#o3msc#ed#c#d#o2cg#g#g#o3g#ec#d#o2cg#g#g#", 0
DB "o3g#ec#d#o2bg#g#a#gd#d#g#gg#gg#ag#f#e", 0
DB "o1ba#bo2eo1bo2f#o1bo2g#ed#eg#eaf#bo3g#f#ed#", 0
DB "f#ec#o2bo3c#o2bo3c#d#ef#g#o2ababo3c#d#ef#o2g#", 0
DB "ag#aco3c#d#eo2f#g#f#g#f#g#f#g#f#g#f#d#o1b", 0
DB "co2c#d#eo1ba#bo2eo1bo2f#o1bo2g#ed#eg#eaf#b", 0
DB "o3g#f#ed#f#ec#o2bo3c#o2bo3c#d#ef#g#o2ababo3c#", 0
DB "d#ef#o2g#ag#abo3c#d#eo2f#o3c#o2co3c#d#c#o2af#mne", 0
DB "o3mlef#g#abo4c#d#mne8mseee8e8mlg#4g#8", 0
DB "msf#8mse8d#8e8c#8o3bo4c#o3bo4c#o3bo4c#d#eo3a", 0
DB "bababo4c#d#o3g#ag#ag#abo4c#o3f#g#f#g#f#", 0
DB "g#f#g#f#g#f#d#o2bo3mlbo4c#d#mne8eee8e8mlg#4g#8", 0
DB "msf#8e8d#8e8c#8o3bo4c#o3bo4c#o3b", 0
DB "o4c#d#eo3abababo4c#d#o3g#ag#ag#abo4c#o3f#", 0
DB "g#f#g#f#ag#f#e8o2b8o3e8g#g#g#8mng#g#g#8", 0
DB "g#g#g#8o4c#8o3g#8o4c#8o3g#8o4c#8o3g#8f#8e8", 0
DB "d#8c#8g#g#g#8g#g#g#8g#g#g#8o4c#8o3g#8", 0
DB "o4c#8o3g#8o4c#8o3b8a#8b8a#8b8g#g#g#8", 0
DB "g#g#g#8g#g#g#8o4c#8o3g#8o4c#8o3g#8o4c#8o3g#8", 0
DB "f#8e8d#8c#8g#g#g#8g#g#g#8g#g#g#8", 0
DB "o4c#8o3g#8o4c#8o3g#8o4c#8o3b8a#8b8a#8b8", 0
DB "o2f#f#f#8f#f#f#8g#8a8f#4a8g#8", 0
DB "e4g#8f#8o0b8o1b8o2f#f#f#8f#f#f#8", 0
DB "g#8a8f#4a8g#8e4g#8f#8", 0
DB "bbb8o1bbb8bbb8bbo2e8f#8g#8", 0
DB "o1bbb8bbo2e8g#g#f#8d#8o1b8bbb8", 0
DB "bbb8bbo2e8f#8g#8eg#mlb4mnb", 0
DB "ag#f#e8o1b8o2e8o3bbb8bbb8bbo4e8", 0
DB "f#8g#8o3bbb8bbo4e8g#g#f#8d#8o3b8", 0
DB "bbb8bbb8bbo4e8f#8g#8o3eg#mlb4", 0
DB "mnbag#f#mlef#g#mnamlg#abo4mnc#mlo3bo4c#d#mnemld#", 0
DB "ef#mng#ao3bo4ao3bo4ao3bo4ao3bo4ao3bo4ao3bo4ao3bo4ao3bmle", 0
DB "f#g#mnamlg#abmno4c#mlo3bo4c#d#mnemld#ef#mng#ao3bo4ao3bo4a", 0
DB "o3bo4ao3bo4ao3bo4ao3bo4ao3bo4ao3bp16mlg#o4g#o3mng#p16mld#o4d#o3mnd#p16", 0
DB "mleo4eo3mnep16mlao4ao3mnap16mlg#o4g#o3mng#p16mld#o4d#o3mnd#p16mleo4eo3mnep16", 0
DB "mlao4ao3mnao4go3go4go3go4go3go4go3go4msg8e8c8e8o4mng#", 0
DB "o3g#o4g#o3g#o4g#o3g#o4g#o3g#o4msg#8e8o3b8o4e8mng#o3g#o4g#o3g#o4g#", 0
DB "o3g#o4g#o3g#o4msg#8f8c#8f8mna#o3a#o4a#o3a#o4a#o3a#o4a#o3a#o4msa#8", 0
DB "g8e8g8b8p16mna#p16ap16g#p16f#p16ep16", 0
DB "d#p16c#p16o3bp16a#p16ap16g#p16f#p16ep16d#p16f#mle", 0
DB "f#g#mnamlg#abmno4c#o3mlbo4c#d#mnemld#ef#mng#ao3bo4ao3bo4a", 0
DB "o3bo4ao3bo4ao3bo4ao3bo4ao3bo4ao3bmlef#g#mnamlg#abmno4c#o3mlb", 0
DB "o4c#d#mnemld#ef#mng#ao3bo4ao3bo4ao3bo4ao3bo4ao3bo4ao3bo4a", 0
DB "o3bo4ao3bp16mlg#o4g#o3mng#p16mld#o4d#o3mnd#p16mleo4eo3mnep16mlao4ao3mnap16", 0
DB "mlg#o4g#o3mng#p16mld#o4d#o3mnd#p16mleo4eo3mnep16mlao4ao3mnao4go3go4go3go4g", 0
DB "o3go4go3go4g8e8c8e8g#o3g#o4g#o3g#o4g#o3g#o4g#o3g#o4g#8", 0
DB "e8o3b8o4e8g#o3g#o4g#o3g#o4g#o3g#o4g#o3g#o4msg#8mnf8c#8", 0
DB "f8a#o3a#o4a#o3a#o4a#o3a#o4a#o3a#o4a#8g8e8g8b8", 0
DB "p16a#p16ap16g#p16f#p16ep16d#p16c#p16o3bp16a#p16", 0
DB "ap16g#p16f#p16ep16d#p16fmled#ed#mne8bbb8", 0
DB "bbb8bbo4e8f#8g#8o3bbb8bbb8", 0
DB "bbo4g#8a8b8p8e8f#8g#8p8o3g#8", 0
DB "a8b8p8p2o2bco3c#dd#", 0
DB "eff#gg#aa#bco4c#d#ed#f#d#ed#f#d#e", 0
DB "d#f#d#ed#f#d#ed#f#d#ed#f#d#ed#f#d#e", 0
DB "d#f#d#e8eo3eo4eo3eo4eo3eo4e8o3bo2bo3bo2bo3bo2bo3b8", 0
DB "g#o2g#o3g#o2g#o3g#o2g#o3g8eo2eo3eo2eo3eo2eo3e8eee8", 0
DB "e8e8o2bbb8b8b8g#g#g#8g#8g#8", 0
DB "eee8e8e8o1b8o2e8o1b8o2g#8e8b8", 0
DB "g#8o3e8o2b8o3e8o2b8o3g#8e8b8g#8o4e4", 0
DB "p8eee8e8e8e8e4p8p16", 0
DB "ee4p8p16o2ee2", 0

End
