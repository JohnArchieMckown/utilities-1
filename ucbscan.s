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
UCBSCAN CEEENTRY PPA=UCBSCAN_PPA,
               MAIN=NO,
               EXPORT=YES,
               AUTO=DSASIZE,
               BASE=R11_32
UCBSCAN  ALIAS C'ucbscan'
         USING CEECAA,R12_32
         USING CEEDSA,R13_32
         J     GO
GOBACK   DS    0H
*wto 'ucbscan - goback',routcde=11
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
*wto 'ucbscan - ceeterm',routcde=11
         CEETERM RC=RETURN_CODE,
               MODIFIER=MODIFIER
GO       DS    0H
         XC    RETURN_CODE,RETURN_CODE
         XC    MODIFIER,MODIFIER
         LR    R10_32,R1_32       SAVE R1 UPON ENTRY
         MVC   RETURN_CODE,=F'-1'
         LR    R0_32,R15_32
         LT    R9_32,0(,R10_32)
         JZ    CEETERM
         ST    R10_32,ARGS@
         USING UCBSCANP,R10_32
         L     R3_32,@ARGC_       pointer to # arguments
         L     R4_32,@ARGVL_      pointer to argument lengths
         L     R5_32,@ARGV_       pointer to argument values
         XC    VOLSINFO,VOLSINFO
*wto 'ucbscan - iocinfo',routcde=11
IOCINFO  DS    0H
         IOCINFO IOCTOKEN=TOKEN,
               MF=(E,CALLX,COMPLETE)
         XC    SCANWORK,SCANWORK
         XC    RETURN_CODE,RETURN_CODE
SEARCH   DS    0H
*wto 'ucbscan - search',routcde=11
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
*wto 'ucbscan - pattern_match',routcde=11
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
*wto 'ucbscan - pattern_test',routcde=11
         LA    R1_32,0(R6_32,R7_32) LAST CHAR ADDR
         BCTR  R1_32,0            BACK UP
         CLI   0(R1_32),C'*'      END IN *?
         JE    PATTERN_TEST_I
         MVI   1(R1_32),C'*'      ADD ENDING *
         LA    R6_32,1(,R6_32)    AND ACCOUNT FOR IT IN LENGTH
PATTERN_TEST_I DS 0H
*wto 'ucbscan - pattern_testi_i',routcde=11
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
*wto 'ucbscan - next_pattern',routcde=11
         LA    R4_32,4(,R4_32)
         LA    R5_32,4(,R5_32)
         BCT   R3_32,PATTERN_MATCH
         J     SEARCH
RETURN_UCB DS  0H
*wto 'ucbscan - return_ucb',routcde=11
         LT    R15_32,@CALLBACK
         JZ    NOCALL
         LA    R1_32,CALLX
         ST    R2_32,CALLX+0      R2 points to the UCB
         LA    R2_32,MYDCE
         ST    R2_32,CALLX+4
         LA    R2_32,CMXTAREA
         ST    R2_32,CALLX+8
         MVC   CALLX+12(4),USERWORD
* Parm list is:
* +0(4) pointer to UCB found
* +4(4) pointer to DCE
* +8(4) contents of USERWORD
         BASR  R14_32,R15_32
*wto 'ucbscan - return_ucb back',routcde=11
         J     SEARCH
NOCALL   DS    0H
*wto 'ucbscan - nocall',routcde=11
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
CEE3DMP  Dc    V(CEE3DMP)
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
TITLE    DC    CL80'UCBSCAN DUMP'
OPTIONS  DC    CL255'BLOCKS,STORAGE,REGST(256),GENOPTS'
         LTORG *
UCBSCAN_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=UCBSCAN,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
DW32     DS    32D
*                                 CALLER WHICH WILL BE CALLED
*                                 FOR EACH DISK ENTRY
@DUMPRET DS    A
ARGS@    DS    A
FC       DS    3F
RETURN_CODE DS F
MODIFIER DS    F
RETURN_VALUE DC A(0)               PREVIOUS DEFAULT DUB
REASON_CODE DC A(0)
CALLX    DS    30F
CALLXL   EQU   *-4
VOLSINFO DS    0F KEEP ALL 3 VOLS... VARIABLES TOGETHER!
VOLSFND  DS    H
VOLSUSED DS    H
UCBCOPY  DS    XL48
CMXTAREA DS    CL32
UCBPAREA DS    CL48
SCANWORK DS    CL100
TOKEN    DS    XL48
         DS    0D
RDSCB4   DC    0D'0',(LDSCB4)X'00'
         LTORG *
MYDCE    DC    XL100'00'
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
         COPY  UCBSCANP
         regs
         END   UCBSCAN
