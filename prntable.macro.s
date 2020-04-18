         MACRO
&LBL     PRNTABLE &CHARS
         AIF   (D'&LBL).SKIP
&LBL     DC    256X'00'
.SKIP    ANOP
         LCLC  &C
         LCLA  &I
&I       SETA  1
.GEN     ANOP
         AIF   (K'&CHARS LT &I).END
&C       SETC  '&CHARS'(&I,1)
         ORG   &LBL+C'&C'
         DC    C'&C'
&I       SETA  &I+1
         AGO   .GEN
.END     ANOP
         MEND
