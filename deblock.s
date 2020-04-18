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
BUFSIZE  EQU   2048               STDIN buffer size, max
         IEABRCX DEFINE
*        IEABRCX DISABLE
         IEABRCX ENABLE
_BALR    OPSYN BALR
BALR     OPSYN BASR
_LA      OPSYN LA
         POP   PRINT
         SYSSTATE ASCENV=P,
               AMODE64=NO,
               ARCHLVL=2
DEBLOCK  CEEENTRY PPA=DEBLOCK_PPA,
               MAIN=YES,
               AUTO=DSASIZE,
               BASE=R11_32
         USING CEECAA,R12_32
         USING CEEDSA,R13_32
         DROP  R11_32
         USING (DEBLOCK,CONSTANTS-1),R11_32
         J     GO
GOBACK   DS    0H
         MVI   CALLX,0
         LA    R1_32,CALLX
         CLOSE (SNAPDCB,FREE),MF=(E,(1))
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
         XC    IOV@,IOV@
         XC    IOVL,IOVL
         LARL  R10_32,CONSTANTS
         USING CONSTANTS,R10_32
         ST    R10_32,@CONSTANTS
         chi r10_32,0
         jz *+2
         ST    R1_32,@PARMS
         LA    R1_32,CALLX
         L     R15_32,CEE3INF
         CALL  (15),(SYS,ENV,MEMBER,GPID,FC),VL,
               MF=(E,(1))
         TM    SYS,X'02'          UNIX?
         JNO   GOBACK             NO
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
         LOAD  EP=BPXWDYN
         ST    R0_32,BPXWDYN
         LOAD  EP=BPX1WRT
         ST    R0_32,BPX1WRT
         LOAD  EP=BPX1WRV
         ST    R0_32,BPX1WRV
         LA    R1_32,CALLX
         L     R15_32,BPXWDYN
         CALL  (15),(VARPARM),VL,MF=(E,(1))
         ltr r15_32,r15_32
         jnz *+2
         MVC   SNAPDCB(LSNAPDCB),SNAPDCBI
         LA    R1_32,CALLX
         OPEN  (SNAPDCB,(OUTPUT)),MF=(E,(1))
 ltr r15_32,r15_32
 jnz *+2
GETLP    DS    0H
 LA R1_32,MSG1
 ST R1_32,CALLX+4
 LA R1_32,MSGAREA
 ST R1_32,CALLX+0
 MVC CALLX+8(4),BYTES_LEFT
 MVC CALLX+12(4),BUFFERO
 LA R1_32,CALLX
 L       R15_32,SPRINTF
 BASR    R14_32,R15_32
 ST R15_32,COUNT
 LA R15_32,MSGAREA
 ST R15_32,BUFFERA
 L R15_32,BPX1WRT
 LA R1_32,CALLX
 CALL (15),(FDERR,BUFFERA,ALET,COUNT,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1))
         LARL  R15_32,SYSIN_EXIT
         LA    R1_32,CALLX
         ST    R13_32,UDA
*        CALL  (15),(UDA,IDFLAGS,IOINFO),MF=(E,(1))
         ST    R13_32,CALLX
         LARL  R1_32,IDFLAGS
         ST    R1_32,CALLX+4
         LA    R1_32,IOINFO
         ST    R1_32,CALLX+8
         LA    R1_32,CALLX
         BASR  R14_32,R15_32
         LTR   R15_32,R15_32
         JNZ   EOFLP
 LA R1_32,MSG2
 ST R1_32,CALLX+4
 LA R1_32,MSGAREA
 ST R1_32,CALLX+0
 MVC CALLX+8(4),BYTES_LEFT
 MVC CALLX+12(4),BUFFERO
 MVC CALLX+16(4),IOINFO+4
 LA R1_32,CALLX
 L       R15_32,SPRINTF
 BASR    R14_32,R15_32
 ST R15_32,COUNT
 LA R15_32,MSGAREA
 ST R15_32,BUFFERA
 L R15_32,BPX1WRT
 LA R1_32,CALLX
 CALL (15),(FDERR,BUFFERA,ALET,COUNT,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1))
         MVC   IOV_STRUC+0(8),IOINFO
         MVC   IOV_STRUC+8(8),=A(NL,1)
         MVC   IOV_COUNT,=F'2'
         L     R15_32,BPX1WRV
         LA    R1_32,CALLX
         CALL  (15),(FDOUT,IOV_COUNT,IOV_STRUC,
               IOV_ALET,IOV_BUFFER_ALET,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1))
         J     GETLP
EOFLP    DS    0H
         L     R15_32,BPXWDYN
         CALL  (15),(VARFREE),VL,MF=(E,(1))
         ltr r15_32,r15_32
         jnz *+2
 LA R1_32,MSG3
 ST R1_32,CALLX+4
 LA R1_32,MSGAREA
 ST R1_32,CALLX+0
 MVC CALLX+8(4),RETURN_VALUE
 MVC CALLX+12(4),RETURN_CODE
 MVC CALLX+16(4),REASON_CODE
 LA R1_32,CALLX
 L R15_32,SPRINTF
 BASR    R14_32,R15_32
 ST R15_32,COUNT
 LA R15_32,MSGAREA
 ST R15_32,BUFFERA
 L R15_32,BPX1WRT
 LA R1_32,CALLX
 CALL (15),(FDERR,BUFFERA,ALET,COUNT,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1))
*ET0     DS    0H
         XC    RETURN_CODE,RETURN_CODE
         XC    MODIFIER,MODIFIER
         J     GOBACK
VARPARM  DC    Y(LSTRING)
STRING   DC    C'ALLOC FI(SNAPDUMP) DSN(TSH009.SNAPDUMP) OLD'
LSTRING  EQU   *-STRING
VARFREE  DC    Y(LFREE)
FREE     DC    C'FREE FI(SNAPDUMP) '
LFREE    EQU   *-FREE
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
         AGO   .SKIP1
         MVC   CALLX(LSNAP),SNAPL
         LA    R1_32,CALLX
LA       OPSYN LAY
         SNAPX DCB=SNAPDCB,ID=1,
               PDATA=(PSW,REGS),STORAGE=(SNAPSTRT,SNAPEND),
               MF=(E,(1))
 ltr r15_32,r15_32
 jnz *+2
LA       OPSYN LA
.SKIP1   ANOP
         SLR   R15_32,R15_32
         CLI   0(R10_32),X'08'    Get function?
         JNE   EXITRET
*wto 'deblock sysin_exit',routcde=11
         LT    R3_32,BYTES_LEFT
         JZ    NOBYTES            Buffer totally exhausted
GETBYTES DS    0H
*wto 'deblock getbytes',routcde=11
         CHI   R3_32,BUFSIZE      More than one buffer full?
         JH    MOVECARD           Yes
         CLI   EOF_SW,1           Already gotten EOF_SW on STDIN?
         JE    MOVECARD           Yes, don't read
*        L     R3_32,BUFFERO      Buffer Offset
*        LR    R2_32,R3_32        Save it for MVCLE
*        LA    R1_32,INBUFFER     Addr of Start of buffer
*        SR    R3_32,R1_32        Number of Used bytes
*        JZ    NOBYTES            Zero
         L     R2_32,BUFFERO      Buffer Offset
         LT    R3_32,BYTES_LEFT
         JZ    NOBYTES
*        SLR   R2_32,R3_32
*        C     R2_32,INBUFFER
*        JE    NOBYTES
*wto 'deblock mvcle',routcde=11
         AGO   .SKIP2
         MVC   CALLX(LSNAP),SNAPL
         LA    R1_32,CALLX
LA       OPSYN LAY
         SNAPX DCB=SNAPDCB,ID=2,
               PDATA=(PSW,REGS),STORAGE=(SNAPSTRT,SNAPEND),
               MF=(E,(1))
 ltr r15_32,r15_32
 jnz *+2
LA       OPSYN LA
.SKIP2   ANOP
         LA    R0_32,INBUFFER
         LR    R1_32,R3_32
MVCLE1   MVCLE R0_32,R2_32,0
         JO    MVCLE1             LOOP IF MVCLE INTERRUPTED
NOBYTES  DS    0H
*wto 'deblock nobytes',routcde=11
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
         AGO   .SKIP3
         MVC   CALLX(LSNAP),SNAPL
         LA    R1_32,CALLX
LA       OPSYN LAY
         SNAPX DCB=SNAPDCB,ID=3,
               PDATA=(PSW,REGS),STORAGE=(SNAPSTRT,SNAPEND),
               MF=(E,(1))
 ltr r15_32,r15_32
 jnz *+2
LA       OPSYN LA
*ago .burp1
.SKIP3   ANOP
 LA R1_32,MSGAREA
 MVC 0(15,R1_32),=C'LEN=0X........ '
 ST R5_32,16(,R1_32)
 UNPK 06(9,R1_32),16(5,R1_32)
 TR 6(8,R1_32),TOHEX-C'0'
 MVI 14(R1_32),C' '
 MVC 15(10,R1_32),0(R2_32)
 mvi 25(r1_32),x'15'
 MVC COUNT,=a(26)
 ST R1_32,CALLX+0
 LA R15_32,MSGAREA
 ST R15_32,BUFFERA
 L R15_32,BPX1WRT
 LA R1_32,CALLX
 CALL (15),(FDERR,BUFFERA,ALET,COUNT,
               RETURN_VALUE,RETURN_CODE,REASON_CODE),VL,
               MF=(E,(1))
.burp1 anop
         LR    R6_32,R5_32 Hold for later!
         BCTR  R5_32,0
*wto 'deblock uploop',routcde=11
UPLOOP   DS    0H
         CHI   R5_32,256
         JL    UPLOOPE
         TR    0(256,R2_32),TOUPPER
         LA    R2_32,256(,R2_32)
         AHI   R5_32,-256
         JNZ   UPLOOP
UPLOOPE  DS    0H
*wto 'deblock uploope',routcde=11
         EX    R5_32,UPPER
         LR    R5_32,R6_32 Restore value
         J     GOTBYTES
MARKEOF  DS    0H
*wto 'deblock markeof',routcde=11
         MVI   EOF_SW,1
GOTBYTES DS    0H
*wto 'deblock gotbytes',routcde=11
         ALR   R4_32,R5_32
         ST    R4_32,BYTES_LEFT
         LR    R3_32,R4_32
         J     GETBYTES           No, get more bytes.
MOVECARD DS    0H
*wto 'deblock movecard',routcde=11
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
*wto 'deblock found',routcde=11
         BCTR  R3_32,0            ACCOUNT FOR THE NEL ITSELF
         ST    R3_32,BYTES_LEFT
         LA    R2_32,1(,R2_32)    BYTE AFTER NEL
         ST    R2_32,BUFFERO      SAVE OFFSET
         ST    R4_32,4(,R11_32)   SET LENGTH FOUND
         SLR   R15_32,R15_32
         J     EXITRET
NOTFND   DS    0H
*wto 'deblock notfnd',routcde=11
         MVC   4(4,R11_32),BYTES_LEFT
         XC    BYTES_LEFT,BYTES_LEFT
         XC    BUFFERO,BUFFERO    SHOULDN'T BE NECESSARY
         SLR   R15_32,R15_32
         J     EXITRET
SYSIN_ERR DS   0H
*wto 'sysin_err',routcde=11
 l r0_32,return_value
 l r1_32,return_code
 l r2_32,reason_code
 l r3_32,buffera
 l r4_32,buffero
 l r5_32,bytes_left
 la r6_32,inbuffer
 larl r15_32,deblock
 j *+2
         XC    0(8,R11_32),0(R11_32) Null the output
         LA    R15_32,12          Bad I/O Error - abort!
         J     EXITRET
SYSIN_EOF DS 0H
*wto 'sysin_eof',routcde=11
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
*  When R10_32 -> x'08', this is two words
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
         ST    R7_32,8(,R13_32)
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
*        LM    R2_32,R3_32,0(R11_32) Get addr & length of line
*        SL    R3_32,=A(L'IDCAMSEND+2) Subtract min length
*        JNP   EXITRET            Too short
*        CLC   IDCAMSEND,1(R2_32) End of IDCAMS run?
*        JNE   EXITRET            No
*        LA    R7_32,DOUBLE       USED IN PACKRC INSTRUCTION
*        EX    R3_32,PACKRC
*        CVB   R4_32,DOUBLE
*        ST    R4_32,IDCAMSRC
         J     EXITRET
         DROP  R9_32
EXITRET  DS    0H
         L     R13_32,4(,R13_32)
         XC    8(4,R13_32),8(R13_32)
         RETURN (14,12),RC=(15)
CONSTANTS DS   0D
SNAPL    SNAPX DCB=0,PDATA=(PSW,REGS),STORAGE=(0,0),ID=0,MF=L
LSNAP    EQU   *-SNAPL
SNAPDCBI DCB   DDNAME=SNAPDUMP,
         DSORG=PS,
         RECFM=VBA,
         MACRF=W,
         LRECL=125,
         BLKSIZE=1632
LSNAPDCB EQU *-SNAPDCBI
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
*ACKRC   PACK  0(8,R7_32),L'IDCAMSEND+1(0,R2_32)
IOLISTI  DC    F'2'
         DC    A(SYSIN_DDNAME),A(SYSIN_EXIT),A(0)
         DC    A(SYSPRINT_DDNAME),A(SYSPRINT_EXIT),A(0)
IOLISTL  EQU   *-IOLISTI
IDCAMSPRM DC   H'0'
DDNAMES  DC    H'0'
PAGELIST DC    H'4',CL4'0001'
IDFLAGS  DC    X'08'
SYSIN_DDNAME DC CL10'DDSYSIN'
SYSPRINT_DDNAME DC CL10'DDSYSPRINT'
*DCAMSEND DC C'IDC0002I IDCAMS PROCESSING COMPLETE. MAXIMUM CONDITION C
*              ODE WAS '
NL       DC    X'15'
TITLE    DC    CL80'DEBLOCK DUMP'
OPTIONS  DC    CL255'BLOCKS,STORAGE,REGST(256),GENOPTS'
MSG1     DC    C'Bytes_left=%d Offseto=%#08.8x',X'1500'
MSG2     DC    C'Bytes_left=%d Offseto=%#08.8x Length=%d',X'1500'
MSG3 DC C'RV=%d RC=%d rsn=%#08.8x',X'1500'
STROUT DC C'Bytes read=%d %10.10S',X'1500'
TOUPPER  DC    256AL1(*-TOUPPER)
         ORG   TOUPPER+X'81'
         DC    C'ABCDEFGHI'
         ORG   TOUPPER+X'91'
         DC    C'JKLMNOPQR'
         ORG   TOUPPER+X'A2'
         DC    C'STUVWXYZ'
         ORG
TOHEX    DC    C'0123456789ABCDEF'
         LTORG *
         LCLC  &CLOCK,&YYYY,&MM,&DD
&YYYY    SETC  '&SYSDATC'(1,4)
&MM      SETC  '&SYSDATC'(5,2)
&DD      SETC  '&SYSDATC'(7,2)
&CLOCK   SETC  '&YYYY-&MM-&DD.T&SYSTIME'
VERSION  DC    C'DEBLOCK: Driver Program for IDCAMS. Version 1.0.0&NL.'
         DC    C' Assembled on &SYSTEM_ID&NL.'
         DC    C' by &SYSASM &SYSVER at &CLOCK'
         DC    C'&NL'
LVERSION EQU   *-VERSION
DEBLOCK_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=DEBLOCK,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
DOUBLE   DS    D                  FORCE DOUBLEWORD
SNAPDCB  DS    (LSNAPDCB)X
         DS    0D
*DCAMSRC DS    F                  Possible RC from IDCAMS
UDA      DS    A
IOINFO   DC    2A(0)
FDIN     DS    F                  Input file descriptor
FDOUT    DS    F                  Output file descriptor
FDERR    DS    F                  Error file descriptor
ATTACHX  ATTACHX SF=L
ECB      DS    F
RECNO    DS    F                  Relative record number from STDIN
@CONSTANTS DS  A
@DUMPRET DS    A
@PARMS   DS    A
IOV@     DS    A                  IOV STRUCTURE ADDRESS
IOVL     DS    F                  IOV STRUCTURE SIZE IN BYTES
BPX1WRT  DC    A(0)               DYNAMICALLY LOADED
BPX1WRV  DC    A(0)               DYNAMICALLY LOADED
BPX1RED  DC    A(0)               DYNAMICALLY LOADED
BPXWDYN  DC    A(0)               DYNAMICALLY LOADED
COUNT    DS    F
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
IOV_COUNT DS   F
IOV_STRUC DS   0D
         DS    (10*8)A            ROOM FOR 10 ADDRESS / LENGTH PAIRS
IOV_STRUC_L EQU *-IOV_STRUC
IOV_STRUC_N EQU IOV_STRUC_L/8
IOLIST   DS    0D,(IOLISTL)X
EXIT_SA  DS    (72/4)A            IDCAMS I/O exits' save area
MSGAREA  DS    CL(20+L'MSG1)
EOF_SW   DS    X
         DS    0D
SNAPSTRT EQU   *
BUFFERA  DS    A
BYTES_LEFT DS  F                  Number of bytes left in input buffer
BUFFERO  DS    A                  Offset within buffer
INBUFFER DS    (2*BUFSIZE)X
ENDBUFFER EQU  *
SNAPEND  EQU   *
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
         END   DEBLOCK
         PUNCH ' SETCODE AC(1)'
         END
