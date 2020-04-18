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
         IEABRCX DEFINE
*        IEABRCX DISABLE
         IEABRCX ENABLE
_BALR    OPSYN BALR
BALR     OPSYN BASR
         POP   PRINT
         SYSSTATE ASCENV=P,
               AMODE64=NO,
               ARCHLVL=2
MCSOPER CEEENTRY PPA=MCSOPER_PPA,
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
         LOAD  EP=BPX1WRT
         ST    R0_32,BPX1WRT
         LOAD  EP=BPX1WRV
         ST    R0_32,BPX1WRV
         ST    R7_32,RETURN_CODE
         L     R3_32,@ARGC        pointer to # arguments
         L     R4_32,@ARGVL       pointer to argument lengths
         L     R5_32,@ARGV        pointer to argument values
         L     R3_32,0(,R3_32)    load number of arguments
         XC    IOV@,IOV@
         XC    IOVL,IOVL
         LA    R1_32,CALLX
         L     R15_32,CEE3INF
         CALL  (15),(SYS,ENV,MEMBER,GPID,FC),VL,
               MF=(E,(1))
         TM    SYS,X'02'          UNIX?
         JNO   NOTUNIX            NO
         LA    R2_32,MSGAREA
         ST    R2_32,BUFFERA      MESSAGE HERE
*        LR    R7_32,R3_32        LOAD NUMBER OF ARGUMENTS
         LA    R1_32,CALLX
         L     R15_32,SPRINTF
*
* Use sprintf to make a nice looking message.
         CALL  (15),
               ((2),MSGFMT1,(3)),
               MF=(E,(1))
         ST    R15_32,COUNT       SAVE LENGTH OF OUTPUT MESSAGE
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDOUT,BUFFERA,ALET,COUNT,
               RETVAL,
               RETCODE,
               RSNCODE),VL,
               MF=(E,(1))
         LA    R9_32,IOV_STRUC
         XC    IOV@,IOV@
         XC    IOVL,IOVL
         CHI   R3_32,IOV_STRUC_N/2
         JL    USEIT
         LR    R0_32,R3_32        NUMBER OF ARGUMENTS
         SLL   R0_32,4            MULTIPLY BY 16
         ST    R0_32,IOVL         SAVE NUMBER OF BYTES
         STORAGE OBTAIN,
               LENGTH=(0)
         ST    R1_32,IOV@         SAVE STORAGE ADDRESS
         LR    R9_32,R1_32
USEIT    DS    0H
         LR    R8_32,R9_32
         L     R3_32,@ARGC
         L     R3_32,0(,R3_32)
LOOP     DS    0H
         L     R1_32,0(,R4_32)    A(LENGTH)
         L     R1_32,0(,R1_32)    LOAD LENGTH
         BCTR  R1_32,0            DECREMENT TO IGNORE TRAILING 0x00
         ST    R1_32,4(,R9_32)    PUT IN PARM
         L     R1_32,0(,R5_32)
         MVC   0(4,R9_32),0(R5_32) MOVE IN A(VALUE)
         LA    R4_32,4(,R4_32)
         LA    R5_32,4(,R5_32)
         MVC   8(8,R9_32),=A(NL,1)
         LA    R9_32,16(,R9_32)
         BCT   R3_32,LOOP
         L     R3_32,@ARGC
         L     R3_32,0(,R3_32)    load number of arguments
         SLA   R3_32,1            MULTIPLY BY 2
         ST    R3_32,IOV_COUNT    STORE COUNT
         LA    R1_32,CALLX
         L     R15_32,BPX1WRV
         CALL  (15),
               (STDOUT,IOV_COUNT,(8),
               IOV_ALET,IOV_BUFFER_ALET,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1))
RET0     DS    0H
         XC    RETURN_CODE,RETURN_CODE
         XC    MODIFIER,MODIFIER
         J     GOBACK
NOTUNIX  DS    0H
         ABEND 1,,STEP,REASON=1
         J     GOBACK
DUMP     DS    0H
         ST    R14_32,@DUMPRET
         LA    R1_32,CALLX
         L     R15_32,CEE3DMP
         CALL  (15),
               (TITLE,OPTIONS,FC),
               VL,
               MF=(E,(1))
         L     R14_32,@DUMPRET
         BR    R14_32
STDIN    DC    F'0'
STDOUT   DC    F'1'
STDERR   DC    F'2'
ALET     DC    A(0)
IOV_ALET EQU   ALET
IOV_BUFFER_ALET EQU ALET
CEE3INF  DC    V(CEE3INF)
SPRINTF  DC    V(SPRINTF)
CEE3DMP  DC    V(CEE3DMP)
MSGFMT1  DC    C'Hello! I was given %i parameters.',X'1500'
TOHEX    DC    C'0123456789ABCDEF'
TAB      DC    X'05'
NL       DC    X'15'
TITLE    DC    CL80'MCSOPER DUMP'
OPTIONS  DC    CL255'BLOCKS,STORAGE,REGST(256),GENOPTS'
TOUPPER  DC    256AL1(*-TOUPPER)
         ORG   TOUPPER+X'81'
         DC    C'ABCDEFGHI'
         ORG   TOUPPER+X'91'
         DC    C'JKLMNOPQR'
         ORG   TOUPPER+X'A2'
         DC    C'STUVWXYZ'
         ORG
         LTORG *
MCSOPER_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=MCSOPER,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
         DS    0D                 FORCE DOUBLEWORD
@DUMPRET DS    A
IOV@     DS    A                  IOV STRUCTURE ADDRESS
IOVL     DS    F                  IOV STRUCTURE SIZE IN BYTES
BPX1WRT  DC    A(0)               DYNAMICALLY LOADED
BPX1WRV  DC    A(0)               DYNAMICALLY LOADED
COUNT    DS    F
BUFFERA  DS    A
RETVAL   DS    A(0)
RETCODE  DS    A(0)
RSNCODE  DS    A(0)
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
BUFL     DS    F
RETURN_CODE DS F
MODIFIER DS    F
RETURN_VALUE DC A(0)               PREVIOUS DEFAULT DUB
REASON_CODE DC A(0)
CEETERM_BLOCK CEETERM MF=L
CALLX    DS     30F
IOV_COUNT DS   F
IOV_STRUC DS   0D
         DS    (10*8)A            ROOM FOR 10 ADDRESS / LENGTH PAIRS
IOV_STRUC_L EQU *-IOV_STRUC
IOV_STRUC_N EQU IOV_STRUC_L/8
MSGAREA  DS    CL(20+L'MSGFMT1)
DSASIZE  EQU   *-CEEDSA
         BPXYCONS DSECT=YES,LIST=YES
         BPXYIOV
         BPXYERNO LIST=YES
         CEECAA
PARMS    DSECT
@ARGC    DS    A                  ADDRESS OF NUMBER OF ARGUMENTS
@ARGVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF ARGS
@ARGV    DS    A                  ADDRESS OF VECTOR OF ARGS
@ENVL    DS    A                  ADDRESS OF NUMBER OF ENV VARS
@ENVVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF ENV VA
@ENV     DS    A                  ADDRESS OF VECTOR OF ENV VARS
         regs
         END   MCSOPER
