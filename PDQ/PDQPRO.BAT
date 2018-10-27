rem This batch file creates a combined Quick Library from P.D.Q. and QuickPak
lib pdq @extract.rsp
link /q /seg:500 @pdqpro.rsp
