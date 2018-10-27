;*********** CYDATA.ASM - 10,000 stored as a single precision value

.Model Medium, Basic

.Data
    Public P$10000                  ;so everyone can get at it
    
    P$10000 DD 10000.0              ;used in Currency calculations to
                                    ;  multiply and divide by ten thousand
End
