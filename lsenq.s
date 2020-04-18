*PROCESS ALIGN,NOCOMPAT,
*PROCESS DXREF,FLAG(ALIGN,CONT,RECORD)
*PROCESS NOFOLD,NOINFO,PC(ON,DATA,GEN,MCALL),RENT,
*PROCESS RA2,NORLD,MXREF,RXREF,USING(MAP,WARN(13))
*PROCESS TYPECHECK(NOMAGNITUDE,REGISTER)
*WARNING - THIS PROGRAM REQUIRES THE HIGH-LEVEL ASSEMBLER
*          AS WELL AS LE/370
*          THIS PROGRAM IS RE-ENTRANT.
         AGO   .SKIP2
         MACRO
&LBL     _LA  &OP1,&OP2
         AIF   ('&OP2'(1,1) EQ '!').LARL
&LBL     LA   &OP1,&OP2
         MEXIT
.LARL    ANOP
         LCLA  &K
         LCLC  &OP2X
&K       SETA  K'&OP2
&K       SETA  &K-1
&OP2X    SETC  '&OP2'(2,&K)
&LBL     LARL  &OP1,&OP2X
         MEND
_LA      OPSYN LA
*LA       OPSYN _LA
         MACRO
&LBL     LONGDISP &INST
_&INST   OPSYN &INST
&INST    OPSYN &INST.Y
         MEND
.SKIP2   ANOP
         PUSH  PRINT
         LCLC  &NL,&TAB
&NL      SETC  BYTE(21)
&TAB     SETC  BYTE(05)
&NULL    SETC  BYTE(00)
         PRINT GEN
         MNOTE *,'SYSOPT_OPTABLE=&SYSOPT_OPTABLE'
         SYSSTATE ASCENV=P,
               AMODE64=NO,
               ARCHLVL=2
         IEABRCX DEFINE
         IEABRCX DISABLE
         IEABRCX ENABLE
_BALR    OPSYN BALR
BALR     OPSYN BASR
_CSECT   OPSYN CSECT
CSECT    OPSYN RSECT
         POP   PRINT
LSENQ    CEEENTRY PPA=LSENQ_PPA,
               MAIN=YES,
               AUTO=DSASIZE,
               BASE=R11_32
         USING CEECAA,R12_32
         USING CEEDSA,R13_32
         J     GO
GOBACK   DS    0H
         CEETERM RC=RETURN_CODE,
               MODIFIER=MODIFIER,
               MF=(E,CEETERM_BLOCK)
         LTORG
GO       DS    0H
         LR    R9_32,R1_32        SAVE R1 UPON ENTRY
         USING PARMS,R9_32
         LARL  R15_32,DO_DOT
         ST    R15_32,ENCODE@
         LA    R1_32,CALLX
         L     R15_32,CEE3INF
         CALL  (15),(SYS,ENV,MEMBER,GPID,FC),VL,
               MF=(E,(1)),LINKINST=BASR
         LHI   R15_32,1
         ST    R15_32,MODIFIER
         LHI   R7_32,16
         TM    SYS,X'02'          UNIX?
         JNO   INITERR            NO
         LOAD  EP=BPX1WRT
         ST    R0_32,BPX1WRT
         LOAD  EP=BPX1WRV
         ST    R0_32,BPX1WRV
         MVC   GQLST(GQPARML),GQPARM
         LARL  R0_32,TAB          point to default tab
         ST    R0_32,TAB@         save address
         LHI   R0_32,1            length of default seperator
         ST    R0_32,TABL         save length
         BCTR  R7_32,0            15
         L     R2_32,@ARGC        &NUMBER OF ARGUMENTS
         L     R3_32,@ARGVL       &LENGTH OF ARGUMENTS
         L     R4_32,@ARGV        &VALUE OF ARGUMENTS
         ST    R2_32,MODIFIER
         L     R2_32,0(,R2_32)    get number of arguments
         CHI   R2_32,2            AT LEAST 2 ARGUMENTS?
         LHI   R7_32,15
         JL    IShelp             NO, output help info
         XC    QNAME@,QNAME@      ZERO OUT QNAME ADDRESS
         MVC   QNAMEL,QNAME@      AND LENGTH
         MVC   RNAMEL,QNAME@      ZERO OUT RNAME LENGTH
         MVC   RNAME@,QNAME@      AND ADDRESS
*
* PROCESS ARGUMENTS
         BCTR  R2_32,0            DON'T BOTHER counting ARGV[0]
         LA    R3_32,4(,R3_32)    nor its length
         LA    R4_32,4(,R4_32)    nor its address
ARGLP    DS    0H
         L     R5_32,0(,R3_32)    &LENGTH
         L     R6_32,0(,R4_32)    &VALUE
         LT    R5_32,0(,R5_32)    LENGTH
         JZ    ARGNEXT            Ignore NULL parameters
         TM    ONOFF,X'40'        -- SEEN ALREADY?
         JO    NOTOPT             YES, - NO LONGER INDICATES OPTION
         CLI   0(R6_32),C'-'      OPTION?
         JE    IS_OPTION
NOTOPT   DS    0H
         CLC   RNAME@,=A(0)
         JZ    MBRNAME
         CLC   QNAME@,=A(0)
         JNZ   ERROR2             TOO MANY ARGUMENTS
         MVC   QNAME@,RNAME@
         MVC   QNAMEL,RNAMEL
         J     MBRNAME
         XC    RNAME@,RNAME@      ZERO RNAME ADDRESS
         MVC   RNAMEL,RNAME@      AND LENGTH
         J     ARGNEXT
ERROR2   DS    0H
         MVC   BUFFERA,=A(PARMSGT2)
         LHI   R5_32,LPARMSGT2
         ST    R5_32,COUNT
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDERR,BUFFERA,ALET,COUNT,
               RETVAL,
               RETCODE,
               RSNCODE),VL,
               MF=(E,(1)),LINKINST=BASR
         LHI   R7_32,14
         J     INITERR
IS_OPTION DS   0H
         CHI   R5_32,2 ONLY A DASH?
         JE    BADOPT             MUST BE
         CLI   1(R6_32),C'o'      OCTAL?
         JE    MBOCTAL
         CLI   1(R6_32),C'h'      HEXADECIMAN?
         JE    MBHEX
         CLI   1(R6_32),C'd'      Debug output?
         JE    MBdbug
         CLI   1(R6_32),C'-'      End of options?
         JE    MBeopts
         CLI   1(R6_32),C't'      Change field separator?
         JE    MBtabchar
         CLI   1(R6_32),C'?'      Help ?
         JE    MBhelp
         J     BADOPT
MBtabchar DS   0H
         CHI   R5_32,3            Separator text in argument?
         JNH   TSTNextArg         no check next arg
         AHI   R5_32,-3           Decrement length
         ST    R5_32,TABL         Save as length
         LA    R1_32,2(,R6_32)    Get address of next char
         ST    R1_32,TAB@         Save as separator
         J     ARGNEXT
TSTNextArg DS  0h
         CHI   R2_32,1            Was this the last argument?
         JE    ARGEND             Yes, well, ain't that a kick?
         LA    R5_32,4(,R3_32)    Point to next length
         LA    R6_32,4(,R4_32)    Point to next value address
         L     R6_32,0(,R6_32)    Load addr of next value
         LT    R5_32,0(,R5_32)    Load addr of length
         JZ    TSTIgn             IGNORE NULL Address
         LT    R5_32,0(,R5_32)    Load length
         JZ    TSTIgn             IGNORE NULL
         CLI   0(R6_32),C'-' DASH?
         JE    ARGNEXT
         BCTR  R5_32,0
         ST    R5_32,TABL
         ST    R6_32,TAB@
*
* absorb the argument I just stole
TSTIgn   DS    0H
         LA    R3_32,4(,R3_32)
         LA    R4_32,4(,R4_32)
         BRCT  R2_32,ARGNEXT
         J     ARGEND             I used up the last argument
MBhelp   DS    0H
         CHI   R5_32,3
         JNE   BADOPT
IShelp   DS    0H
         MVC   BUFFERA,=A(HELPMSG)
         LHI   R5_32,LHELPMSG
         ST    R5_32,COUNT
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDERR,BUFFERA,ALET,COUNT,
               RETVAL,
               RETCODE,
               RSNCODE),VL,
               MF=(E,(1)),LINKINST=BASR
         MVC   RETURN_CODE,=F'1'
         L     R1_32,@ARGC
         L     R1_32,0(,R1_32)
         CHI   R1_32,2
         JNH   GOBACK             No parms at all
ERROR4   DS    0H
         MVC   BUFFERA,=A(PARMSbd4)
         LHI   R5_32,LPARMSbd4
         ST    R5_32,COUNT
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDERR,BUFFERA,ALET,COUNT,
               RETVAL,
               RETCODE,
               RSNCODE),VL,
               MF=(E,(1)),LINKINST=BASR
         LHI   R7_32,13
         J     INITERR
MBeopts  ds    0h
         CHI   R5_32,3
         JNE   BADOPT
         OI    ONOFF,X'40'
         J     ARGNEXT
MBdbug   DS    0H
         CHI   R5_32,3
         JNE   BADOPT
         OI    ONOFF,X'80'
         J     ARGNEXT
MBOCTAL  DS    0H
         CHI   R5_32,3
         JNE   BADOPT
         LARL  R15_32,DO_OCTAL
         ST    R15_32,ENCODE@
         J     ARGNEXT
MBHEX    DS    0H
         CHI   R5_32,3
         JNE   BADOPT
         LARL  R15_32,DO_HEX
         ST    R15_32,ENCODE@
         J     ARGNEXT
BADOPT   DS    0H
         LARL  R0_32,OPTMSG1
         LHI   R1_32,OPTMSG1L
         STM   R0_32,R1_32,FIELD1@
         XC    TAB1(8),TAB1
         ST    R5_32,FIELD2L
         ST    R6_32,FIELD2@
         LM    R0_32,R1_32,=A(NL,1)
         STM   R0_32,R1_32,TAB2
         LHI   R0_32,4
         ST    R0_32,IOV_COUNT
         LA    R1_32,CALLX
         L     R15_32,BPX1WRV
         CALL  (15),
               (STDERR,IOV_COUNT,IOV_STRUC,
               IOV_ALET,IOV_BUFFER_ALET,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1)),LINKINST=BASR
         LHI   R7_32,12
         J     ARGNEXT
MBRNAME  DS    0H
         ST    R5_32,RNAMEL
         ST    R6_32,RNAME@
ARGNEXT  DS    0H
         LA    R3_32,4(,R3_32)
         LA    R4_32,4(,R4_32)
         BRCT  R2_32,ARGLP
ARGEND   DS    0H
* END OF ARGUMENT LOOP
*
         LA    R0_32,QNAME@
         CLC   RNAME@,=A(0)
         JNZ   DOQNAME
         MVC   BUFFERA,=A(PARMSLT2)
         LHI   R5_32,LPARMSLT2
         ST    R5_32,COUNT
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDERR,BUFFERA,ALET,COUNT,
               RETVAL,
               RETCODE,
               RSNCODE),VL,
               MF=(E,(1)),LINKINST=BASR
         LHI   R7_32,11
         J     INITERR
DOQNAME  DS    0H
         LT    R5_32,QNAMEL       QNAME specified?
         JNZ   GOTQNAME           Yes
*
* INITIAIZE QNAME TO DEFAULT OF SYSDSN
         LARL  R0_32,SYSDSN
         ST    R0_32,QNAME@
         LHI   R0_32,1+L'SYSDSN
         ST    R0_32,QNAMEL
*
         LR    R5_32,R0_32
GOTQNAME DS    0H
         L     R6_32,QNAME@
         AHI   R5_32,-2           DEC BY 1 FOR TRAILING 0x00 AND
*                                 ANOTHER 1 FOR EX
         MVC   QNAME,=CL8' '
         EX    R5_32,CP_QNAME
DORNAME  DS    0H
         L     R5_32,RNAMEL
         BCTR  R5_32,0            IGNORE TRAILING 0x00
         L     R6_32,RNAME@
         CHI   R5_32,255          CHECK AGAINST MAX LENGTH
         JNH   RLENOK             TOO LONG
ERROR3   DS    0H
         MVC   BUFFERA,=A(PARMSGT3)
         LHI   R5_32,LPARMSGT3
         ST    R5_32,COUNT
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDERR,BUFFERA,ALET,COUNT,
               RETVAL,
               RETCODE,
               RSNCODE),VL,
               MF=(E,(1)),LINKINST=BASR
         LHI   R7_32,10
         J     INITERR
RLENOK   DS    0H
         BCTR  R7_32,0            7
         ST    R5_32,RNAME_LEN
         BCTR  R5_32,0            DECREMENT BY 1
         EX    R5_32,CP_RNAME
*
* FOR CONVIENCE, I WILL FORCE RNAMES TO UPPER CASE IF
* THE QNAME IS DEFAULTED TO SYSDSN
         CLC   QNAME,=CL8'SYSDSN'
         JNE   OK1
         L     R5_32,RNAME_LEN
         BCTR  R5_32,0
         EX    R5_32,TR_RNAME
OK1      DS    0H
         TM    ONOFF,X'80'
         JNO   NOWRT
         LA    R8_32,QNAMEX       RECEIVING FIELD
         ST    R8_32,FIELD1@
         LHI   R9_32,8
         LA    R10_32,QNAME
*        AGO   .DOWRT1
         BRASL R14_32,DO_ENCODE
         SL    R8_32,FIELD1@
         ST    R8_32,FIELD1L
         CHI   R8_32,8*4
         JH    *+2
         L     R0_32,TAB@
         L     R1_32,TABL
         STM   R0_32,R1_32,TAB1
         LA    R8_32,RNAMEX
         ST    R8_32,FIELD2@
         L     R9_32,RNAME_LEN
         LA    R10_32,RNAME
         BRASL R14_32,DO_ENCODE
         SL    R8_32,FIELD2@
         ST    R8_32,FIELD2L
         CHI   R8_32,255*4
         JH    *+2
         LM    R0_32,R1_32,=A(NL,1)
         STM   R0_32,R1_32,TAB2
         LHI   R0_32,4
         ST    R0_32,IOV_COUNT
         LA    R1_32,CALLX
         L     R15_32,BPX1WRV
         CALL  (15),
               (STDERR,IOV_COUNT,IOV_STRUC,
               IOV_ALET,IOV_BUFFER_ALET,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1)),LINKINST=BASR
NOWRT    DS    0H
         ago   .nowrt1
.DOWRT1  ANOP
         TM    ONOFF,X'80'
         JNO   NOWRT
         ST    R0_32,BUFFERA
         MVI   QNAME+L'QNAME,C'&TAB' Place TAB in output
         MVC   QNAME+L'QNAME(1),TAB Place separator in output
         L     R5_32,RNAME_LEN
         LA    R5_32,RNAME(R5_32)
         MVI   0(R5_32),C'&NL'    Place NEL in output
         SLR   R5_32,R4_32
         AHI   R5_32,1
         ST    R5_32,COUNT
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDERR,BUFFERA,ALET,COUNT,
               RETVAL,
               RETCODE,
               RSNCODE),VL,
               MF=(E,(1)),LINKINST=BASR
NOWRT    DS    0H
         AGO   .NOWRT2
.nowrt1  anop
         L     R2_32,STORAGE_LENGTH
         STORAGE OBTAIN,
               LENGTH=(2),
               SP=10,
               BNDRY=PAGE
         ST    R1_32,RETURN@
         MVC   0(4,R1_32),STORAGE_LENGTH
*        LA    R1_32,CALLX
*        L     R15_32,ISGQUERY
*        CALL  (15),
         CEEPCALL ISGQUERY,
               (QNAME,RNAME,RNAME_LEN+3,GQLST,RETURN@),
               VL,
               MF=(E,CALLX),LINKINST=BASR
         ST    R15_32,RETURN_CODE
         LTR   R15_32,R15_32
         JZ    GOOD1
         CHI   R15_32,4           RC==4?
         JNE   ERROR1             NO
         STM   R15_32,R0_32,F_RC
*
* IF RC==4 AND MODIFIER=X'....0404' THIS MEANS
* THAT NOTHING WAS FOUND. THIS IS FINE.
         CLC   =X'0404',F_MODIFIER+2
*        CLHHSI F_MODIFIER+2,X'0404'
         JNE   ERROR1
         XC    RETURN_CODE,RETURN_CODE
         J     GOOD2
.NOWRT2  ANOP
ERROR1   DS    0H
         LA    R1_32,CALLX
         LM    R3_32,R4_32,F_RC
         L     R2_32,RETURN@
         LA    R2_32,8(,R2_32)
         ST    R2_32,BUFFERA
         L     R15_32,SPRINTF
         CALL  (15),
               ((2),FORMAT,(3),(4)),
               MF=(E,(1)),LINKINST=BASR
         ST    R15_32,COUNT
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDERR,BUFFERA,ALET,COUNT,
               RETVAL,
               RETCODE,
               RSNCODE),VL,
               MF=(E,(1)),LINKINST=BASR
GOOD2    DS    0H
         LT    R1_32,RETURN@
         JZ    GOBACK
         L     R2_32,0(,R1)
         STORAGE RELEASE,
               LENGTH=(2),
               SP=10,
               ADDR=(1)
         J     GOBACK
GOOD1    DS    0H
         L     R2_32,RETURN@
         LA    R3_32,8(,R2_32)
         USING RETURN_STRUC,R3_32
         L     R0_32,TAB@
         L     R1_32,TABL
         STM   R0_32,R1_32,TAB1
         STM   R0_32,R1_32,TAB2
         STM   R0_32,R1_32,TAB3
         STM   R0_32,R1_32,TAB4
         STM   R0_32,R1_32,TAB5
         STM   R0_32,R1_32,TAB6
         STM   R0_32,R1_32,TAB7
         STM   R0_32,R1_32,TAB8
         LM    R0_32,R1_32,=A(NL,1)
         STM   R0_32,R1_32,NL1
PRINT    DS    0H
         CL    R3_32,4(,R2_32)
         JNL   GOOD2
         LA    R8_32,QNAMEX
         ST    R8_32,FIELD1@
         LHI   R9_32,8
         LA    R10_32,RTN_QNAME
         BRASL R14_32,DO_ENCODE
         LHI   R0_32,8
         SL    R8_32,FIELD1@
         ST    R8_32,FIELD1L
         chi   r8_32,8*4
         JH    *+2
         LA    R1_32,RTN_JOBNAME
         ST    R1_32,FIELD3@
         ST    R0_32,FIELD3L
         LA    R1_32,RTN_EXCSHR
         ST    R1_32,FIELD5@
         ST    R0_32,FIELD5L
         LA    R1_32,RTN_SYSNAME
         ST    R1_32,FIELD4@
         ST    R0_32,FIELD4L
         LA    R1_32,RTN_STATUS
         ST    R1_32,FIELD6@
         ST    R0_32,FIELD6L
         LA    R1_32,RTN_SCOPE
         ST    R1_32,FIELD7@
         ST    R0_32,FIELD7L
         UNPK  D_RC(9),RTN_TCB(5)
         TR    D_RC(8),TOHEX-X'F0'
         LA    R1_32,D_RC
         ST    R1_32,FIELD8@
         ST    R0_32,FIELD8L
         UNPK  F_RC(5),RTN_ASID(3)
         TR    F_RC(4),TOHEX-X'F0'
         LA    R1_32,F_RC
         ST    R1_32,FIELD9@
         MVC   FIELD9L,=F'4'
         LA    R8_32,RNAMEX
         ST    R8_32,FIELD2@
         L     R9_32,RTN_RLEN
         LA    R10_32,RTN_RNAME
         BRASL R14_32,DO_ENCODE
         LHI   R0_32,8
         SL    R8_32,FIELD2@
         ST    R8_32,FIELD2L
         MVC   IOV_COUNT,=A(IOV_STRUC_L/8)
         L     R10_32,IOV_COUNT
         chi   r8_32,255*4
         jh    *+2
         chi   r10_32,iov_struc_l/8
         jh    *+2
         LA    R1_32,CALLX
         L     R15_32,BPX1WRV
         CALL  (15),
               (STDOUT,IOV_COUNT,IOV_STRUC,
               IOV_ALET,IOV_BUFFER_ALET,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1)),LINKINST=BASR
         LA    R3_32,RTN_NEXT
         J     PRINT
         DROP  R3
INITERR  DS    0H
         ST    R7_32,RETURN_CODE
         CHI   R7_32,16           NOT UNIX?
         JNE   BADPARMS           BAD PARMS
* I CAN'T ISSUE A MESSAGE, SO I GUESS A WTO IS NEEDED
         WTO   'LSENQ NEEDS A UNIX ENVIRONMENT',
               ROUTCDE=11,
               DESC=7
BADPARMS DS    0H
         LA    R2_32,ERRMSG1
         ST    R2_32,BUFFERA      MESSAGE HERE
         LA    R1_32,CALLX
         L     R15_32,SPRINTF
*
* Use sprintf to make a nice looking message.
         CALL  (15),
               ((2),ERRFMT1,(7)),
               MF=(E,(1))
         ST    R15_32,COUNT
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),(STDERR,BUFFERA,ALET,COUNT,
               RETVAL,
               RETCODE,
               RSNCODE),VL,
               MF=(E,(1)),LINKINST=BASR
         J     GOBACK
CONSTANTS DS   0D
         LTORG *
STORAGE_LENGTH DC A(4*1024*1024)
STDOUT   DC    F'1'
STDERR   DC    F'2'
ALET     DC    A(0)
IOV_ALET EQU   ALET
IOV_BUFFER_ALET EQU ALET
CEE3INF  DC    V(CEE3INF)
SPRINTF  DC    V(SPRINTF)
CEE3DMP  DC    V(CEE3DMP)
*ISGQUERY DC    V(ISGQUERY)
CP_QNAME MVC   QNAME(0),0(R6_32)
CP_RNAME MVC   RNAME(0),0(R6_32)
TR_RNAME TR    RNAME(0),TOUPPER
FORMAT   DC    C'ISGQUERY Return code=%i Modifier=%#8x',X'1500'
         DS    0H
ERRFMT1  DC    C'LSENQ Parameter error. code=%i',X'1500'
         DS    0H                 Align to HalfWord because TAB is
*                                 accessed via LARL as is SYSDSN
TAB      DC    C'&TAB'
NL       DC    C'&NL'           Doubles as alignment padding for SYSDSN
SYSDSN   DC    CL6'SYSDSN',X'00'
TITLE    DC    CL80'LSENQ DUMP'
OPTIONS  DC    CL255'BLOCKS,STORAGE,REGST(256),GENOPTS'
TOUPPER  DC    256AL1(*-TOUPPER)
         ORG   TOUPPER+X'81'
         DC    C'ABCDEFGHI'
         ORG   TOUPPER+X'91'
         DC    C'JKLMNOPQR'
         ORG   TOUPPER+X'A2'
         DC    C'STUVWXYZ'
         ORG
TOHEX    DC    C'0123456789ABCDEF'
         DS    0D
PRNTABLE PRNTABLE abcdefghijklmnopqrstuvwxyz
PRNTABLE PRNTABLE ABCDEFGHIJKLMNOPQRSTUVWXYZ
PRNTABLE PRNTABLE 0123456789
PRNTABLE PRNTABLE `~!@#$%µ*()_+-=
PRNTABLE PRNTABLE []\{}|;"./<>?
         ORG   PRNTABLE+C' '
         DC    C' '
         ORG   PRNTABLE+C','
         DC    C','
         ORG   PRNTABLE+C''''
         DC    C''''
         ORG   PRNTABLE+C'&&'
         DC    C'&&'
         ORG
         ISGQUERY MF=(L,GQPARM)
         DS    0H
OPTMSG1  DC    C'Unknown option:'
OPTMSG1L EQU   *-OPTMSG1
PARMSGT2 DC    C'More than 2 non-option parameters specified.&NL'
LPARMSGT2 EQU  *-PARMSGT2
PARMSGT3 DC    C'RNAME length exceeds 255 characters.&NL.'
LPARMSGT3 EQU  *-PARMSGT3
PARMSbd4 DC    C'&NL.-? specified. Other arguments ignored.&NL.'
LPARMSbd4 EQU  *-PARMSbd4
PARMSLT2 DC    C'Insuffient number of parameters. No RNAME '
         DC    C'found.&NL'
LPARMSLT2 EQU  *-PARMSLT2
HELPMSG  DC    C'lsenq lists enqueue information.&NL.'
         DC    C'-d requests "debugging" output.&NL.'
 DC C'-h requests nondisplay characters be output in hexadecimal.&NL.'
 DC C'-o requests nondisplay characters be output in octal.&NL.'
 DC C'   if neither, nondisplay characters will be replaced with a '
 DC C'dot.&NL.'
 DC C'-t specifies the field separator character(s).&NL.'
 DC C'   if not specified, it defaults to a tab.&NL.'
 DC C'-- forces subsequent arguments to not be intepreted '
 DC C'as options, but as data.&NL.'
 DC C'-? display this help information.&NL.'
LHELPMSG EQU  *-HELPMSG
E_CONSTANTS EQU *
         PUSH  USING
         DROP  R11_32
DO_ENCODE DS   0H
         L     R15_32,ENCODE@
         BR    R15_32
DO_DOT   DS    0H
         STM   R14_32,R12_32,12(R13_32)
         CHI   R9_32,255
         LARL  R1_32,PRNTABLE     POINT TO PRINT TABLE
         SLR   R0_32,R0_32        TEST CHAR IS X'00'
D_TROO   TROO  R8_32,R10_32       MOVE AND TEST
         JO    D_TROO             LOOP ON CC=3
         JE    D_TROOE            FINISHED!
*
* TRANSLATE TO A PERIOD
         MVI   0(R8_32),C'.'
         LA    R10_32,1(,R10_32)
         LA    R8_32,1(,R8_32)
         LARL  R1_32,PRNTABLE
         BCTR  R9_32,0
         LTR   R9_32,R9_32
         JP    D_TROO
D_TROOE  DS    0H
         ST    R8_32,8*4+20(,R13_32)
         LM    R14_32,R12_32,12(R13_32)
         BR    R14_32
DO_HEX   DS    0H
         BASR  R15_32,0
         USING (*,E_DO_HEX),R15_32
         STM   R14_32,R12_32,12(R13_32)
         CHI   R9_32,255
         LARL  R1_32,PRNTABLE     POINT TO PRINT TABLE
         SLR   R0_32,R0_32        TEST CHAR IS X'00'
H_TROO   TROO  R8_32,R10_32 0     MOVE AND TEST
         JO    H_TROO             LOOP ON CC=3
         JE    H_TROOE            FINISHED!
*
* TRANSLATE TO HEXADECIMAL
         MVC   0(3,R8_32),=C'\0x'
         SLR   R3_32,R3_32
         UNPK  3(3,R8_32),0(2,R10_32)
         LARL  R1_32,CONSTANTS
         USING (CONSTANTS,E_CONSTANTS),R1_32
         TR    3(2,R8_32),TOHEX-240
         DROP  R1_32
         LA    R10_32,1(,R10_32)
         LA    R8_32,5(,R8_32)
         LARL  R1_32,PRNTABLE
         BCTR  R9_32,0
         LTR   R9_32,R9_32
         JP    H_TROO
H_TROOE  DS    0H
         ST    R8_32,8*4+20(,R13_32)
         LM    R14_32,R12_32,12(R13_32)
         BR    R14_32
         LTORG *
E_DO_HEX DS    0H
         DROP  R15_32
DO_OCTAL DS    0H
         STM   R14_32,R12_32,12(R13_32)
         CHI   R9_32,255
         LARL  R1_32,PRNTABLE     POINT TO PRINT TABLE
         SLR   R0_32,R0_32        TEST CHAR IS X'00'
O_TROO   TROO  R8_32,R10_32 0     MOVE AND TEST
         JO    O_TROO             LOOP ON CC=3
         JE    O_TROOE            FINISHED!
*
* TRANSLATE TO OCTAL
         SLR   R3_32,R3_32
         IC    R3_32,0(,R10_32)   LOAD BYTE
         MVI   0(R8_32),C'\'      PLACE ESCAPE CHAR IN OUTPUT
         STC   R3_32,3(,R8_32)
         NI    3(R8_32),X'07'
         OI    3(R8_32),X'F0'
         SRL   R3_32,3
         STC   R3_32,2(,R8_32)
         NI    2(R8_32),X'07'
         OI    2(R8_32),X'F0'
         SRL   R3_32,3
         STC   R3_32,1(,R8_32)
         NI    1(R8_32),X'07'
         OI    1(R8_32),X'F0'
         LA    R10_32,1(,R10_32)
         LA    R8_32,4(,R8_32)
         LARL  R1_32,PRNTABLE
         BCTR  R9_32,0
         LTR   R9_32,R9_32
         JP    O_TROO
O_TROOE  DS    0H
         ST    R8_32,8*4+20(,R13_32)
         LM    R14_32,R12_32,12(R13_32)
         BR    R14_32
         POP   USING
LSENQ_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=LSENQ,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
         DS    0D                 FORCE DOUBLEWORD
QNAME@   DS    A
QNAMEL   DS    F
RNAME@   DS    A
RNAMEL   DS    F
NL_CATD  DS    A
ENCODE@  DS    A
D_RC     DS    D
D_MODIFIER DS  D
F_RC     DS    F
F_MODIFIER DS  F
RETURN@  DS    A
GQLST    DS    (GQPARML)X
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
FC       DS    F
BUFL     DS    F
RETURN_CODE DS F
MODIFIER DS    F
RETURN_VALUE DC A(0)               PREVIOUS DEFAULT DUB
REASON_CODE DC A(0)
CEETERM_BLOCK CEETERM MF=L
CALLX    DS    30A
IOV_COUNT DS   F
RNAME_LEN DS   F
TAB@     DS    A
TABL     DS    F
QNAME    DS    CL8
RNAME    DS    CL255
QNAMEX   DS    6CL(L'QNAME)
RNAMEX   DS    6CL(L'RNAME)
         ORG   QNAME
ERRMSG1  DS    CL(20+L'ERRFMT1)
         ORG
IOV_STRUC DS   0D
FIELD1@  DS    A
FIELD1L  DS    F
TAB1     DS    2F
FIELD2@  DS    A
FIELD2L  DS    F
TAB2     DS    2F
FIELD3@  DS    A
FIELD3L  DS    F
TAB3     DS    2F
FIELD4@  DS    A
FIELD4L  DS    F
TAB4     DS    2F
FIELD5@  DS    A
FIELD5L  DS    F
TAB5     DS    2F
FIELD6@  DS    A
FIELD6L  DS    F
TAB6     DS    2F
FIELD7@  DS    A
FIELD7L  DS    F
TAB7     DS    2F
FIELD8@  DS    A
FIELD8L  DS    F
TAB8     DS    2F
FIELD9@  DS    A
FIELD9L  DS    F
NL1      DS    2F
IOV_STRUC_L EQU *-IOV_STRUC
ONOFF    DS    X
DSASIZE  EQU   *-CEEDSA
         BPXYCONS DSECT=YES,LIST=YES
         BPXYERNO LIST=YES
         BPXYIOV
         CEECAA
         ISGYQUAA
         ISGYCON
         ISGRNLE
PARMS    DSECT
@ARGC    DS    A                  ADDRESS OF NUMBER OF ARGUMENTS
@ARGVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF ARGS
@ARGV    DS    A                  ADDRESS OF VECTOR OF ARGS
@ENVL    DS    A                  ADDRESS OF NUMBER OF ENV VARS
@ENVVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF ENV VA
@ENV     DS    A                  ADDRESS OF VECTOR OF ENV VARS
RETURN_STRUC DSECT
RTN_QNAME DS   CL8                ISGYQUAARSQNAME
RTN_JOBNAME DS CL8                ISGYQUAARQXJOBNAME
RTN_RLEN DS    F                  ISGYQUAARSRNAMELEN
RTN_SYSNAME DS CL8                ISGYQUAARQXSYSNAME
RTN_EXCSHR DS  CL8                ISGYQUAARQFLAGS1
*ISGYQUAARQCONTROL EQ X'80'       ON-SHARED
*ISGYQUAARQOWNER   EQ X'08'
*ISGYQUAARQMATU    EQ X'04'
RTN_STATUS DS  CL8
RTN_SCOPE  DS  CL8                ISGYQUAARSSCOPE
* ISGYQUAA_KSTEP
* ISGYQUAA_KSYSTEM
* ISGYQUAA_KSYSPLEX
RTN_TCB  DS    A
RTN_ASID DS    H
RTN_RNAME DS   CL255
RTN_NEXT EQU   *
RTN_LEN  EQU   *-RTN_QNAME
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
         END   LSENQ
