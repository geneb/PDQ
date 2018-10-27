rem This batch file creates the PDQ7.QLB and PDSVBDOS.QLB Quick Library files
lib pdq @extract7.rsp
link /q @quick7.rsp
e:\vbdos\link /q @quickvbd.rsp
