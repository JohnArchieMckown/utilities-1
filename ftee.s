*PROCESS ALIGN,NOCOMPAT,DXREF,FLAG(ALIGN,CONT,RECORD)
*PROCESS NOFOLD,NOINFO,PC(ON,DATA,GEN,MCALL),RENT,
*PROCESS RA2,NORLD,MXREF(FULL),RXREF,USING(MAP,WARN(13))
*PROCESS TYPECHECK(NOMAGNITUDE,REGISTER),XREF(FULL)
*WARNING - THIS PROGRAM REQUIRES THE HIGH-LEVEL ASSEMBLER
*          AS WELL AS LE/370
*          THIS PROGRAM IS RE-ENTRANT.
         PUSH  PRINT
         LCLC  &NL,&TAB
&NL      SETC  BYTE(21)
&TAB     SETC  BYTE(05)
         PRINT NOGEN
         IEABRCX DEFINE
*        IEABRCX DISABLE
         IEABRCX ENABLE
_BALR    OPSYN BALR
BALR     OPSYN BASR
         POP   PRINT
         SYSSTATE ASCENV=P,
               AMODE64=NO,
               ARCHLVL=2
FTEE     CEEENTRY PPA=FTEE_PPA,
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
         JNO   NOTUNIX            NO
         XC    IOV@,IOV@
         XC    IOVL,IOVL
         LOAD  EP=BPX1WRT
         ST    R0_32,BPX1WRT
         LOAD  EP=BPX1WRV
         ST    R0_32,BPX1WRV
         SLR   R0_32,R0_32
         ST    R0_32,DYN_Opts
         ST    R0_32,DYN_Opts_Len
         STC   R0_32,OPTION
         LT    R3_32,@ARGC        pointer to # arguments
         JZ    NoFiles
         L     R4_32,@ARGVL       pointer to argument lengths
         L     R5_32,@ARGV        pointer to argument values
         L     R3_32,0(,R3_32)    load number of arguments
         CHI   R3_32,2
         JL    NoFiles
         LA    R4_32,4(,R4_32)    SKIP ARG(0)
         LA    R5_32,4(,R5_32)    SKIP ARG(0)
         BCTR  R3_32,0            DEC # ARGS BY 1
LOOP     DS    0H
         L     R6_32,0(,R4_32)    A(LENGTH)
         LT    R6_32,0(,R6_32)    LOAD LENGTH
         JZ    NextLOOP
         L     R7_32,0(,R5_32)    A(STRING)
         TM    OPTION,DASHDASH
         JO    NotOpt
         CLI   0(R7_32),C'-'      Option?
         JE    Options
NotOpt   DS    0H
         CLI   0(R7_32),0         NULL string?
         JE    NextLOOP
* ..
Options  DS    0H
         CHI   R6_32,2
         JL    NextLOOP
NextOpt  DS    0H
         CLI   0(R7_32),0         End of Options string?
         JE    NextLOOP
         CLI   0(R7_32),C'x'      BPXWDYN Options?
         JE    BPXWDYN_Opt
         BRCT  R6_32,NextOpt
NextLOOP DS    0H
         LA    R4_32,4(,R4_32)
         LA    R5_32,4(,R5_32)
         BRCT  R3_32,LOOP
NoFiles  DS    0H
* ...
BPXWDYN_Opt DS 0H
         LT    R0_32,DYN_Opts
         JNZ   Ret20
DYN_Opt_Save DS 0H
         CHI   R6_32,2
         JL    DYN_Opt_Next_Arg
         CLI   1(R7_32),0
         JE    DYN_Opt_Next_Arg
         LA    R7_32,1(,R7_32)
         ST    R7_32,DYN_Opts
         BCTR  R6_32,0
         ST    R6_32,DYN_Opts_Len
         J     NextLOOP
DYN_Opt_Next_Arg DS 0H
         CHI   R3_32,1
         JE    NoMoreArgs
         LA    R4_32,4(,R4_32)
         LA    R5_32,4(,R5_32)
         L     R6_32,0(,R4_32)
         MVC   DYN_Opts,0(R4_32)
         MVC   DYN_Opts_Len,0(R6_32)
         BRCT  R3_32,NextLOOP     Absorb ARG
RET0     DS    0H
         XC    RETURN_CODE,RETURN_CODE
         XC    MODIFIER,MODIFIER
         J     GOBACK
NoMoreArgs DS  0H
         J     Ret20
Ret20    DS    0H
         MVC   RETURN_CODE,=F'20'
         J     GOBACK
NOTUNIX  DS    0H
         ABEND 1,,STEP,REASON=1
         J     GOBACK
DUMP     DS    0H
         ST    R14_32,@DUMPRET
         LA    R1_32,CALLX
         L     R15_32,CEE3DMP
         CALL  (15),
               (TITLE,DUMPOPTS,FC),
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
*PRINTF  DC    V(SPRINTF)
CEE3DMP  DC    V(CEE3DMP)
TOHEX    DC    C'0123456789ABCDEF'
TAB      DC    C'&TAB.'
NL       DC    C'&NL.'
TITLE    DC    CL80'FTEE DUMP'
DUMPOPTS DC    CL255'BLOCKS,STORAGE,REGST(256),GENOPTS'
TOUPPER  DC    256AL1(*-TOUPPER)
         ORG   TOUPPER+X'81'
         DC    C'ABCDEFGHI'
         ORG   TOUPPER+X'91'
         DC    C'JKLMNOPQR'
         ORG   TOUPPER+X'A2'
         DC    C'STUVWXYZ'
         ORG
         LTORG *
FTEE_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=FTEE,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
         DS    0D                 FORCE DOUBLEWORD
DYN_Opts DS    F
DYN_Opts_Len DS F
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
CALLX    DS     30A
IOV_COUNT DS   F
IOV_STRUC DS   0D
         DS    (10*8)A            ROOM FOR 10 ADDRESS / LENGTH PAIRS
IOV_STRUC_L EQU *-IOV_STRUC
IOV_STRUC_N EQU IOV_STRUC_L/8
*SGAREA  DS    CL(20+L'MSGFMT1)
OPTION   DS    X
DASHDASH EQU   X'80'
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
         AGO   .SKIP1
R0       EQU   0,,,,GR
R1       EQU   1,,,,GR
R2       EQU   2,,,,GR
R3       EQU   3,,,,GR
R4       EQU   4,,,,GR
R5       EQU   5,,,,GR
R6       EQU   6,,,,GR
R7       EQU   7,,,,GR
R8       EQU   8,,,,GR
R9       EQU   9,,,,GR
R10      EQU   10,,,,GR
R11      EQU   11,,,,GR
R12      EQU   12,,,,GR
R13      EQU   13,,,,GR
R14      EQU   14,,,,GR
R15      EQU   15,,,,GR
R0_64    EQU   0,,,,GR64
R1_64    EQU   1,,,,GR64
R2_64    EQU   2,,,,GR64
R3_64    EQU   3,,,,GR64
R4_64    EQU   4,,,,GR64
R5_64    EQU   5,,,,GR64
R6_64    EQU   6,,,,GR64
R7_64    EQU   7,,,,GR64
R8_64    EQU   8,,,,GR64
R9_64    EQU   9,,,,GR64
R10_64   EQU   10,,,,GR64
R11_64   EQU   11,,,,GR64
R12_64   EQU   12,,,,GR64
R13_64   EQU   13,,,,GR64
R14_64   EQU   14,,,,GR64
R15_64   EQU   15,,,,GR64
R0_32    EQU   0,,,,GR32
R1_32    EQU   1,,,,GR32
R2_32    EQU   2,,,,GR32
R3_32    EQU   3,,,,GR32
R4_32    EQU   4,,,,GR32
R5_32    EQU   5,,,,GR32
R6_32    EQU   6,,,,GR32
R7_32    EQU   7,,,,GR32
R8_32    EQU   8,,,,GR32
R9_32    EQU   9,,,,GR32
R10_32   EQU   10,,,,GR32
R11_32   EQU   11,,,,GR32
R12_32   EQU   12,,,,GR32
R13_32   EQU   13,,,,GR32
R14_32   EQU   14,,,,GR32
R15_32   EQU   15,,,,GR32
AR0      EQU   0,,,,AR
AR1      EQU   1,,,,AR
AR2      EQU   2,,,,AR
AR3      EQU   3,,,,AR
AR4      EQU   4,,,,AR
AR5      EQU   5,,,,AR
AR6      EQU   6,,,,AR
AR7      EQU   7,,,,AR
AR8      EQU   8,,,,AR
AR9      EQU   9,,,,AR
AR10     EQU   10,,,,AR
AR11     EQU   11,,,,AR
AR12     EQU   12,,,,AR
AR13     EQU   13,,,,AR
AR14     EQU   14,,,,AR
AR15     EQU   15,,,,AR
.SKIP1   ANOP
         END   FTEE
