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
LVTOC    CEEENTRY PPA=LVTOC_PPA,
               MAIN=NO,
               EXPORT=YES,
               AUTO=DSASIZE,
               BASE=R11_32
         USING CEECAA,R12_32
         USING CEEDSA,R13_32
         J     GO
GOBACK   DS    0H
         LT    R1_32,IOV@
         JZ    NOFREE
         LT    R0_32,IOVL
         JZ    NOFREE
         STORAGE RELEASE,
               LENGTH=(0),
               ADDR=(1)
NOFREE   DS    0H
         CEETERM RC=RETURN_CODE,
               MODIFIER=MODIFIER
GO       DS    0H
         LM    R4_32,R7_32,0(R1_32)
         ST    R15_32,MODIFIER
         MVC   RETURN_CODE,=F'-1'
         LTR   R4_32,R4_32
         JZ    GOBACK
         XC    RETURN_CODE,RETURN_CODE
         USING UCBOB,R4_32
         USING DCE,R5_32
         USING UCBCMEXT,R6_32
         MVC   SWITCH1,0(R7_32)
         LA    R15_32,UCBVOLI
         ST    R15_32,BUFFERA
         LA    R1_32,CALLX
         MVC   COUNT,=F'6'
         CALL  BPX1WRT,(STDOUT,BUFFERA,ALET,COUNT,
               RETURN_VALUE,
               RETURN_CODE,
               REASON_CODE),VL,
               MF=(E,(1))
         MVC   BUFFERA,=A(NL)
         MVC   COUNT,=F'1'
         LA    R1_32,CALLX
         CALL  BPX1WRT,(STDOUT,BUFFERA,ALET,COUNT,
               RETURN_VALUE,
               RETURN_CODE,
               REASON_CODE),VL,
               MF=(E,(1))
         J     GOBACK
         LTORG *
LVTOC_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=LVTOC,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
CONSTANTS DS   0F
STDIN    DC    F'0'
STDOUT   DC    F'1'
STDERR   DC    F'2'
ALET     DC    A(0)
SPRINTF  DC    V(SPRINTF)
NL       DC    C'&NL.'
         LTORG *
         CEEDSA
IOV@     DS    A                  IOV STRUCTURE ADDRESS
IOVL     DS    F                  IOV STRUCTURE SIZE IN BYTES
COUNT    DS    F
BUFFERA  DS    A
RETURN_CODE DS F
MODIFIER DS    F
RETURN_VALUE DC A(0)               PREVIOUS DEFAULT DUB
REASON_CODE DC A(0)
CALLX    DS    30F
CALLXL   EQU   *-4
MSGAREA  DS    CL256
SWITCH1  DS    X
OPT_DEBUG EQU  X'80'
OPT_COUNT EQU  X'40'
OPT_LONG EQU   X'20'
OPT_ADDR EQU   X'10'
OPT_VTOC EQU   X'08'
DSASIZE  EQU   *-CEEDSA
         BPXYCONS DSECT=YES,LIST=YES
         BPXYIOV
         BPXYERNO LIST=YES
         CEECAA
UCB      DSECT
         IEFUCBOB LIST=YES         UCB MAPPING MACRO
         IECDDCE
         CVT    DSECT=YES,LIST=YES
         regs
         END   LVTOC
