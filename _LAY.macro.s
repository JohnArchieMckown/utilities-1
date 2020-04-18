         MACRO
&LABEL   _LAY   &REG,&ADDR
&LABEL   DS     0H
         AIF    ('&SYSOPT_OPTABLE' EQ 'ZOP').OLD
         AIF    ('&SYSOPT_OPTABLE' EQ 'DOS').OLD
         AIF    ('&SYSOPT_OPTABLE' EQ 'ESA').OLD
         AIF    ('&SYSOPT_OPTABLE' EQ '370').OLD
         AIF    ('&SYSOPT_OPTABLE' EQ 'XA').OLD
         LAY    &REG,&ADDR
         AGO    .NEW
.OLD     ANOP
O&SYSNDX.A DC     S(&ADDR)
.NEW     ANOP
         MEND
