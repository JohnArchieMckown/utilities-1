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
LSDASD   CEEENTRY PPA=LSDASD_PPA,
               MAIN=YES,
               AUTO=DSASIZE,
               BASE=R11_32
         USING CEECAA,R12_32
         USING CEEDSA,R13_32
         USING UCBSCANP,UCBSCANP_
         J     GO
GOBACK   DS    0H
         TM    SWITCH1,OPT_COUNT
         JNO   NOT_COUNT
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
         CEEPCALL BPX1WRT,(STDOUT,BUFFERA,ALET,COUNT,
               RETURN_VALUE,
               RETURN_CODE,
               REASON_CODE),VL,
               MF=(E,(1))
NOT_COUNT DS   0H
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
               MF=(E,CEETERM_BLOCK)
GO       DS    0H
         LR    R10_32,R1_32       SAVE R1 UPON ENTRY
*wto 'lsdasd go',routcde=11
         MVI   SWITCH1,0
         XC    VOLSINFO,VOLSINFO
         XC    IOV@,IOV@
         XC    IOVL,IOVL
         USING PARMS,R10_32
         LA    R1_32,CALLX
         L     R15_32,CEE3INF
         CALL  (15),(SYS,ENV,MEMBER,GPID,FC),VL,
               MF=(E,(1))
         TM    SYS,X'02'          UNIX?
         JNO   GOBACK             NO
*wto 'lsdasd is unix',routcde=11
         XC    #ARGC,#ARGC
         LA    R1_32,#ARGC
         ST    R1_32,#ARGC@
         L     R3_32,@ARGC        pointer to # arguments
         L     R3_32,0(,R3_32)
         L     R4_32,@ARGVL       pointer to argument lengths
         L     R5_32,@ARGV        pointer to argument values
*
* Test ARGV[0] for c'lsvtoc'
* This is a bit difficult because the name
* might be prefixed by a path, either
* absolute or relative. So we need to take
* that into account.
* 1) if the length of the parameter is too short,
*    then it cannot be equal, so goto NOT_VTOC
* 2) if the length of the parameter is exactly the
*    length of the program name, then we need to check
*    the name without a leading slash.
* 3) if the length of the parameter is greater
*    than the length of the program name, then we
*    need to check the last "n" characters for the
*    program name with a leading slash.
*
         L     R6_32,0(,R4_32)    Point to addr of length
         L     R6_32,0(,R6_32)    Get length
         L     R7_32,0(,R5_32)
         CHI   R6_32,L'LSVTOC-1
         JL    END_VTOC
         JH    HAS_PATH
NO_PATH  DS    0H
         CLC   LSVTOC+1(L'LSVTOC-1),0(R7_32)
         JNE   END_VTOC
IS_VTOC  DS    0H
         OI    SWITCH1,OPT_VTOC
         J     END_VTOC
HAS_PATH DS    0H
         ALR   R7_32,R6_32        Point to last byte + 1
         AHI   R7_32,0-L'LSVTOC   # bytes to back u
         CHI   R6_32,L'LSVTOC
         JL    NO_PATH            Check only program name
         CLC   LSVTOC,0(R7_32)
         JE    IS_VTOC
END_VTOC DS    0H
         CHI   R3_32,20
         JL    NODYNAM
         SLL   R3_32,8            # PARAMETERS * 8
         STORAGE OBTAIN,
               LENGTH=(3),
               SP=10,
               BNDRY=PAGE
         ST    R1_32,#STOR@       Dynamic Storage address
         ST    R3_32,#STORL       and length in bytes
         ST    R1_32,#ARGVL@      addr of array of lengths
         SRL   R3_32,1            Now equal to # parametes * 4
         LA    R3_32,0(R3_32,R1_32)
         ST    R3_32,#ARGV@       addr of array of C-strings
         J     CONTV
NODYNAM  DS    0H
         XC    #STOR@,#STOR@
         XC    #STORL,#STORL
         LA    R1_32,#ARGV
         ST    R1_32,#ARGV@
         LA    R1_32,#ARGVL
         ST    R1_32,#ARGVL@
CONTV    DS    0H
         L     R3_32,@ARGC        pointer to # arguments
         L     R3_32,0(,R3_32)    load number of arguments
         AHI   R3_32,-1           Dec by one because first is junk
         JNP   NOARGS             Eek! None left.
         L     R4_32,@ARGVL
         LA    R4_32,4(,R4_32)    Skip first parm
         L     R5_32,@ARGV
         LA    R5_32,4(,R5_32)    Skip first parm
         L     R8_32,#ARGVL@
         L     R9_32,#ARGV@
ARGSU    DS    0H                 UPPER CASE SOME ARGUMENTS
         LHI   R1_32,0
         LT    R6_32,0(,R4_32)    POINTER TO LENGTH
         JZ    BAD_PARM
         LHI   R1_32,4
         LR    R2_32,R6_32
         L     R6_32,0(,R6_32)
         AHI   R6_32,-1           ADJ LENGTH FOR TRAILING X'00'
         JNP   BAD_PARM
         LHI   R1_32,8
         LT    R7_32,0(,R5_32)    POINTER TO ARGUMENT
         JZ    BAD_PARM
         CLI   0(R7_32),C'-'      OPTION?
         JE    SWITCH             YES, DON'T UPPER CASE IT
         LHI   R1_32,12
         BCTR  R6_32,0            DEC BY 1 FOR EX
         CHI   R6_32,5            TOO LONG?
         JH    BAD_PARM           YES
         EX    R6_32,TOUPPER      UPPER CASE IT
         L     R0_32,#ARGC
         SLL   R0_32,2            Times 4 for Index
         L     R8_32,#ARGVL@
         ALR   R8_32,R0_32
         MVC   0(4,R8_32),0(R4_32)
         L     R9_32,#ARGV@
         ALR   R9_32,R0_32
         MVC   0(4,R9_32),0(R5_32)
         AHI   R1_32,1            Add 1 to Argument count
         ST    R1_32,#ARGC
* Above puts the value of R0_32 into the high word of R7_64
NARGSU   DS    0H
         LA    R4_32,4(,R4_32)    NEXT ARG LENGTH POINTER POINTER
         LA    R5_32,4(,R5_32)    NEXT ARG VALUE POINTER POINTER
         BCT   R3_32,ARGSU        LOOP
NOARGS   DS    0H
*wto 'lsdasd noargs',routcde=11
*        J     IOCINFO
*IOCINFO  DS    0H
*         IOCINFO IOCTOKEN=TOKEN,
*               MF=(E,CALLX,COMPLETE)
*         XC    SCANWORK,SCANWORK
         XC    RETURN_CODE,RETURN_CODE
         TM    SWITCH1,OPT_VTOC   VTOC listing?
         JO    DO_VTOC
         TM    SWITCH1,OPT_LONG   LONG listing?
         JZ    NOHEADER           No, don't print header.
         LA    R15_32,LHEADER
         ST    R15_32,COUNT       SAVE LENGTH OF OUTPUT MESSAGE
         LA    R15_32,HEADER
         ST    R15_32,BUFFERA
         LA    R1_32,CALLX
         CEEPCALL BPX1WRT,(STDOUT,BUFFERA,ALET,COUNT,
               RETURN_VALUE,
               RETURN_CODE,
               REASON_CODE),VL,
               MF=(E,(1))
NOHEADER DS    0H
         LA    R1_32,CALLX
         XC    CALLX,CALLX
         CEEPCALL prdasd,MF=(E,(1))
         ST    R0_32,@CALLBACK
         CHI   R15_32,-1
         JNE   *+2
         SR    R7_32,R7_32
         TM    SWITCH1,OPT_COUNT
         JNO   DO_LSPACE
         XC    @CALLBACK,@CALLBACK
         J     SEARCH
*
* The following two sections of code are weird because I
* cannot figure out how to the the entry point of a function
* in a DLL. So I have written both LVTOC and LSPACE to
* check word 1 for an F'0'. If it is zero, then they
* return with a return code of minus 1 and their EPA in
* R0_32.
* There's gotta be a better way.
DO_VTOC  DS    0H
*wto 'lsdasd do_vtoc',routcde=11
         XC    CALLX,CALLX
         CEEPCALL LVTOC,MF=(E,CALLX)
         ST    R0_32,@CALLBACK
         C     R15_32,=F'-1'
         JNE   *+2 THIS ABEND SHOULD NOT OCCUR
         J     SEARCH
DO_LSPACE DS   0H
*wto 'lsdasd do_lspace'
         XC    CALLX,CALLX
         CEEPCALL lspace,MF=(E,CALLX)
         ST    R0_32,@LSPACE
         C     R15_32,=F'-1'
         JNE   *+2 THIS ABEND SHOULD NOT OCCUR
         J     SEARCH
SEARCH   DS    0H
*wto 'lsdasd search',routcde=11
         LA    R1_32,UCBSCANP_
         LA    R2_32,SWITCH1
         ST    R2_32,USERWORD
         MVC   @ARGC_,#ARGC@
         MVC   @ARGVL_,#ARGVL@
         MVC   @ARGV_,#ARGV@
         CEEPCALL ucbscan,MF=(E,(1))
         ST    R15_32,RETURN_CODE
         ST    R0_32,VOLSINFO
         J     GOBACK
BAD_PARM DS    0H
         CHI   R1_32,NERR_JUMPS-ERR_JUMPS
         JH    UNKERR
         LHI   R0_32,-4
         NR    R0_32,R1_32
         CR    R0_32,R1_32
         JNE   UNKERR
         L     R14_32,@ARGC
         L     R14_32,0(,R14_32)
         SR    R14_32,R3_32
         CVD   R14_32,DOUBLE
         OI    DOUBLE+7,X'0F'
         UNPK  DW32(15),DOUBLE(8)
         LA    R14_32,DW32
         LHI   R15_32,15
FN0_1    DS    0H                 FIRST NON-ZERO
         CLI   0(R14_32),C'0'
         JNE   EFN0_1
         LA    R14_32,1(,R14_32)
         BCT   R15_32,FN0_1
EFN0_1   DS    0H
         MVC   IOV_STRUC+00(8),=A(EMSG_1,L'EMSG_1)
         STM   R14_32,R15_32,IOV_STRUC+08
         MVC   IOV_STRUC+16(8),=A(EMSG_2,L'EMSG_2)
         LR    R0_32,R14_32
         LARL  R15_32,ERR_JUMPS
         ALR   R15_32,R1_32
         BR    R15_32
EMSG_1   DC    C'Argument number: '
EMSG_2   DC    C' is in error. '
ERR_JUMPS DS   0H
         J     ERR_0
         J     ERR_4
         J     ERR_8
         J     ERR_12
NERR_JUMPS EQU *
ERR_0    DS    0H
* argument length is 0
         MVC   IOV_STRUC+24(8),=A(ERR_0_M,L'ERR_0_M)
         MVC   IOV_COUNT,F5
         MVC   RETURN_CODE,F4
         J     ERR_WRITE
ERR_0_M  DC    C': Address of argument length is NULL&NL.'
ERR_4    DS    0H
         MVC   IOV_STRUC+24(8),=A(ERR_4_M,L'ERR_4_M)
         CVD   R6_32,DOUBLE
         UNPK  CALLXL-16(15),DOUBLE
         LA    R14_32,CALLXL-16
         LHI   R15_32,15
FN0_4    DS    0H                 FIRST NON-ZERO
         CLI   0(R14_32),C'0'
         JNE   EFN0_4
         LA    R14_32,1(,R14_32)
         BCT   R15_32,FN0_4
EFN0_4   DS    0H
         STM   R14_32,R15_32,IOV_COUNT+32
         MVC   IOV_COUNT,F6
         MVC   RETURN_CODE,F5
         J     ERR_WRITE
ERR_4_M  DC    C': Argument length too small :'
ERR_8    DS    0H
         MVC   IOV_COUNT,F5
         MVC   IOV_STRUC+24(8),=A(ERR_8_M,L'ERR_8_M)
         MVC   RETURN_CODE,F6
         J     ERR_WRITE
ERR_8_M  DC    C': Address of argument is NULL&NL.'
ERR_12   DS    0H
         MVC   IOV_COUNT,F8
         MVC   IOV_STRUC+24(8),=A(ERR_12_M,L'ERR_12_M)
         ST    R7_32,IOV_STRUC+32
         ST    R6_32,IOV_STRUC+36
         MVC   IOV_STRUC+40(8),=A(ERR_12_V,L'ERR_12_V)
         AHI   R6_32,1
         CVD   R6_32,DOUBLE
         OI    DOUBLE+7,X'0F'
         UNPK  CALLXL-16(15),DOUBLE
         LA    R14_32,CALLXL-16
         LHI   R15_32,15
FN0_12   DS    0H                 FIRST NON-ZERO
         CLI   0(R14_32),C'0'
         JNE   EFN0_12
         LA    R14_32,1(,R14_32)
         BCT   R15_32,FN0_12
EFN0_12  DS    0H
         STM   R14_32,R15_32,IOV_COUNT+48
         MVC   IOV_STRUC+56(8),=A(NL,1)
         MVC   RETURN_CODE,F7
         J     ERR_WRITE
ERR_12_M DC    C': Argument value is too long:'
ERR_12_V DC    C' Value is:'
ERR_WRITE DS   0H
         LA    R1_32,CALLX
         CEEPCALL BPX1WRV,
               (STDERR,IOV_COUNT,IOV_STRUC,
               IOV_ALET,IOV_BUFFER_ALET,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1))
         J     GOBACK
UNKERR   DS    0H
         MVC   RETURN_CODE,F3

         J     GOBACK
SWITCH   DS    0H
         ST    R7_32,IOV_STRUC+8
         ST    R6_32,IOV_STRUC+12
SW_LOOP  DS    0H
         CLI   1(R7_32),C'd'
         JE    SETDEBUG
         CLI   1(R7_32),C'l'      Output "long" information
         JE    SETLONG
* In this case, the LSPACE information is written out UNLESS
* the -f switch is set as well. In that case, dataset information
* including dates, sizes, and DCB information is also listed
* in addition to volumes serial and DSN.
         CLI   1(R7_32),C'n'      Output device numbers too
         JE    SETADDR
         CLI   1(R7_32),C'f'      Output names of files on volume(s)
         JE    SETVTOC            OK, OK, they are datasets, not files
* Output the volume serial and DSNs (one per line) instead of just
* volume information.
         CLI   1(R7_32),C'm'      Change output limit
         JE    SETLIMIT
         CLI   1(R7_32),C'?'      display help
         JE    HELP_ME
         CLI   1(R7_32),C'h'      display help
         JE    HELP_ME
         CLI   1(R7_32),C'c'      Output counts
         JE    SETCOUNT
* Invalid switch
         MVC   IOV_STRUC+00(8),=A(SE_1,L'SE_1)
         MVC   IOV_STRUC+16(8),=A(NL,1)
         MVC   IOV_COUNT,F3
         LA    R1_32,CALLX
         CEEPCALL BPX1WRV,
               (STDERR,IOV_COUNT,IOV_STRUC,
               IOV_ALET,IOV_BUFFER_ALET,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1))
         MVC   RETURN_CODE,F2
         J     GOBACK
         LA    R7_32,1(,R7_32)
         BCT   R6_32,SW_LOOP
         J     NARGSU
HELP_ME  DS    0H
         XC    RETURN_CODE,RETURN_CODE
         J     GOBACK
SE_1     DC    C'Invalid switch string:'
SETLIMIT DC    0H
         OI    SWITCH1,OPT_LIMIT
         MVC   SWITCH1+1(3),=X'FFFFFF'
         J     NARGSU
SETVTOC  DC    0H
         OI    SWITCH1,OPT_VTOC
         J     NARGSU
SETADDR  DC    0H
         OI    SWITCH1,OPT_ADDR
         J     NARGSU
SETDEBUG DS    0H
         OI    SWITCH1,OPT_DEBUG
         J     NARGSU
SETLONG  DS    0H
         OI    SWITCH1,OPT_LONG
         J     NARGSU
SETCOUNT DS    0H
         OI    SWITCH1,OPT_COUNT
         J     NARGSU
RET0     DS    0H
         J     GOBACK
NOTUNIX  DS    0H
         ABEND 1,,STEP,REASON=1
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
QUESTION DC   C'?'
HEX0     DC   X'00'
STDIN    DC    F'0'
STDOUT   DC    F'1'
STDERR   DC    F'2'
ALET     DC    A(0)
IOV_ALET EQU   ALET
IOV_BUFFER_ALET EQU ALET
CEE3INF  DC    V(CEE3INF)
SPRINTF  DC    V(SPRINTF)
TOUPPER  TR    0(0,R7_32),UPPER
LSVTOC   DC    C'/lsvtoc&NULL'
DEBUG1   DC    C'Volume:&TAB.'
DEBUG2   DC    C'&TAB.Pattern:&TAB.'
SUCCESS  DC    C'&TAB.MATCH SUCCEEDED&NL.'
FAILED   DC    C'&TAB.MATCH FAILED&NL.'
CNTFMT1  DC    C'%i&TAB.%i'
         DC    C'&NL.&NULL.'
UPPER    DC    256AL1(*-UPPER)
         ORG   UPPER+C'a'
         DC    C'ABCDEFGHI'
         ORG   UPPER+C'j'
         DC    C'JKLMNOPQR'
         ORG   UPPER+C's'
         DC    C'STUVWXYZ'
         ORG
NL       DC    X'15'
HEADER   DC    C'VOLSER&TAB.Addr&TAB'
         DC    C'SMS Indicator&TAB.Extents&TAB.'
         DC    C'Total Cylinders&TAB.Total Tracks&TAB'
         DC    C'Largest Extent in Cylinders&TAB'
         DC    C'Largest Extent in Tracks&TAB'
         DC    C'Cylinders on Device&TAB'
         DC    C'Tracks Per Cylinder&TAB'
         DC    C'Track Size&NL'
LHEADER  EQU   *-HEADER
LSPACE1 LSPACE SMF=NONE,
               DATA=0,
               F4DSCB=0,
               MF=L
LLSPACE1 EQU   *-LSPACE1
TITLE    DC    CL80'LSDASD DUMP'
OPTIONS  DC    CL255'BLOCKS,STORAGE,REGST(256),GENOPTS'
         LTORG *
LSDASD_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=LSDASD,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
DOUBLE   DS    D                  FORCE DOUBLEWORD
@LSPACE  DS    A
UCBSCANP_ DS   (LUCBSCANP)X
UCBSCANP# EQU  *
RDSCB4   DC    0D'0',(LDSCB4)X'00'
*EELOAD  CEELOAD NAME=lspace.dll,MF=L
*CEELOAD EQU   *-CEELOAD
VOLSINFO DS    0F KEEP ALL 3 VOLS... VARIABLES TOGETHER!
VOLSFND  DS    H
VOLSUSED DS    H
         DS    F                  MUST REMAIN HERE!
DW32     DS    32D
IOV@     DS    A                  IOV STRUCTURE ADDRESS
IOVL     DS    F                  IOV STRUCTURE SIZE IN BYTES
#STORL   DS    F
#STOR@   DS    A
#ARGC@   DS    F
#ARGC    DS    F
#ARGV@   DS    A
#ARGV    DS    20A
#ARGVL@  DS    A
#ARGVL   DS    20A
TOKEN    DS    XL48
*PX1WRT  DC    A(0)               DYNAMICALLY LOADED
*PX1WRV  DC    A(0)               DYNAMICALLY LOADED
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
CALLXL   EQU   *-4
IOV_COUNT DS   F
IOV_STRUC DS   0D
         DS    (10*8)A            ROOM FOR 10 ADDRESS / LENGTH PAIRS
IOV_STRUC_L EQU *-IOV_STRUC
IOV_STRUC_N EQU IOV_STRUC_L/8
SCANWORK DS    CL100
SWITCH1  DS    X
OPT_DEBUG EQU  X'80'
OPT_COUNT EQU  X'40'
OPT_LONG EQU   X'20'
OPT_ADDR EQU   X'10'
OPT_LIMIT EQU  X'08'
OPT_VTOC EQU   X'01'
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
MSGAREA  DS    CL256
DSASIZE  EQU   *-CEEDSA
*        COPY  FINDUCBP
         COPY  ucbscanp
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
PARMS    DSECT
@ARGC    DS    A                  ADDRESS OF NUMBER OF ARGUMENTS
@ARGVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF ARGS
@ARGV    DS    A                  ADDRESS OF VECTOR OF ARGS
@ENVL    DS    A                  ADDRESS OF NUMBER OF ENV VARS
@ENVVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF ENV VA
@ENV     DS    A                  ADDRESS OF VECTOR OF ENV VARS
         regs
         END   LSDASD
