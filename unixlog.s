*PROCESS ALIGN,NOCOMPAT,DXREF,FLAG(ALIGN,CONT,RECORD)
*PROCESS NOFOLD,NOINFO,PC(ON,DATA,GEN,MCALL),RENT,
*PROCESS RA2,NORLD,MXREF(FULL),RXREF,USING(MAP,WARN(13))
*PROCESS TYPECHECK(NOMAGNITUDE,REGISTER),XREF(FULL)
*WARNING - THIS PROGRAM REQUIRES THE HIGH-LEVEL ASSEMBLER
*          AS WELL AS LE/370
*          THIS PROGRAM IS RE-ENTRANT.
         PUSH  PRINT
         PRINT NOGEN
&NL      SETC  BYTE(21)
&TAB     SETC  BYTE(05)
&NULL    SETC  BYTE(00)
         IEABRCX DEFINE
*        IEABRCX DISABLE
         IEABRCX ENABLE
_BALR    OPSYN BALR
BALR     OPSYN BASR
         POP   PRINT
         SYSSTATE ASCENV=P,
               AMODE64=NO,
               ARCHLVL=2
UNIXLOG CEEENTRY PPA=UNIXLOG_PPA,
               MAIN=YES,
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
               MF=(E,CEETERM_BLOCK)
GO       DS    0H
         LR    R10_32,R1_32       SAVE R1 UPON ENTRY
         USING PARMS,R10_32
         LA    R1_32,CALLX
         L     R15_32,CEE3INF
         CALL  (15),(SYS,ENV,MEMBER,GPID,FC),VL,
               MF=(E,(1))
         TM    SYS,X'02'          UNIX?
         JNO   GOBACK             NO
         XC    IOV@,IOV@
         XC    IOVL,IOVL
         LOAD  EP=BPX1WRT
         ST    R0_32,BPX1WRT
         LOAD  EP=BPX1WRV
         ST    R0_32,BPX1WRV
         L     R4_32,@ARGVL
         L     R5_32,@ARGV
         LA    R1_32,CALLX
         L     R15_32,SPRINTF
         L     R3_32,@ARGC        pointer to # arguments
         L     R4_32,@ARGVL       pointer to argument lengths
         L     R5_32,@ARGV        pointer to argument values
         LHI   R8_32,-1
         L     R3_32,0(,R3_32)    load number of arguments
         L     R7_32,4(0,R5_32)   A(ADDR OF ARG[1])
         CHI   R3_32,2
         JL    LOGIT
         L     R6_32,4(,R4_32)    A(LENGTH OF ARG[1])
         L     R6_32,0(,R6_32)    LENGTH OF ARG[1]
         AHI   R6_32,-2           DEC BY 1 FOR ENDING X'00'
         JM    LOGIT
         CHI   R6_32,15
         JH    LOGIT
         ALR   R7_32,R6_32
         AHI   R6_32,1
         MVC   NUMBER,=CL15'000000000000000'
         LA    R8_32,NUMBER+14
MOVEIT   DS    0H
         CLI   0(R7_32),C'0'
         JL    LOGIT
         CLI   0(R7_32),C'9'
         JH    LOGIT
         MVC   0(1,R8_32),0(R7_32)
         BCTR  R7_32,0
         BCTR  R8_32,0
         BCT   R6_32,MOVEIT
         PACK  DOUBLE,NUMBER
         CVB   R8_32,DOUBLE
LOGIT    DS    0H
*
* Use sprintf to make a nice looking message.
         LA    R2_32,MSGAREA
         ST    R2_32,BUFFERA      MESSAGE HERE
         ST    R2_32,CALLX+4
         CALL  (15),
               ((2),MSGFMT1,(R8_32)),
               MF=(E,(1))
*        ST    R15_32,COUNT       SAVE LENGTH OF OUTPUT MESSAGE
*        L     R15_32,BPX1WRT
*        LA    R1_32,CALLX
*        CALL  (15),(STDOUT,BUFFERA,ALET,COUNT,
*              RETVAL,
*              RETCODE,
*              RSNCODE),VL,
*              MF=(E,(1))
         ST    R8_32,CALLX
*        MVC   CALLX+4(4),=A(SYSLOG_MSG)
         CEEPCALL SYSLOG,MF=(E,CALLX)
         AGO   .SKIP1
LOOP     DS    0H
         L     R1_32,0(,R4_32)    A(LENGTH)
         L     R1_32,0(,R1_32)    LOAD LENGTH
         BCTR  R1_32,0            DECREMENT TO IGNORE TRAILING 0x00
         LA    R4_32,4(,R4_32)
         LA    R5_32,4(,R5_32)
         LA    R9_32,16(,R9_32)
         BCT   R3_32,LOOP
*        ST    R3_32,IOV_COUNT    STORE COUNT
*        LA    R1_32,CALLX
*        L     R15_32,BPX1WRV
*        CALL  (15),
*              (STDOUT,IOV_COUNT,(8),
*              IOV_ALET,IOV_BUFFER_ALET,
*              RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
*              MF=(E,(1))
.SKIP1   DS    0H
RET0     DS    0H
         XC    RETURN_CODE,RETURN_CODE
         XC    MODIFIER,MODIFIER
         J     GOBACK
NOTUNIX  DS    0H
         ABEND 1,,STEP,REASON=1
         J     GOBACK
STDIN    DC    F'0'
STDOUT   DC    F'1'
STDERR   DC    F'2'
ALET     DC    A(0)
IOV_ALET EQU   ALET
IOV_BUFFER_ALET EQU ALET
CEE3INF  DC    V(CEE3INF)
SPRINTF  DC    V(SPRINTF)
SYSLOG_MSG DC  C'This is a message&NL&NULL'
MSGFMT1  DC    C'This is unixsys with x=%i .&NL.&NULL.'
TOHEX    DC    C'0123456789ABCDEF'
TAB      DC    X'05'
NL       DC    X'15'
         LTORG *
UNIXLOG_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=UNIXLOG,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
         DS    0D                 FORCE DOUBLEWORD
DOUBLE   DS    D
IOV@     DS    A                  IOV STRUCTURE ADDRESS
IOVL     DS    F                  IOV STRUCTURE SIZE IN BYTES
BPX1WRT  DC    A(0)               DYNAMICALLY LOADED
BPX1WRV  DC    A(0)               DYNAMICALLY LOADED
COUNT    DS    F
BUFFERA  DS    A
SYS      DS    F
* BIT MEANING
*    0 X'80'
*    CURRENTLY EXECUTING IN THE CICS ENVIRONMENT
*    1 X'40'
*    CURRENTLY EXECUTING IN A CICS_PIPI ENVIRONMENT
*    2-3 X'30'
*    RESERVED FOR OTHER SPECIFIC CICS ENVIRONMENTS
*    4 X'10'
*    CURRENTLY EXECUTING IN A TSO ENVIRONMENT
*    5 X'08'
*    CURRENTLY EXECUTING IN A BATCH ENVIRONMENT
*    6 X'04'
*    CURRENTLY EXECUTING IN A Z/OS UNIX ENVIRONMENT
*    7-28
*    RESERVED FOR FUTURE USE
*    29
*    CURRENTLY EXECUTING ON Z/VSE(TM)
*    30
*    CURRENTLY EXECUTING ON Z/OS
*    31
*    PREVIOUSLY INDICATED AS EXECUTING ON Z/OS.E
*
ENV      DS    F
*
MEMBER   DS    F
*
GPID     DS    F
FC       DS    3F
RETURN_CODE DS F
MODIFIER DS    F
RETURN_VALUE DC A(0)               PREVIOUS DEFAULT DUB
REASON_CODE DC A(0)
CEETERM_BLOCK CEETERM MF=L
CALLX    DS    30F
IOV_COUNT DS   F
IOV_STRUC DS   0D
         DS    (10*8)A            ROOM FOR 10 ADDRESS / LENGTH PAIRS
IOV_STRUC_L EQU *-IOV_STRUC
IOV_STRUC_N EQU IOV_STRUC_L/8
MSGAREA  DS    CL(20+L'MSGFMT1)
NUMBER   DS    CL15
DSASIZE  EQU   *-CEEDSA
         BPXYCONS DSECT=YES,LIST=YES
         BPXYERNO LIST=YES
         BPXYIOV
         CEECAA
PARMS    DSECT
@ARGC    DS    A                  ADDRESS OF NUMBER OF ARGUMENTS
@ARGVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF ARGS
@ARGV    DS    A                  ADDRESS OF VECTOR OF ARGS
@ENVL    DS    A                  ADDRESS OF NUMBER OF ENV VARS
@ENVVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF ENV VA
@ENV     DS    A                  ADDRESS OF VECTOR OF ENV VARS
         regs
         END   UNIXLOG
