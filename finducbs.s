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
FINDUCBS CEEENTRY PPA=FINDUCBS_PPA,
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
         CLC   RETURN_CODE,F0
         JZ    TEST_VOLS
         L     R0_32,MODIFIER
         J     CEETERM
TEST_VOLS DS   0H
         LT    R0_32,VOLSINFO
         JNZ   CEETERM
         MVC   RETURN_CODE,F1
CEETERM  DS    0H
         ST    R0_32,MODIFIER
         CEETERM RC=RETURN_CODE,
               MODIFIER=MODIFIER
GO       DS    0H
         XC    RETURN_CODE,RETURN_CODE
         XC    MODIFIER,MODIFIER
         LR    R10_32,R1_32       SAVE R1 UPON ENTRY
         ST    R10_32,ARGS@
         XC    IOV@,IOV@
         XC    IOVL,IOVL
         LOAD  EP=CEE3DMP
         ST    R0_32,CEE3DMP
         USING FINDUCBP,R10_32
         L     R3_32,@ARGC_       pointer to # arguments
         L     R4_32,@ARGVL_      pointer to argument lengths
         L     R5_32,@ARGV_       pointer to argument values
         XC    VOLSINFO,VOLSINFO
         LT    R3_32,0(,R3_32)    load number of arguments
         JNP   NOARGS
ARGSU    DS    0H                 UPPER CASE SOME ARGUMENTS
         LHI   R1_32,0
         LT    R6_32,0(,R4_32)    POINTER TO LENGTH
         JZ    NARGSU             ZERO?? SKIP IT!
         LHI   R1_32,4
         L     R6_32,0(,R6_32)
         AHI   R6_32,-1           ADJ LENGTH FOR TRAILING X'00'
         JNP   NARGSU
         LHI   R1_32,8
         LT    R7_32,0(,R5_32)    POINTER TO ARGUMENT
         JZ    NARGSU
         LHI   R1_32,12
         BCTR  R6_32,0            DEC BY 1 FOR EX
         CHI   R6_32,5            TOO LONG?
         JH    NARGSU             YES
         EX    R6_32,TOUPPER      UPPER CASE IT
NARGSU   DS    0H
         LA    R4_32,4(,R4_32)    NEXT ARG LENGTH POINTER POINTER
         LA    R5_32,4(,R5_32)    NEXT ARG VALUE POINTER POINTER
         BCT   R3_32,ARGSU        LOOP
         J     IOCINFO
NOARGS   DS    0H
         J     IOCINFO
IOCINFO  DS    0H
         IOCINFO IOCTOKEN=TOKEN,
               MF=(E,CALLX,COMPLETE)
         XC    SCANWORK,SCANWORK
         XC    RETURN_CODE,RETURN_CODE
SEARCH   DS    0H
         LA    R1_32,CALLX
         UCBSCAN COPY,UCBAREA=UCBCOPY,
               WORKAREA=SCANWORK,
               UCBPAREA=UCBPAREA,
               CMXTAREA=CMXTAREA,
               NONBASE=YES,
               RANGE=ALL,
               PLISTVER=MAX,
               DYNAMIC=YES,
               DCEAREA=MYDCE,
               DCELEN=LMYDCE,
               DEVCLASS=DASD,
               IOCTOKEN=TOKEN,
               MF=(E,(1))
         LTR   R15_32,R15_32
         JNZ   TESTDYN
         LA    R2_32,UCBCOPY         GET UCB ADDRESS THAT THE SCAN
*                                  SERVICE RETURNED
         USING UCBOB,R2_32
         TM    UCBSTAT,UCBONLI    Q. IS THIS DEVICE ONLINE ?
         JNO   SEARCH             A. NO - TRY AGAIN
         CLI   UCBTBYT3,UCB3DACC  DASD?
         JNE   SEARCH              NO
         LH    R1_32,VOLSFND
         AHI   R1_32,1
         STH   R1_32,VOLSFND
         L     R3_32,@ARGC_
         LT    R3_32,0(,R3_32)
         JNP   RETURN_UCB
         L     R4_32,@ARGVL_      &argv[0] length
         L     R5_32,@ARGV_       &argv[0] value
         LA    R8_32,UCBVOLI
PATTERN_MATCH DS 0H
         L     R6_32,0(,R4_32)    ADDR OF LENGTH, ALREADY VALIDATED
         L     R7_32,0(,R5_32)    ADDRESS OF ARGUMENT
         CLI   0(R7_32),C'-'      SWITCH?
         JE    NEXT_PATTERN       DON'T PROCESS IT
         L     R6_32,0(,R6_32)    LENGTH, ALREADY VALIDATED
         AHI   R6_32,-1           DON'T COUNT THE TRAILING X'00'
         JNP   NEXT_PATTERN
         CHI   R6_32,6
         JE    PATTERN_TEST_I
         JNH   PATTERN_TEST
         J     NEXT_PATTERN
PATTERN_TEST DS 0H
         LA    R1_32,0(R6_32,R7_32) LAST CHAR ADDR
         BCTR  R1_32,0            BACK UP
         CLI   0(R1_32),C'*'      END IN *?
         JE    PATTERN_TEST_I
         MVI   1(R1_32),C'*'      ADD ENDING *
         LA    R6_32,1(,R6_32)    AND ACCOUNT FOR IT IN LENGTH
PATTERN_TEST_I DS 0H
         ST    R6_32,CALLXL
         ASAXWC REQUEST=NORMALWC,
               PATTERNSTR=(R7_32),
               PATTERNSTRLEN=CALLXL,
               STRING=UCBVOLI,
               STRINGLEN=F6,
               ZEROORMORE=ASTERISK,
               ONECHAR=QUESTION,
               DELIMITER=HEX0,
               WORKAREA=DW32,
               MF=(E,CALLX,COMPLETE)
         LTR   R15_32,R15_32
         JZ    RETURN_UCB
NEXT_PATTERN DS 0H
         LA    R4_32,4(,R4_32)
         LA    R5_32,4(,R5_32)
         BCT   R3_32,PATTERN_MATCH
         J     SEARCH
RETURN_UCB DS  0H
         LT    R15_32,@CALLBACK
         JZ    NOCALL
         LA    R1_32,CALLX
         ST    R2_32,CALLX+0
         LA    R2_32,MYDCE
         ST    R2_32,CALLX+4
         LA    R2_32,CMXTAREA
         ST    R2_32,CALLX+8
         MVC   CALLX+12(4),USERWORD
         BASR  R14_32,R15_32
         LTR   R0_32,R15_32
         JZ    NOCALL
         ST    R0_32,MODIFIER
         MVC   RETURN_CODE,=F'-1'
         J     GOBACK
NOCALL   DS    0H
         LH    R1_32,VOLSUSED
         AHI   R1_32,1
         STH   R1_32,VOLSUSED
         J     SEARCH
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
TESTDYN  DS    0H
         CHI   R15_32,4
         JE    GOBACK
         CHI   R15_32,12           CONFIG CHANGE?
         JE    GO                 Start over
         JNE   GOBACK              NO, Exit
         J     GO                 Config change, start all over
RET0     DS    0H
         J     GOBACK
CONSTANTS DS   0F
F0       DC    F'0'
F1       DC    F'1'
F2       DC    F'2'
F3       DC    F'3'
F4       DC    F'4'
F5       DC    F'5'
F6       DC    F'6'
F7       DC    F'7'
F8       DC    F'8'
F9       DC    F'9'
ASTERISK DC   C'*'
QUESTION DC   C'?'
HEX0     DC   X'00'
LMYDCE   DC    AL2(L'MYDCE)
TOUPPER  TR    0(0,R7_32),UPPER
DEBUG1   DC    C'Volume:&TAB.'
DEBUG2   DC    C'&TAB.Pattern:&TAB.'
SUCCESS  DC    C'&TAB.MATCH SUCCEEDED&NL.'
FAILED   DC    C'&TAB.MATCH FAILED&NL.'
UPPER    DC    256AL1(*-UPPER)
         ORG   UPPER+C'a'
         DC    C'ABCDEFGHI'
         ORG   UPPER+C'j'
         DC    C'JKLMNOPQR'
         ORG   UPPER+C's'
         DC    C'STUVWXYZ'
         ORG
NL       DC    X'15'
LSPACE1 LSPACE SMF=NONE,
               DATA=0,
               F4DSCB=0,
               MF=L
LLSPACE1 EQU   *-LSPACE1
TITLE    DC    CL80'FINDUCBS DUMP'
OPTIONS  DC    CL255'BLOCKS,STORAGE,REGST(256),GENOPTS'
         LTORG *
FINDUCBS_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=FINDUCBS,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
DOUBLE   DS    D                  FORCE DOUBLEWORD
DW32     DS    32D
SAVE_REGS EQU  DW32
@PROCESS_ENTRY DS A               ADDRESS OF SUBROUTINE PASSED IN FROM
*                                 CALLER WHICH WILL BE CALLED
*                                 FOR EACH DISK ENTRY
@MASK    DS    A                  ADDRESS OF MASK
@DUMPRET DS    A
ARGS@    DS    A
IOV@     DS    A                  IOV STRUCTURE ADDRESS
IOVL     DS    F                  IOV STRUCTURE SIZE IN BYTES
CEE3DMP  DS    A
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
RETURN_CODE DS F
MODIFIER DS    F
RETURN_VALUE DC A(0)               PREVIOUS DEFAULT DUB
REASON_CODE DC A(0)
CALLX    DS    30F
CALLXL   EQU   *-4
IOV_COUNT DS   F
IOV_STRUC DS   0D
         DS    (10*8)A            ROOM FOR 10 ADDRESS / LENGTH PAIRS
IOV_STRUC_L EQU *-IOV_STRUC
IOV_STRUC_N EQU IOV_STRUC_L/8
VOLSINFO DS    0F KEEP ALL 3 VOLS... VARIABLES TOGETHER!
VOLSFND  DS    H
VOLSUSED DS    H
TOKEN    DS    XL48
TOKEN2   DS    XL48
UCBCOPY  DS    XL48
CMXTAREA DS    CL32
UCBPAREA DS    CL48
SCANWORK DS    CL100
         DS    0D
RECORD   DS    0D
RDSCB4   DC    0D'0',(LDSCB4)X'00'
SDATA    DC    (LLSPACE)X'00'
OUTDEV   DS    X
* OUTDEV CONTAIN A 1 BYTE CODE FOR THE DEVICE TYPE AS FOLLOWS:
* 0E = 3380 STANDARD
* 1E = 3380-D
* 21 = 3380-J
* 23 = 3380-K
* 2E = 3380-E
* 26 = 3390-1
* 27 = 3390-2
* 24 = 3390-3
* 32 = 3390-9
         LTORG *
MSGAREA  DS    CL256
MYDCE    DC    XL100'00'
SWITCH1  DS    X
DEBUG    EQU   X'80'
DSASIZE  EQU   *-CEEDSA
         BPXYCONS DSECT=YES,LIST=YES
         BPXYIOV
         BPXYERNO LIST=YES
         CEECAA
UCB      DSECT
         IEFUCBOB LIST=YES         UCB MAPPING MACRO
         IECDDCE
         CVT    DSECT=YES,LIST=YES
DSCB4    DSECT
         IECSDSL1 (4)
LDSCB4   EQU   *-DSCB4
LSPACE   LSPACE MF=(D,DATA)
LLSPACE  EQU   *-LSPACE
         COPY  FINDUCBP
         regs
         END   FINDUCBS
