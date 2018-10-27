;********** COLORDAT.ASM - this holds the current CLS and PDQCPrint color

;Copyright (c) 1989 Ethan Winer

; 9/14/92, Thomas G. Hanlin III: added b$ForeColor for graphics modes


;The color byte value stored here is bit-coded using the method required by
;the PC's hardware.  The figure below shows the bit arrangement for the
;foreground, background, intensity, and flashing status.
;
;                    7  6  5  4  3  2  1  0   <--- bits in the color byte
;                    |  |  |  |  |  |  |  |
;     flash bit -----+  |  |  |  |  +--+--+----- foreground
;    background --------+--+--+  +----------- intensity bit


.Model Medium, Basic
    Public  P$Color     ;so CLS and PDQCPrint can get at it
    Public  b$ForeColor ;so PSET, PRESET, LINE, etc can get at it

.Data
    P$Color DB 7        ;default to white on black
    b$ForeColor DB 1    ;default on (normally white or blue, depending on mode)

End
