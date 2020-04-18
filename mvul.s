*PROCESS ALIGN,NOCOMPAT,DXREF,FLAG(ALIGN,CONT,RECORD)
*PROCESS NOFOLD,NOINFO,PC(ON,DATA,GEN,MCALL),RENT,
*PROCESS RA2,NORLD,MXREF(FULL),RXREF,USING(MAP,WARN(13))
*PROCESS TYPECHECK(NOMAGNITUDE,REGISTER),XREF(FULL)
*WARNING - THIS PROGRAM REQUIRES THE HIGH-LEVEL ASSEMBLER
*          AS WELL AS LE/370
*          THIS PROGRAM IS RE-ENTRANT.
         LCLC  &NL,&TAB,&NULL
&NL      SETC  A2C(21)
&NL      SETC  '&NL'(4,1)
&TAB     SETC  A2C(05)
&TAB     SETC  '&TAB'(4,1)
&NULL    SETC  A2C(00)
&NULL    SETC  '&NULL'(4,1)
         PUSH  PRINT
         PRINT NOGEN
         SYSSTATE ASCENV=P,                                            x
               AMODE64=NO,                                             x
               ARCHLVL=2
         IEABRCX DEFINE
*        IEABRCX DISABLE
         IEABRCX ENABLE
_BALR    OPSYN BALR
BALR     OPSYN BASR
         POP   PRINT
mvUl     CEEENTRY PPA=mvUl_PPA,                                        x
               MAIN=YES,                                               x
               AUTO=DSASIZE,                                           x
               BASE=R11_32
         USING CEECAA,R12_32
         USING CEEDSA,R13_32
         J     GO
GOBACK   DS    0H
         LT    R1_32,IOV@
         JZ    NOFREE
         LT    R0_32,IOVL
         JZ    NOFREE
         STORAGE RELEASE,                                              x
               LENGTH=(0),                                             x
               ADDR=(1)
NOFREE   DS    0H
         CEETERM RC=RETURN_CODE,                                       x
               MF=(E,CEETERM_BLOCK)
GO       DS    0H
         LR    R10_32,R1_32       SAVE R1 UPON ENTRY
         USING PARMS,R10_32
         XC    IOV@,IOV@
         XC    IOVL,IOVL
         LA    R1_32,CALLX
         L     R15_32,CEE3INF
         CALL  (15),(SYS,ENV,MEMBER,GPID,FC),VL,                       x
               MF=(E,(1))
         TM    SYS,X'02'          UNIX?
         JNO   GOBACK             NO
         XC    RETURN_CODE,RETURN_CODE
         XC    IOV@,IOV@
         MVC   OnOFF,initOnOFF
         L     R1_32,CVTPTR
         USING CVT,R1_32
         L     R1_32,CVTECVT
         DROP  R1_32
         USING ECVT,R1_32
         L     R1_32,ECVTOEXT
         DROP  R1_32
         USING OEXT,R1_32
*
* set the OMVS Sysplex indicator
         MVC   SPFenqTo+11,OEXTFLG1
         DROP  R1_32
* Isolate the single bit
         NI    SPFenqTo+11,OEXTSYSPLEXACTV
* And copy to the second place as well.
         MVC   SPFenqFrom+8(4),SPFenqTo
*
         LOAD  EP=BPX1WRT         WRITE BUFFER
         ST    R0_32,BPX1WRT
         ST    R0_32,BPX1WRT@
         LOAD  EP=BPX1WRV         WRITE BUFFERS
         ST    R0_32,BPX1WRV
         ST    R0_32,BPX1WRV@
         LOAD  EP=BPX1REN         RENAME FILE
         ST    R0_32,BPX1REN
         L     R3_32,@ARGC        pointer to # arguments
         L     R4_32,@ARGVL       pointer to argument lengths
         L     R5_32,@ARGV        pointer to argument values
         L     R3_32,0(,R3_32)    load number of arguments
         LA    R1_32,CALLX
         L     R15_32,CEE3INF
         CALL  (15),(SYS,ENV,MEMBER,GPID,FC),VL,                       x
               MF=(E,(1))
         TM    SYS,X'02'          UNIX?
         JNO   NOTUNIX            NO
*
* R3_32 == Number of arguments
* R4_32 contains the address of a list of addresses of length
* R5_32 contains the address of a list of addresses to pointers
*       to strings
         L     R6_32,0(,R4_32)
         JZ    NEXTLOOP
         LT    R6_32,0(,R6_32)    get length of argument 0
         JZ    NEXTLOOP           Not much user to look at nothing
         CHI   R6_32,4            At least 4?
         JL    NEXTLOOP           Hum.
         L     R7_32,0(,R5_32)    Get pointer to address of string
         LA    R7_32,0(R6_32,R7_32)
         AHI   R7_32,-5
         CLC   0(5,R7_32),=C'mvlU&NULL'
         JNE   NEXTLOOP
         CHI   R6_32,5
         JNE   SLASH
_OK1     DS    0H
         NI    OnOFF,UlX
         J     NEXTLOOP
_SLASH   DS    0H
         BCTR  R7_32,0
         CLI   0(R7_32),C'/'
         JE    OK1
         J     NEXTLOOP
LOOP     DS    0H
         LT    R6_32,0(,R4_32)    Get pointer to length
         JZ    NEXTLOOP           NULL
         LT    R6_32,0(,R6_32)    get length of argument string
         JZ    NEXTLOOP           Not much user to look at nothing
         L     R7_32,0(,R5_32)    Get pointer to string
         TM    OnOFF,Eopts        -- already seen?
         JO    NotOption          Yes, don't bother with option test
         CLI   0(R7_32),C'-'      Option?
         JE    Options            Yes
NotOption DS   0H
*
* R7_32 points to the file name
* R6_32 contains the length of the file name
         J     NEXTLOOP
Options  DS    0H                 Process Options
         CHI   R6_32,2            At least 2?
         JL    NEXTLOOP           No - option is a single dash!
         BCTR  R6_32,0            Dec length by 1
         LA    R7_32,1(,R7_32)    Point to next char
         CLI   0(r7_32),c'-'      --?
         JNE   Option             No
         CHI   R6_32,2            Maybe Exactly --?
         JH    Option             No
         CHI   R6_32,1
         JE    Eos1
         OI    OnOFF,Eopts
         J     NEXTLOOP
Eos1     CLI   1(R7_32),0
         JNE   Option
         OI    OnOFF,Eopts
         J     NEXTLOOP
Option   DS    0H
         CLI   0(R7_32),0         End of string?
         JE    NEXTLOOP
         CLI   0(R7_32),C'v'      Verbose?
         JE    Verbose
         CLI   0(R7_32),C'q'      Quiet
         JE    Quiet
         CLI   0(R7_32),C's'      Silent
         JE    Quiet
         CLI   0(R7_32),C'l'      To "l"ower?
         JE    Lower
         CLI   0(R7_32),C'U'      To "U"pper?
         JE    Upper
         CLI   0(R7_32),C'e'      Do enqueue?
         JE    enqueue
         CLI   0(R7_32),C'E'      Do not do enqueue?
         JE    EnqueuX
         CLI   0(R7_32),C'd'      Debug?
         JE    Debug
         CLI   0(R7_32),C'D'      Do not debug?
         JE    DebugX
         CLI   0(R7_32),C'?'      Help/Usage?
         JE    Usage
         CLI   0(R7_32),C'h'      Help/Usage?
         JE    Usage
         OC    RETURN_CODE,=F'1'
         MVC   IOV_STRUC+0(4),=A(MSG1)
         MVC   IOV_STRUC+4(4),=A(MSG1L)
         ST    R7_32,IOV_STRUC+8
         MVC   IOV_STRUC+12(4),=F'1'
         MVC   IOV_STRUC+16(4),=A(NL)
         MVC   IOV_STRUC+20(4),=F'1'
         MVC   IOV_COUNT,=F'3'    3 ADDRESS/LENGTH PAIRS
         LA    R1_32,CALLX
         L     R15_32,BPX1WRV
         CALL  (15),                                                   x
               (STDERR,IOV_COUNT,IOV_STRUC,                            x
               IOV_ALET,IOV_BUFFER_ALET,                               x
               RETVAL,RETCODE,RSNCODE),VL,                             x
               MF=(E,(1)),LINKINST=BASR
         J     NextOpt
_Debug   DS    0H
         OI    OnOFF,Debug
         J     NextOpt
_DebugX  DS    0H
         NI    OnOFF,DebugX
         J     NextOpt
_enqueue DS    0h
         OI    OnOFF,Enqueue
         J     NextOpt
_EnqueuX DS    0H
         NI    OnOFF,EnqueueX
         J     NextOpt
_Verbose DS    0H
         MVC   BPX1WRT@,BPX1WRT
         MVC   BPX1WRV@,BPX1WRV
         OI    OnOFF,Verbose
         J     NextOpt
_Quiet   DS    0H
         MVC   BPX1WRT@,=A(DO_RETURN)
         MVC   BPX1WRV@,BPX1WRT@
         NI    OnOFF,VerboseX
         J     NextOpt
_Usage   DS    0H
*        CHI   R3_32,3
*        JNE   BADOPT
*Shelp   DS    0H
         TM    OnOFF,Hopt
         JO    NextOpt
         OI    OnOFF,Hopt
         MVC   BUFFERA,=A(HELPMSG)
         LHI   R8_32,LHELPMSG
         ST    R8_32,COUNT
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDERR,BUFFERA,ALET,COUNT,                        x
               RETVAL,                                                 x
               RETCODE,                                                x
               RSNCODE),VL,                                            x
               MF=(E,(1)),LINKINST=BASR
         J     NextOpt
_Lower   DS    0H
         NI    OnOFF,UlX
         J     NextOpt
_Upper   DS    0H
         OI    OnOFF,Ul
         J     NextOpt
NextOpt  DS    0H
         LA    R7_32,1(,R7_32)
         BRCT  R6_32,Option       Process next option
         J     NEXTLOOP           No more Options
NEXTLOOP DS    0H
         LA    R4_32,4(,R4_32)    Point to address of next length
         LA    R5_32,4(,R5_32)    Point to address of next pointer
         BRCT  R3_32,LOOP         Process next
*        MVC   RETURN_CODE+3(1),OnOFF
         J     GOBACK
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
         CALL  (15),                                                   x
               (TITLE,DOPTIONS,FC),                                    x
               VL,                                                     x
               MF=(E,(1))
         L     R14_32,@DUMPRET
DO_RETURN DS   0H
         XC    RETURN_CODE,RETURN_CODE
         XC    MODIFIER,MODIFIER
         XC    RETCODE,RETCODE
         XC    RSNCODE,RSNCODE
         SLR   R15_32,R15_32
         BR    R14_32
Do_Enqueue  DS    0H
RnameLEN equ   12
         SLR   R15_32,R15_32      Say ENQ succeeded.
         XC    RETCODE,RETCODE
         XC    RSNCODE,RSNCODE
         TM    OnOFF,Enqueue      Do we want an ENQ?
         JNO   DO_RETURN          No
         STMG  R2_64,R10_64,TempRegs+2*8
         MVC   RESTABLE(2*ISGYENQRES_LEN),RESTABLEI
*SGENQ_P USING ISGENQ_DSECT,RESTABLE
         LA    R1_32,SPFenqFrom
         ST    R1_32,RESTABLE+ISGYENQRESRNAMEADDR31-ISGYENQRES
*        ST    R1_32,ISGENQ_RESRNAMEADDR31
         LA    R1_32,SPFenqTo
         ST    R1_32,RESTABLE+ISGYENQRESRNAMEADDR31-ISGYENQRES+ISGYENQRx
               ES_LEN
*        ST    R1_32,ISGENQ_RESRNAMEADDR31+ISGENQL
         TM    SPFenqTo+11,OEXTSYSPLEXACTV
         LA    R1_32,CALLX
         JNO   ENQ_Sys
ENQ_Plex DS    0H
         MVI   RESTABLE+ISGYENQRESSCOPE-ISGYENQRES,ISGYENQ_kSYSTEMS
         MVI   RESTABLE+ISGYENQRESSCOPE-ISGYENQRES+ISGYENQRES_LEN,ISGYEx
               NQ_kSYSTEMS
*        MVI   ISGENQ_xscope,ISGENQ_XSCOPE_SYSPLEX
*        MVI   ISGENQ_xscope+ISGENQL,ISGENQ_XSCOPE_SYSPLEX
         J     Do_Enqueue_2
ENQ_Sys  DS    0H
*        MVI   ISGENQ_xscope,ISGENQ_XSCOPE_SYSTEM
*        MVI   ISGENQ_xscope+ISGENQL,ISGENQ_XSCOPE_SYSTEM
*        DROP  ISGENQ_P
         MVI   RESTABLE+ISGYENQRESSCOPE-ISGYENQRES,ISGYENQ_kSYSTEM
         MVI   RESTABLE+ISGYENQRESSCOPE-ISGYENQRES+ISGYENQRES_LEN,ISGYEx
               NQ_kSYSTEM
Do_Enqueue_2 DS 0H
         ISGENQ REQUEST=OBTAIN,                                        x
               COND=YES,                                               x
               ENQTOKENTBL=ENQT,                                       x
               MF=(E,(1),COMPLETE),                                    x
               NUMRES=2,                                               x
               RESLIST=YES,                                            x
               RESTABLE=RESTABLE,                                      x
               RETCODE=RETCODE,                                        x
               RETURNTABLE=RETURNTABLE,                                x
               RSNCODE=RSNCODE
*        J     Do_Enqueue_R
Do_Enqueue_R DS 0H
         LMG   R2_64,R10_64,TempRegs+2*8
         BR    R14_32
Do_Dequeue  DS    0H
         SLR   R15_32,R15_32      Say DEQ succeeded.
         TM    OnOFF,Enqueue      Did we do an ENQ?
         JNO   DO_RETURN          No
         STMG  R2_64,R10_64,TempRegs+2*8
         LA    R1_32,CALLX
         ISGENQ REQUEST=RELEASE,                                       x
               COND=YES,                                               x
               ENQTOKENTBL=ENQT,                                       x
               MF=(E,(1),COMPLETE),                                    x
               NUMRES=2,                                               x
               RESLIST=YES,                                            x
               RETCODE=RETCODE,                                        x
               RETURNTABLE=RETURNTABLE,                                x
               RSNCODE=RSNCODE
         LMG   R2_64,R10_64,TempRegs+2*8
         BR    R14_32
STDIN    DC    F'0'
STDOUT   DC    F'1'
STDERR   DC    F'2'
*nameLEN DC    F'12'              Length of RNAME for SPFEDIT enq
ALET     DC    A(0)
IOV_ALET EQU   ALET
IOV_BUFFER_ALET EQU ALET
CEE3INF  DC    V(CEE3INF)
#PRINTF  DC    V(SPRINTF)
CEE3DMP  DC    V(CEE3DMP)
RESTABLEI DC   CL8'SPFEDIT'       QNAME
         DC    AD(0)              64-BIT RNAME ADDR
         DC    F'0'               RNAME ALET
         DC    A(0)               UCB@
         DC    AL1(RnameLEN)
         DC    AL1(ISGYENQ_kSYSTEMS)
         DC    AL1(ISGYENQ_kCONTROLEXCLUSIVE)
         DC    X'00'              FLAGS
         DC    XL4'00000000'      RESERVED
         DC    CL8'SPFEDIT'       QNAME
         DC    AD(0)              64-BIT RNAME ADDR
         DC    F'0'               RNAME ALET
         DC    A(0)               UCB@
         DC    AL1(RnameLEN)
         DC    AL1(ISGYENQ_kSYSTEMS)
         DC    AL1(ISGYENQ_kCONTROLEXCLUSIVE)
         DC    X'00'              FLAGS
         DC    XL4'00000000'      RESERVED
TAB      DC    X'05'
NL       DC    X'15'
TITLE    DC    CL80'mvUl DUMP'
DOPTIONS DC    CL255'BLOCKS,STORAGE,REGST(256),GENOPTS'
initOnOFF DC   X'80'
TOUPPER  DC    256AL1(*-TOUPPER)
         ORG   TOUPPER+c'a'
         DC    C'ABCDEFGHI'
         ORG   TOUPPER+c'j'
         DC    C'JKLMNOPQR'
         ORG   TOUPPER+c's'
         DC    C'STUVWXYZ'
         ORG
TOlower  DC    256AL1(*-TOlower)
         ORG   TOlower+c'A'
         DC    C'abcdefghi'
         ORG   TOlower+c'J'
         DC    C'jklmnopqr'
         ORG   TOlower+c'S'
         DC    C'sturvxyz'
         ORG
         LTORG *
MSG1     DC    C'Invalid option:'
MSG1L    equ   *-MSG1
HELPMSG  DC    C'mvUl renames one or more files.&NL.'
 DC C'It translates all UPPER case letters in the '
 DC C'file name to lower case, by default.&NL.'
 DC C'If invoked as "mvlU", it reverses this function. That is, '
 DC C'it translates all lower case letters to UPPER case.&NL.'
 DC C'-v:Verbose: display the old and new name, similar to mv -v. '
 DC C'(default)&NL.'
 DC C'-q:Quiet: Do not display normal messages, only errors.&NL.'
 DC C'-s:Silent: Same as -q.&NL.'
 DC C'-f:Force: the rename even if the new name already exists. '
 DC C'(default)&NL.'
 DC C'-i:Inquire: ask permission of the user to rename the file '
 DC C'when the new name already exists.&NL.'
 DC C'-l:Lower: translate UPPER case in the nameto lower case '
 DC C'(default for mvUl).&NL.'
 DC C'-U:Upper: translate lower case in the name to UPPER case '
 DC C'(default for mvlU).&NL.'
 DC C'-e:Enqueue: Issue SPFEDIT enqueues on both the from "from" '
 DC C'and "to" names.&NL.'
 DC C'-E:Enqueue: Do NOT issue an enqueue of SPFEDIT on the '
 DC C'"from" and "to" names. (default)&NL.'
 DC C'-d:Debug: Display debugging information on stderr.&NL.'
 DC C'-D:Debug: Do not display debugging information (default).&NL.'
 DC C'Options may be interspersed with arguments (file names).&NL.'
 DC C'This allows different options for different arguments.&NL.'
 DC C'An option is active from the time it is specified until '
 DC C'it is changed.&NL.'
 DC C'-?: display this help information. Displayed at most once.&NL.'
 DC C'-h: display this help information. Displayed at most once.&NL.'
LHELPMSG EQU  *-HELPMSG
mvUl_PPA CEEPPA LIBRARY=NO,                                            x
               PPA2=YES,                                               x
               EXTPROC=YES,                                            x
               TSTAMP=YES,                                             x
               PEP=YES,                                                x
               INSTOP=YES,                                             x
               EXITDSA=NO,                                             x
               OWNEXM=YES,                                             x
               EPNAME=mvUl,                                            x
               VER=1,                                                  x
               REL=1,                                                  x
               MOD=0,                                                  x
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
         DS    0D                 FORCE DOUBLEWORD
PathLength DS  F
@VERBOSE DS    A
@DUMPRET DS    A
IOV@     DS    A                  IOV STRUCTURE ADDRESS
IOVL     DS    F                  IOV STRUCTURE SIZE IN BYTES
BPX1WRT@ DC    A(0)               DYNAMICALLY LOADED
BPX1WRV@ DC    A(0)               DYNAMICALLY LOADED
BPX1WRT  DC    A(0)               DYNAMICALLY LOADED
BPX1WRV  DC    A(0)               DYNAMICALLY LOADED
BPX1REN  DC    A(0)               DYNAMICALLY LOADED
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
CEETERM_BLOCK CEETERM MF=L
CALLX    DS    (ISGENQL)D
IOV_COUNT DS   F
SPFenqTo DS    3F                 Inode || Devnode || OextSysplexActv
SPFenqFrom DS  3F                 Inode || Devnode || OextSysplexActv
IOV_STRUC DS   0D
         DS    (16*8)A            ROOM FOR 16 ADDRESS / LENGTH PAIRS
IOV_STRUC_L EQU *-IOV_STRUC
IOV_STRUC_N EQU IOV_STRUC_L/8
         ORG   IOV_STRUC
TempRegs DS    16D       Rooom to save all 16 64-bit General Registers
RESTABLE DS    2CL(ISGYENQRES_LEN)
RETURNTABLE DS 2CL(ISGYENQRETURN_LEN)
ENQT     DS    2CL(ISGYENQTOKEN_LEN)
         ORG
OnOFF    DS    X'00'
Ul       equ   x'80'            on => UPPER 2 lower, else lower 2 UPPER
UlX      equ   x'ff'-Ul
* default = on. -l will turn OFF. -U turns on
Verbose  equ   x'40'              -v (verbose) specified
VerboseX equ   x'ff'-Verbose
* default = off. -v turns ON. -q or -s turns OFF
Inquire  equ   x'20'              -i (inquire) about overwrite
InquireX equ   x'ff'-Inquire
* default = off. -i turns ON. -f turns OFF
Enqueue  equ   x'10'
EnqueueX equ   x'ff'-Enqueue
* default = off. -e turns ON. -E turns OFF.
Debug    equ   x'08'
DebugX   equ   x'ff'-Debug
* default = off. -d turns ON. -D turns OFF.
Hopt     equ   x'02'              Help already displayed
Eopts    equ   x'01'              no more options
* default = off. -- turns ON. cannot be turned off
*         indicates that - no longer indicates an option
NewName  ds    cl255              max path name length
DSASIZE  EQU   *-CEEDSA
         BPXYCONS DSECT=YES,LIST=YES
         BPXYIOV
         ISGYCON
         ISGYENQ
         CVT   DSECT=YES,LIST=NO
         IHAECVT
         BPXYOEXT
         BPXYERNO LIST=YES
         CEECAA
ISGENQ_DSECT DSECT
         ISGENQ MF=(L,ISGENQ)
PARMS    DSECT
@ARGC    DS    A                  ADDRESS OF NUMBER OF ARGUMENTS
@ARGVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF ARGS
@ARGV    DS    A                  ADDRESS OF VECTOR OF ARGS
@ENVL    DS    A                  ADDRESS OF NUMBER OF ENV VARS
@ENVVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF ENV VA
@ENV     DS    A                  ADDRESS OF VECTOR OF ENV VARS
         regs
         END   mvUl
