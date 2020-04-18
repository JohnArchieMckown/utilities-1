         PUSH  PRINT
         PRINT NOGEN
         IEABRCX DEFINE
*        IEABRCX DISABLE
         IEABRCX ENABLE
&NL      SETC  BYTE(21)
&TAB     SETC  BYTE(05)
&NULL    SETC  BYTE(00)
_BALR    OPSYN BALR
BALR     OPSYN BASR
         POP   PRINT
         SYSSTATE ASCENV=P,
               AMODE64=NO,
               ARCHLVL=2
LSPACE   CEEENTRY PPA=LSPACE_PPA,
               MAIN=NO,
               EXPORT=YES,
               AUTO=DSASIZE,
               BASE=R11_32
LSPACE   ALIAS C'lspace'
         USING CEECAA,R12_32
         USING CEEDSA,R13_32
         J     GO
GOBACK   DS    0H
         CEETERM RC=RETURN_CODE,
               MODIFIER=MODIFIER
GO       DS    0H
         LM    R4_32,R5_32,0(R1_32)
         ST    R15_32,MODIFIER
         MVC   RETURN_CODE,=F'-1'
         LTR   R4_32,R4_32
         JZ    GOBACK
         XC    RETURN_CODE,RETURN_CODE
         USING UCBOB,R4_32
         XC    RETURN_CODE,RETURN_CODE
         LA    R0_32,CALLX
         MVC   CALLX(LLSPACE1),LSPACE1
         CEEPLDA RDSCB4,REG=8
         CEEPLDA SDATA,REG=7
         LSPACE UCB=((4)),
               DATA=((8)),
               SMF=NONE,
               F4DSCB=((7)),
               MF=(E,(1))
         ST    R15_32,RETURN_CODE
*        LA    R5_32,SDATA
*        LA    R6_32,RDSCB4
*        STM   R4_32,R6_32,CALLX
         J     GOBACK
         DROP  R4_32
         LTORG *
LSPACE_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=LSPACE,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEPDDA RDSCB4,SCOPE=EXPORT
RDSCB4   DC    0D'0',(LDSCB4)X'00'
         CEEPDDA END
         CEEPDDA SDATA,SCOPE=EXPORT
SDATA    DC    (LLSPACE1)X'00'
         CEEPDDA END
CONSTANTS DS   0F
LSPACE1 LSPACE SMF=NONE,
               DATA=0,
               F4DSCB=0,
               MF=L
LLSPACE1 EQU   *-LSPACE1
         LTORG *
         CEEDSA
RETURN_CODE DS F
MODIFIER DS    F
RETURN_VALUE DC A(0)               PREVIOUS DEFAULT DUB
REASON_CODE DC A(0)
CALLX    DS    30F
CALLXL   EQU   *-4
DSASIZE  EQU   *-CEEDSA
*        BPXYCONS DSECT=YES,LIST=YES
*        BPXYIOV
*        BPXYERNO LIST=YES
         CEECAA
UCB      DSECT
         IEFUCBOB LIST=YES         UCB MAPPING MACRO
*        IECDDCE
         CVT    DSECT=YES,LIST=YES
DSCB4    DSECT
         IECSDSL1 (4)
LDSCB4   EQU   *-DSCB4
         regs
         END   LSPACE
