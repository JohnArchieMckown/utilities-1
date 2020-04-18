*PROCESS ALIGN,NOCOMPAT,DXREF,FLAG(ALIGN,CONT,RECORD)
*PROCESS NOFOLD,NOINFO,PC(ON,DATA,GEN,MCALL),RENT,
*PROCESS RA2,NORLD,MXREF(FULL),RXREF,USING(MAP,WARN(13))
*PROCESS TYPECHECK(NOMAGNITUDE,REGISTER),XREF(FULL)
*WARNING - THIS PROGRAM REQUIRES THE HIGH-LEVEL ASSEMBLER
*          AS WELL AS LE/370
*          THIS PROGRAM IS RE-ENTRANT.
         PUSH  PRINT
         PRINT NOGEN
         SYSSTATE ASCENV=P,
               AMODE64=NO,
               ARCHLVL=2
         LCLA  &CALC,&THREE
&NL      SETC  BYTE(21)
&TAB     SETC  BYTE(05)
&NULL    SETC  BYTE(00)
         IEABRCX DEFINE
*        IEABRCX DISABLE
         IEABRCX ENABLE
_BALR    OPSYN BALR
BALR     OPSYN BASR
         POP   PRINT
         PRINT NOGEN
PRDASD   CEEENTRY PPA=PRDASD_PPA,
               MAIN=NO,
               EXPORT=YES,
               AUTO=DSASIZE,
               BASE=R11_32
PRDASD   ALIAS C'prdasd'
         USING CEECAA,R12_32
         USING CEEDSA,R13_32
         J     GO
GOBACK   DS    0H
 ago .skip
         LA    R1_32,MSGAREA      Output area
         ST    R1_32,CALLX+0
         LA    R1_32,CNTFMT1      Format control string
         ST    R1_32,CALLX+4
         LH    R1_32,VOLSUSED
         ST    R1_32,CALLX+8
         LH    R1_32,VOLSFND
         ST    R1_32,CALLX+12
         LA    R1_32,CALLX
         L     R15_32,SPRINTF
         BASR  R14_32,R15_32
         ST    R15_32,COUNT
         LA    R15_32,MSGAREA
         ST    R15_32,BUFFERA
         LA    R1_32,CALLX
         L     R15_32,BPX1WRT
         CALL  (15),(STDOUT,BUFFERA,ALET,COUNT,
               RETURN_VALUE,
               RETURN_CODE,
               REASON_CODE),VL,
               MF=(E,(1))
.skip anop
         LT    R1_32,IOV@
         JZ    NOFREE1
         LT    R0_32,IOVL
         JZ    NOFREE1
         STORAGE RELEASE,
               LENGTH=(0),
               ADDR=(1)
NOFREE1  DS    0H
         LT    R1_32,#STOR@
         JZ    NOFREE2
         LT    R0_32,#STORL
         JZ    NOFREE2
         STORAGE RELEASE,
               LENGTH=(0),
               SP=10,
               ADDR=(1)
NOFREE2  DS    0H
         CEETERM RC=RETURN_CODE,
               MODIFIER=MODIFIER
GO       DS    0H
         LR    R10_32,R1_32       SAVE R1 UPON ENTRY
         XC    VOLSINFO,VOLSINFO
         XC    IOV@,IOV@
         XC    IOVL,IOVL
         XC    #STOR@,#STOR@
         XC    #STORL,#STORL
         LM    R2_32,R5_32,0(R10_32)
         MVC   RETURN_CODE,=F'-1'
         ST    R15_32,MODIFIER
         LTR   R2_32,R2_32
         JZ    GOBACK
* R2_32 points to the UCB
* R3_32 points to the DCE
* R4_32 points to the Common UCB extention
* R5_32 points to the userword
         USING UCBOB,R2_32
         USING DCE,R3_32
         USING UCBCMEXT,R4_32
         MVC   SWITCH1,0(R5_32)
         TM    SWITCH1,OPT_LONG
         JNO   SHORT
         XC    CALLX,CALLX
         CEEPCALL lspace,MF=(E,CALLX)
SHORT    DS    0H
         LA    R1_32,MSGAREA
         ST    R1_32,CALLX+0
         LA    R1_32,MSGFMTS
         ST    R1_32,CALLX+4
         LA    R1_32,UCBVOLI
         ST    R1_32,CALLX+8
         LLH   R1_32,UCBCHAN
         ST    R1_32,CALLX+12
         LA    R1_32,CALLX
         L     R15_32,SPRINTF
         BASR  R14_32,R15_32
         ST    R15_32,COUNT
         LA    R15_32,MSGAREA
         ST    R15_32,BUFFERA
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDOUT,BUFFERA,ALET,COUNT,
               RETURN_VALUE,
               RETURN_CODE,
               REASON_CODE),VL,
               MF=(E,(1))
*        CEEPCALL BPX1WRT,(STDOUT,BUFFERA,ALET,COUNT,
*              RETURN_VALUE,
*              RETURN_CODE,
*              REASON_CODE),VL,
*              MF=(E,(1))
         J     GOBACK
CONSTANTS DS   D
STDIN    DC    F'0'
STDOUT   DC    F'1'
STDERR   DC    F'2'
ALET     DC    A(0)
BPX1WRT  DC    V(BPX1WRT)
IOV_ALET EQU   ALET
IOV_BUFFER_ALET EQU ALET
SPRINTF  DC    V(SPRINTF)
CNTFMT1  DC    C'%i&TAB.%i'
         DC    C'&NL.&NULL.'
MSGFMTS  DC    C'%6.6s&TAB./%04X'
         DC    C'&NL.&NULL.'
MSGFMTL  DC    C'%6.6s&TAB.%04X&TAB.%s'
         DC    8C'&TAB.%u'
         DC    C'&NL.&NULL.'
HEADER   DC    C'VOLSER&TAB.Addr&TAB'
         DC    C'SMS Indicator&TAB.Extents&TAB.'
         DC    C'Total Cylinders&TAB.Total Tracks&TAB'
         DC    C'Largest Extent in Cylinders&TAB'
         DC    C'Largest Extent in Tracks&TAB'
         DC    C'Cylinders on Device&TAB'
         DC    C'Tracks Per Cylinder&TAB'
         DC    C'Track Size&NL'
LHEADER  EQU   *-HEADER
PRDASD_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=PRDASD,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         LTORG
         CEEDSA
IOV@     DS    A
IOVL     DS    F
BUFFERA  DS    A
COUNT    DS    F
#STOR@   DS    A
#STORL   DS    F
RETURN_CODE DS F
MODIFIER DS    F
RETURN_VALUE DC A(0)               PREVIOUS DEFAULT DUB
REASON_CODE DC A(0)
*EETERM_BLOCK CEETERM MF=L
CALLX    DS    30F
CALLXL   EQU   *-4
IOV_COUNT DS   F
IOV_STRUC DS   0D
         DS    (10*8)A            ROOM FOR 10 ADDRESS / LENGTH PAIRS
IOV_STRUC_L EQU *-IOV_STRUC
IOV_STRUC_N EQU IOV_STRUC_L/8
* GROUP TOGETHER
VOLSINFO DS    0F
VOLSFND  DS    H
VOLSUSED DS    H
* END GROUP
MSGAREA  DS    CL256
SWITCH1  DS    X
OPT_DEBUG EQU  X'80'
OPT_COUNT EQU  X'40'
OPT_LONG EQU   X'20'
OPT_ADDR EQU   X'10'
OPT_LIMIT EQU  X'08'
OPT_VTOC EQU   X'01'
DSASIZE  EQU   *-CEEDSA
UCB      DSECT
         IEFUCBOB LIST=YES         UCB MAPPING MACRO
         IECDDCE
         CVT    DSECT=YES,LIST=YES
DSCB4    DSECT
         IECSDSL1 (4)
LDSCB4   EQU   *-DSCB4
         CEECAA
         regs
         END   PRDASD
