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
FLOWDRVR CEEENTRY PPA=FLOWDRVR_PPA,
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
         LA    R1_32,CALLX
         CLI   SYSIN_O,0
         JE    NO_CLOSE_SYSIN
         CLOSE (SYSIN),MF=(E,(1))
NO_CLOSE_SYSIN DS 0H
         LA    R1_32,CALLX
         CLOSE (SYSPUNCH),MF=(E,(1))
         CEETERM RC=RETURN_CODE,
               MF=(E,CEETERM_BLOCK)
GO       DS    0H
         LR    R10_32,R1_32       SAVE R1 UPON ENTRY
         USING PARMS,R10_32
         XC    IOV@,IOV@
         XC    IOVL,IOVL
         MVI   SYSIN_O,0          Mark SYSIN not open
         MVC   SYSIN(LDCBI),DCBI
         MVC   SYSPUNCH(LDCBO),DCBO
         LA    R1_32,CALLX
         L     R15_32,CEE3INF
         CALL  (15),(SYS,ENV,MEMBER,GPID,FC),VL,
               MF=(E,(1))
         TM    SYS,X'02'          UNIX?
         JNO   NOTUNIX            NO
         LOAD  EP=BPX1WRT
         ST    R0_32,BPX1WRT
         LOAD  EP=BPX1WRV
         ST    R0_32,BPX1WRV
         LA    R1_32,CALLX
         L     R15_32,CEE3INF
         CALL  (15),(SYS,ENV,MEMBER,GPID,FC),VL,
               MF=(E,(1))
         TM    SYS,X'02'          UNIX?
         JNO   NOTUNIX            NO
         LOAD  EP=BPXWDYN
         ST    R0_32,BPXWDYN
         LR    R15_32,R0_32
         LA    R1_32,CALLX
         LA    R2_32,ALLOC1
         ST    R2_32,0(,R1_32)
         OI    0(R1_32),X'80'
         BASR  R14_32,R15_32
*        LTR   R15_32,R15_32
*        JNZ   *+2
         L     R15_32,BPXWDYN
         LA    R1_32,CALLX
         LA    R2_32,ALLOC2
         ST    R2_32,0(,R1_32)
         OI    0(R1_32),X'80'
         BASR  R14_32,R15_32
*        LTR   R15_32,R15_32
*        JNZ   *+2
         LA    R1_32,CALLX
         MVC   CALLX(LOPENI),OPENI
         OPEN  (SYSIN,(INPUT)),
               MF=(E,(1))
         MVI   SYSIN_O,1
NOTUNIX  DS    0H
         MVC   CALLX(LOPENO),OPENO
         LA    R1_32,CALLX
         OPEN  (SYSPUNCH,(OUTPUT)),
               MF=(E,(1))
         LOAD  EP=FLOWASM
         ST    R0_32,FLOWASM
         XC    RETURN_CODE,RETURN_CODE
         XC    MODIFIER,MODIFIER
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
OPENI    OPEN  (0,(INPUT)),MF=L
LOPENI   EQU   *-OPENI
OPENO    OPEN  (0,(OUTPUT)),MF=L
LOPENO   EQU   *-OPENO
STDIN    DC    F'0'
STDOUT   DC    F'1'
STDERR   DC    F'2'
ALET     DC    A(0)
IOV_ALET EQU   ALET
IOV_BUFFER_ALET EQU ALET
CEE3INF  DC    V(CEE3INF)
SPRINTF  DC    V(SPRINTF)
CEE3DMP  DC    V(CEE3DMP)
DCBI     DCB   DDNAME=SYSIN,
               MACRF=GM,
               DSORG=PS,
               LRECL=80,
               RECFM=FB
LDCBI    EQU   *-DCBI
DCBO     DCB   DDNAME=SYSPUNCH,
               MACRF=PM,
               DSORG=PS,
               LRECL=80,
               RECFM=FB
LDCBO    EQU   *-DCBO
ALLOC1   DC    Y(LALLOC1S)
ALLOC1S  DC    C'ALLOC FI(SYSIN) PATH(''/dev/fd0'') FILEDATA(TEXT)'
         DC    C' MSG(2)'
LALLOC1S EQU   *-ALLOC1S
ALLOC2   DC    Y(LALLOC2S)
ALLOC2S  DC    C'ALLOC FI(SYSPUNCH) PATH(''/dev/fd1'') FILEDATA(TEXT)'
         DC    C' MSG(2)'
LALLOC2S EQU   *-ALLOC2S
TOHEX    DC    C'0123456789ABCDEF'
TAB      DC    X'05'
NL       DC    X'15'
TITLE    DC    CL80'FLOWDRVR DUMP'
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
FLOWDRVR_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=FLOWDRVR,
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
BPXWDYN  DC    A(0)               DYNAMICALLY LOADED
FLOWASM  DC    A(0)               DYNAMICALLY LOADED
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
SYSIN     DS   0F,(LDCBI)X
SYSPUNCH  DS   0F,(LDCBO)X
CALLX     DS    30A
IOV_COUNT DS   F
IOV_STRUC DS   0D
         DS    (10*8)A            ROOM FOR 10 ADDRESS / LENGTH PAIRS
IOV_STRUC_L EQU *-IOV_STRUC
IOV_STRUC_N EQU IOV_STRUC_L/8
SYSIN_O  DS    X
DSASIZE  EQU   *-CEEDSA
         DCBD  DSORG=PS,DEVD=DA         Define DCB DSECT
         ASMAXITP PRINT=GEN             Define exit parm lists
*        ASMDREG ,                      Define register equates
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
         END   FLOWDRVR
