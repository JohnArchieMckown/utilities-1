*PROCESS ALIGN,NOCOMPAT,DXREF,FLAG(ALIGN,CONT,RECORD)
*PROCESS NOFOLD,NOINFO,PC(ON,DATA,GEN,MCALL),RENT,
*PROCESS RA2,NORLD,MXREF(FULL),RXREF,USING(MAP,WARN(13))
*PROCESS TYPECHECK(NOMAGNITUDE,REGISTER),XREF(FULL)
*WARNING - THIS PROGRAM REQUIRES THE HIGH-LEVEL ASSEMBLER
*          AS WELL AS LE/370
*          THIS PROGRAM IS RE-ENTRANT.
*THIS PROGRAM REQUIRES THE FLOWASM HLASM EXIT TO ASSEMBLE
*UNLESS YOU REFORMAT IT TO NORMAL STANDARDS
         PUSH  PRINT
         PRINT NOGEN
&NL      SETC  BYTE(21)
&TAB     SETC  BYTE(05)
&NULL    SETC  BYTE(00)
BUFSIZE  EQU   2048               STDIN buffer size, max
         IEABRCX DEFINE
*        IEABRCX DISABLE
         IEABRCX ENABLE
_BALR    OPSYN BALR
BALR     OPSYN BASR
         POP   PRINT
         SYSSTATE ASCENV=P,
               AMODE64=NO,
               ARCHLVL=2
AMS      CEEENTRY PPA=AMS_PPA,
               MAIN=YES,
               AUTO=DSASIZE,
               BASE=R11_32
         USING CEECAA,R12_32
         USING CEEDSA,R13_32
         DROP  R11_32
         USING (AMS,CONSTANTS-1),R11_32
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
         LA    R1_32,CEETERM_BLOCK
         CEETERM RC=RETURN_CODE,
               MF=(E,(1))
         LTORG *
GO       DS    0H
         LARL  R10_32,CONSTANTS
         USING CONSTANTS,R10_32
         ST    R10_32,@CONSTANTS
         ST    R1_32,@PARMS
         LA    R1_32,CALLX
         L     R15_32,CEE3INF
         CALL  (15),(SYS,ENV,MEMBER,GPID,FC),VL,
               MF=(E,(1))
         TM    SYS,X'02'          UNIX?
         JNO   GOBACK             NO
*        LA    R1_32,CALLX
*        LINK  EP=BPX1ITY,
*              PARAM=(STDIN,ISTTY),
*              VL=1,
*              MF=(E,(1))
         XC    BYTES_LEFT,BYTES_LEFT
         XC    RECNO,RECNO
         XC    EOF_SW,EOF_SW
         LA    R1_32,INBUFFER BUFSIZE
         ST    R1_32,BUFFERO
         MVC   IOLIST(IOLISTL),IOLISTI
         MVC   FDIN,STDIN         Initialize input file descriptor
         MVC   FDOUT,STDOUT       Initialize output file descriptor
         MVC   FDERR,STDERR       Initialize error file descriptor
         ST    R13_32,IOLIST+12     SYSIN's User Data
         ST    R13_32,IOLIST+24     SYSPRINT's User Data
         LOAD  EP=BPX1RED
         ST    R0_32,BPX1RED
         LOAD  EP=BPX1WRT
         ST    R0_32,BPX1WRT
         LOAD  EP=BPX1WRV
         ST    R0_32,BPX1WRV
         XC    ECB,ECB
         LA    R1_32,CALLX
         MVC   ATTACHX(LATTACHI),ATTACHI
         ATTACHX EP=IDCAMS,
               PARAM=(IDCAMSPRM,DDNAMES,PAGELIST,IOLIST),
               ECB=ECB,
               VL=1,
               SF=(E,ATTACHX),
               MF=(E,CALLX)
         LTR   R15_32,R15_32
         JNZ   ATTACH_FAILED
         ST    R1_32,TCBA
         LA    R1_32,ECB
         WAIT  ECB=(1)
         DETACH TCBA
         MVC   RETURN_CODE,ECB
         MVI   RETURN_CODE,0      ZERO JUNK IN HIGH BYTE
         XC    MODIFIER,MODIFIER
         J     GOBACK
ATTACH_FAILED DS 0H
         LA    R1_32,MSGAREA
         ST    R1_32,CALLX+0
         ST    R1_32,BUFFERA
         LARL  R1_32,ATTACH_MSG
         ST    R1_32,CALLX+4
         ST    R15_32,CALLX+8
         LA    R1_32,CALLX
         L     R15_32,SPRINTF
         BASR  R14_32,R15_32
         ST    R15_32,COUNT
         L     R15_32,BPX1WRT
         LA    R1_32,CALLX
         CALL  (15),
               (FDERR,BUFFERA,ALET,COUNT,
               RETURN_VALUE,
               RETURN_CODE,
               REASON_CODE),VL,
               MF=(E,(1))
         LA    R0_32,1
         ST    R0_32,RETURN_CODE
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
         DROP  R13_32
         DROP  R11_32
         DROP  R10_32
SYSIN_EXIT SAVE  (14,12),,'SYSIN EXIT'
         LM    R9_32,R11_32,0(R1_32)
*
* R9_32 is the User Data area, which is primed with the
*       CEEDSA address
* R10_32 is the IDFLAGS from IDCAMS
* R11_32 is the IOINFO
*  When R10_32 -> x'08', this is two words
*  Word 1 is the address of the input record
*  Word 2 is the size of the input record
*  Both words are output fields, not input
*
         USING CEEDSA,R9_32
         L     R8_32,@CONSTANTS
         USING CONSTANTS,R8_32
         LA    R7_32,EXIT_SA
         ST    R13_32,4(,R7_32)
         ST    R7_32,8(,R13_32)
         LR    R13_32,R7_32
         SLR   R15_32,R15_32
         CLI   0(R10_32),X'08'    Get function?
         JNE   EXITRET
         LT    R3_32,BYTES_LEFT
         JZ    NOBYTES            Buffer totally exhausted
GETBYTES DS    0H
         CHI   R3_32,BUFSIZE      More than one buffer full?
         JH    MOVECARD           Yes
         CLI   EOF_SW,1           Already gotten EOF_SW on STDIN?
         JE    MOVECARD           Yes, don't read
         L     R2_32,BUFFERO      Buffer Offset
         LT    R3_32,BYTES_LEFT
         JZ    NOBYTES
         LA    R0_32,INBUFFER
         LR    R1_32,R3_32
MVCLE1   MVCLE R0_32,R2_32,0
         JO    MVCLE1             LOOP IF MVCLE INTERRUPTED
NOBYTES  DS    0H
         CLI   EOF_SW,1           Already gotten EOF_SW on STDIN?
         JE    SYSIN_EOF          Yes, don't read
         LA    R2_32,INBUFFER
         ST    R2_32,BUFFERO
         L     R4_32,BYTES_LEFT
         ALR   R2_32,R4_32
         ST    R2_32,BUFFERA
         L     R15_32,BPX1RED
         LA    R1_32,CALLX
         CALL  (15),
               (FDIN,
               BUFFERA,
               ALET,
               =A(BUFSIZE),
               RETURN_VALUE,RETURN_CODE,REASON_CODE),
               VL,
               MF=(E,(1))
         LT    R5_32,RETURN_VALUE
         JM    SYSIN_ERR
         JZ    MARKEOF
         LR    R6_32,R5_32 Hold for later!
         BCTR  R5_32,0
UPLOOP   DS    0H
         CHI   R5_32,256
         JL    UPLOOPE
         TR    0(256,R2_32),TOUPPER
         LA    R2_32,256(,R2_32)
         AHI   R5_32,-256
         JNZ   UPLOOP
UPLOOPE  DS    0H
         EX    R5_32,UPPER
         LR    R5_32,R6_32 Restore value
         J     GOTBYTES
MARKEOF  DS    0H
         MVI   EOF_SW,1
GOTBYTES DS    0H
         ALR   R4_32,R5_32
         ST    R4_32,BYTES_LEFT
         LR    R3_32,R4_32
*
* If stdin is not a terminal, then loop to
* fill the buffer for more efficient(?) processing.
*        CLI   ISTTY_SW,0
*        JZ    GETBYTES
*
* But if stdin is a terminal, then continue on since
* testing shows that the BPX1RED returns when the "enter"
* key is pressed. We want to process the input immediately
* because we are basically running interactively.
MOVECARD DS    0H
         LT    R3_32,BYTES_LEFT
         JZ    SYSIN_EOF
         L     R2_32,BUFFERO
         ST    R2_32,0(,R11_32)   Input pointer
* Need to find the NEL (0x15) in the buffer
* If it isn't there, I will say the entire buffer is
* a single input record.
         BCTR  R2_32,0            BACK UP ONE
         LHI   R4_32,-1           Initialize LENGTH COUNTER
NELSCAN  DS    0H
         AHI   R4_32,1            INCREMENT LENGTH
         LA    R2_32,1(,R2_32)    NEXT BYTE
         CLI   0(R2_32),C'&NL'    NEL?
         JE    FOUND              YES - FOUND IT!
         BRCT  R3_32,NELSCAN      LOOP SCANNING
         J     NOTFND
FOUND    DS    0H
         BCTR  R3_32,0            ACCOUNT FOR THE NEL ITSELF
         ST    R3_32,BYTES_LEFT
         LA    R2_32,1(,R2_32)    BYTE AFTER NEL
         ST    R2_32,BUFFERO      SAVE OFFSET
         ST    R4_32,4(,R11_32)   SET LENGTH FOUND
         SLR   R15_32,R15_32
         J     EXITRET
NOTFND   DS    0H
         MVC   4(4,R11_32),BYTES_LEFT
         XC    BYTES_LEFT,BYTES_LEFT
         XC    BUFFERO,BUFFERO    SHOULDN'T BE NECESSARY
         SLR   R15_32,R15_32
         J     EXITRET
SYSIN_ERR DS   0H
         XC    0(8,R11_32),0(R11_32) Null the output
         LA    R15_32,12          Bad I/O Error - abort!
         J     EXITRET
SYSIN_EOF DS 0H
         XC    0(8,R11_32),0(R11_32) Null the output
         LA    R15_32,4           Indicate EOF_SW
         J     EXITRET
         DROP  R9_32
SYSPRINT_EXIT SAVE  (14,12),,'SYSPRINT EXIT'
*
* R9_32 is the User Data area, which is primed with the
*       CEEDSA address
* R10_32 is the IDFLAGS from IDCAMS
* R11_32 is the IOINFO
*  When R10_32 -> x'0C', this is two words
*  Word 1 is the address of the IDCAMS output record
*  Word 2 is the size of the IDCAMS output record
*  Both words are input fields.
*
         LM    R9_32,R11_32,0(R1_32)
         USING CEEDSA,R9_32
         L     R8_32,@CONSTANTS
         USING CONSTANTS,R8_32
         LA    R7_32,EXIT_SA
         ST    R13_32,4(,R7_32)
         LR    R13_32,R7_32
         SLR   R15_32,R15_32
         CLI   0(R10_32),X'0C'    Put function?
         JNE   EXITRET
         MVC   IOV_COUNT,=F'2'
         MVC   IOV_STRUC+0(8),0(R11_32)
         MVC   IOV_STRUC+8(8),=A(NL,1)
         LA    R1_32,CALLX
         L     R15_32,BPX1WRV
         CALL  (15),
               (FDOUT,IOV_COUNT,IOV_STRUC,
               IOV_ALET,IOV_BUFFER_ALET,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1))
         SLR   R15_32,R15_32
         J     EXITRET
         DROP  R9_32
EXITRET  DS    0H
         L     R13_32,4(,R13_32)
         RETURN (14,12),RC=(15)
CONSTANTS DS   0D
SRCHTBL  DC    256X'00'
         ORG   SRCHTBL+C'&NL'
         DC    C'&NL'
         ORG
ATTACHI  ATTACHX EP=IDCAMS,
               ECB=0,
               VL=1,
               SF=L
LATTACHI EQU   *-ATTACHI
STDIN    DC    F'0'
STDOUT   DC    F'1'
STDERR   DC    F'2'
ALET     DC    A(0)
IOV_ALET EQU   ALET
IOV_BUFFER_ALET EQU ALET
CEE3INF  DC    V(CEE3INF)
SPRINTF  DC    V(SPRINTF)
CEE3DMP  DC    V(CEE3DMP)
UPPER    TR    0(0,R2_32),TOUPPER
IOLISTI  DC    F'2'
         DC    A(SYSIN_DDNAME),A(SYSIN_EXIT),A(0)
         DC    A(SYSPRINT_DDNAME),A(SYSPRINT_EXIT),A(0)
IOLISTL  EQU   *-IOLISTI
IDCAMSPRM DC   Y(LAMSPARM)
AMSPARM  DC    C'MARGINS(1 2048)'
LAMSPARM EQU   *-AMSPARM
DDNAMES  DC    H'0'
PAGELIST DC    H'4',CL4'0001'
SYSIN_DDNAME DC CL10'DDSYSIN'
SYSPRINT_DDNAME DC CL10'DDSYSPRINT'
ATTACH_MSG DC  0H,C'ATTACH of AMS failed with RC=%d',X'1500'
NL       DC    X'15'
TITLE    DC    CL80'AMS DUMP'
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
         LCLC  &CLOCK,&YYYY,&MM,&DD
&YYYY    SETC  '&SYSDATC'(1,4)
&MM      SETC  '&SYSDATC'(5,2)
&DD      SETC  '&SYSDATC'(7,2)
&CLOCK   SETC  '&YYYY-&MM-&DD.T&SYSTIME'
VERSION  DC    C'AMS: Driver Program for IDCAMS. Version 1.0.0&NL.'
         DC    C' Assembled on &SYSTEM_ID&NL.'
         DC    C' by &SYSASM &SYSVER at &CLOCK'
         DC    C'&NL'
LVERSION EQU   *-VERSION
AMS_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=AMS,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
DOUBLE   DS    D                  FORCE DOUBLEWORD
TCBA     DS    A                  Address of Attach'd TCB
FDIN     DS    F                  Input file descriptor
FDOUT    DS    F                  Output file descriptor
FDERR    DS    F                  Error file descriptor
ATTACHX  ATTACHX SF=L
ECB      DS    F
BYTES_LEFT DS  F                  Number of bytes left in input buffer
BUFFERO  DS    A                  Offset within buffer
RECNO    DS    F                  Relative record number from STDIN
@CONSTANTS DS  A
@DUMPRET DS    A
@PARMS   DS    A
IOV@     DS    A                  IOV STRUCTURE ADDRESS
IOVL     DS    F                  IOV STRUCTURE SIZE IN BYTES
BPX1WRT  DC    A(0)               DYNAMICALLY LOADED
BPX1WRV  DC    A(0)               DYNAMICALLY LOADED
BPX1RED  DC    A(0)               DYNAMICALLY LOADED
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
BUFL     DS    F
RETURN_CODE DS F
MODIFIER DS    F
RETURN_VALUE DC A(0)               PREVIOUS DEFAULT DUB
REASON_CODE DC A(0)
CEETERM_BLOCK CEETERM MF=L
CALLX    DS    30A
MSGAREA  DS    0CL(IOV_STRUC_L)
IOV_COUNT DS   F
IOV_STRUC DS   0D
         DS    (10*8)A            ROOM FOR 10 ADDRESS / LENGTH PAIRS
IOV_STRUC_L EQU *-IOV_STRUC
IOV_STRUC_N EQU IOV_STRUC_L/8
IOLIST   DS    0D,(IOLISTL)X
EXIT_SA  DS    (72/4)A            IDCAMS I/O exits' save area
ISTTY    DS    F
         ORG   ISTTY
         DS    3X
ISTTY_SW DS    X
EOF_SW   DS    X
         DS    0D
INBUFFER DS    (2*BUFSIZE)X
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
         END   AMS
         PUNCH ' SETCODE AC(1)'
         END
