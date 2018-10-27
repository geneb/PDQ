rem This batch file creates DEMOEGA.EXE from the necessary BASIC modules
bc demoega /o;
bc egabox /o;
bc egadot /o;
bc egaelips /o;
bc egaline /o;
bc egaprint /o;
link /nod /noe demoega egabox egadot egaelips egaline egaprint , , nul , pdq;
