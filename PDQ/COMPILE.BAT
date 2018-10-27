rem This is a sample batch file for compiling and linking with P.D.Q.
if not exist %1 goto goodname
rem Please do not type an extension!
goto exit
:goodname
bc %1 /o;
link /nod /noe /seg:250 %1, %1, nul, pdq;
del %1.obj
:exit
