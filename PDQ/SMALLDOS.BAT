rem This is a sample batch for linking with the SMALLDOS.LIB library
bc %1 /o;
link /nod /noe /seg:250 %1 _noread _noval _noerror,, nul, smalldos pdq ;
del %1.obj
