         MACRO
&LABEL   _LT    &REG,&ADDR
&LABEL   DS     0H
         AIF    ('&SYSOPT_OPTABLE' EQ 'ZOP').OLD
         AIF    ('&SYSOPT_OPTABLE' EQ 'DOS').OLD
         AIF    ('&SYSOPT_OPTABLE' EQ 'ESA').OLD
         AIF    ('&SYSOPT_OPTABLE' EQ '370').OLD
         AIF    ('&SYSOPT_OPTABLE' EQ 'XA').OLD
         LT     &REG,&ADDR
         AGO    .NEW
.OLD     ANOP
         L      &REG,&ADDR
         LTR    &REG,&REG
.NEW     ANOP
         MEND
