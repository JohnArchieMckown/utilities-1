QUERYSMS TITLE 'REXX FUNCTION - QUERY SMS'
&MAXVOLS SETA      2000 /* MAX DASD SMS VOLUMES IN THE SYSTEM */
***********************************************************************
*                 MODULE NAME = QUERYSMS                              *
*             DESCRIPTIVE NAME =  REXX FUNCTION TO QUERY SMS THROW SSI*
*             AUTHOR = SALVADOR CARRASCO                              *
*                 FUNCTION =                                          *
*                arg(1)='SGV' - return a list of volumes associated   *
*                               the storage group arg(2)              *
*                       'VSG' - return the storage group associated   *
*                               the volume arg(2)                     *
*                       'VOL' - return arg(2) volume definition       *
*                       'AVL' - return the list of all volumes        *
*                       'SGL' - return the list of storage groups     *
*             RESTRICTIONS = NONE                                     *
*             REGISTER CONVENTIONS = STANDARD CONVENTIONS.            *
*             ATTRIBUTES = KEY NZ, PROBLEM STATE, ENABLED, NO LOCKS   *
*             ENTRY POINTS = QUERYSMS (ONLY ENTRY POINT)              *
*             INPUT = REG0 POINTS TO REXX ENVBLOCK                    *
*                     REG1 POINTS TO REXX ARGTABLE                    *
*             EXIT - NORMAL = AT PROGRAM END VIA BR 14                *
*             OUTPUT = DATA IN REXX STACK                             *
*                      RETURN CODE = 1                                *
*             EXIT - ERROR = AT PROGRAM END VIA BR 14                 *
*             OUTPUT = ERROR MSG TO IRXSAY                            *
*                      RETURN CODE = 16                               *
*             EXTERNAL REFERENCES =                                   *
*                CONTROL BLOCKS = VARIOUS MVS/SMS.                    *
*                                 SEE BOTTOM OF CODE.                 *
***********************************************************************
QUERYSMS CSECT
         SYSSTATE ASCENV=P,
               AMODE64=NO,
               ARCHLVL=2
QUERYSMS AMODE 31
QUERYSMS RMODE ANY
         YREGS                         STD REGISTER EQUATES
* ADDRESSING
         SAVE  (14,12),,*              SAVE PREVIOUS
         LR    R12,R15                 BASE REG
         USING QUERYSMS,R12            =BASE REGISTER     =
         LR    R11,R0                  REXX ENVBLOCK ADD.
         LR    R10,R1                  REXX EFPL ADD.
         GETMAIN RU,LV=LDATA,LOC=BELOW GET WORK AREA
         LR    R15,R13                 PREVIOUS SAVEAREA
         LR    R13,R1                  NEW SAVEAREA/WORK AREA
         ST    R15,4(,R13)             SAVE OLD SAVEAREA
         ST    R13,8(R15)              SAVE NEW SAVEAREA
         USING DATA,R13                =SAVEAREA+WORK AREA=
         USING ENVBLOCK,R11            =REXX ENV BLOCK    =
         USING EFPL,R10                =REXX EFPL         =
         USING EVALBLOCK,R9            =REXX EVALBLOCK    =
         USING ARGTABLE_ENTRY,R8       =REXX ARG TABLE    =
         L     R9,EFPLEVAL             USE DEFAULT EVALBLOCK
         L     R9,0(,R9)               ADDRESS IT
         L     R8,EFPLARG              FIRST ARG
* GET AND VERIFY PARM
         XC    PARM1,PARM1             CLEAR PARM1
         MVC   PARM2,=CL30' '          CLEAR PARM2
         L     R1,ARGTABLE_ARGSTRING_PTR  GET FIRST ARG ADD
         LTR   R1,R1                   TEST
         BM    EXITNOK                 NO PARM -> ERROR
         L     R2,ARGTABLE_ARGSTRING_LENGTH GET LENGTH OF ARG
*        C     R2,=F'3'                LENGTH = 3 ?
         CHI   R2,3                    LENGTH = 3 ?
         BNE   EXITNOK                 NO -> EXIT NO OK
         BCTR  R2,0                    LEN=LEN-1
         EX    R2,COPYPAR1             EXECUTE MOVE
         LA    R8,ARGTABLE_NEXT        POINT TO NEXT ARG
         L     R1,ARGTABLE_ARGSTRING_PTR GET ARG ADD
         LTR   R1,R1                   TEST
         BM    CHECKP1                 NO PARM2 -> SKIP
         L     R2,ARGTABLE_ARGSTRING_LENGTH GET LENGTH OF ARG
*        C     R2,=F'30'               LENGTH <= 30 ?
         CHI   R2,30   '               LENGTH <= 30 ?
         BH    EXITNOK                 NO -> EXIT NO OK
         STH   R2,PARM2L               SAVE LENGTH
         BCTR  R2,0                    LEN=LEN-1
         EX    R2,COPYPAR2             EXECUTE MOVE
CHECKP1  EQU   *
         MVI   TYPE,C'V'               VLD PROCESS
         CLC   PARM1,=C'VOL'           ARG(1) = 'VOL' ?
         BE    CHECKP2                 YES, CHECK ARG(2)
         CLC   PARM1,=C'AVL'           ARG(1) = 'AVL' ?
         BE    MAIN                    YES, PROCEED
         CLC   PARM1,=C'SGV'           ARG(1) = 'SGV' ?
         BE    CHECKP2                 YES, PROCEED
         MVI   TYPE,C'S'               SGD PROCESS
         CLC   PARM1,=C'VSG'           ARG(1) = 'VSG' ?
         BE    CHECKP2                 YES, PROCEED
         CLC   PARM1,=C'SGL'           ARG(1) = 'SGL' ?
         BE    MAIN                    YES, PROCEED
         B     EXITNOK                 ARG(1) NOT VALID
CHECKP2  CLC   PARM2,=CL30' '          ARG(2) EMPTY ?
         BE    EXITNOK                 YES, EXIT NO OK
         B     MAIN                    ARG(2) OK -> PROCEED
COPYPAR1 MVC   PARM1(0),0(R1)          MOVE ARG(1)
COPYPAR2 MVC   PARM2(0),0(R1)          MOVE ARG(2)
* MAIN
MAIN     GETMAIN RU,LV=WKTBL,LOC=ANY   GET WORK AREA
         ST    R1,WORKVLD              SAVE BUFFER ADDRESS
         BAL   R14,CALLSMS             GET SMS INFORMATION
         BAL   R14,SAVEDAT             WRITE DATA
         L     R1,WORKVLD              GET BUFFER ADDRESS
         FREEMAIN RU,LV=WKTBL,A=(1)    FREE SAVE/WORK AREA
         B     EXITOK
* EXIT
EXITBAD1 CVD   R15,WORKD               CONV TO DECIMAL SSI RC
         ED    ABE01M(6),WORKD+5       EDIT IN MSG
         LA    R1,ABE01                LOAD MSG ADD
         BAL   R14,WRITEER             SAY ERROR
         LA    R11,16                  RETURN CODE=16
         B     $E02
EXITBAD2 CVD   R1,WORKD                CONV TO DECIMAL SSSA RSN
         ED    ABE02M(6),WORKD+5       EDIT IN MSG
         LA    R1,ABE02                LOAD MSG ADD
         BAL   R14,WRITEER             SAY ERROR
         LA    R11,16                  RETURN CODE=16
         B     $E02
EXITNOK  LA    R1,ERR01                ARG/PARM ERROR
         BAL   R14,WRITEER             SAY ERROR
         LA    R11,16                  RC=16
         B     $E02
EXITOK   MVI   EVALBLOCK_EVDATA,C'1'   RETURN 'TRUE'
         LA    R1,1                    RETURN LENGTH
         ST    R1,EVALBLOCK_EVLEN      SAVE IT
         SLR   R11,R11                 RETURN CODE=0
$E02     LR    R1,R13                  GET SAVE/WORK AREA
         L     R13,4(,13)              GET OLD SAVEAREA
         FREEMAIN RU,LV=LDATA,A=(1)    FREE SAVE/WORK AREA
         LR    R15,R11                 GET RETURN CODE
         RETURN (14,12),RC=(15)        RETURN TO CALLER
* CALLSMS
CALLSMS  EQU   *
         ST    R14,SCALLSMS            SAVE RETURN ADDRESS.
* CONSTRUCT SSOB
         XC    WORKSSOB,WORKSSOB       CLEAR SSOB
         LA    R2,WORKSSOB             LOAD SSOB ADD.
         USING SSOB,R2                 MAP IT
         MVC   SSOBID,=C'SSOB'         SSOB ACRON.
         MVC   SSOBLEN,=AL2(SSOBHSIZ)  SSOB LENGTH
         MVC   SSOBFUNC,=AL2(SSOBSSMS) FUNCTION CODE FOR SMS SERVICES
         L     R1,CVTPTR(0,0)          -> CVT
         L     R1,CVTJESCT-CVTMAP(,R1) -> JES2 COMMUNICATION TABLE
         L     R1,JESCTEXT-JESCT(,R1)  -> PAGEABLE JESCT
         MVC   SSOBSSIB,JESSMSIB-JESPEXT(R1) -> SMS SSIB
         O     R2,=X'80000000'         SET LAST PARM
         ST    R2,PTRSSOB              SAVE IT
* CONSTRUCT SSSA
         XC    WORKSSSA,WORKSSSA       CLEAR SSSA
         LA    R3,WORKSSSA             LOAD SSSA ADD.
         ST    R3,SSOBINDV             FUNCTION DEPENDENT AREA POINTER
         USING IEFSSSA,R3              MAP IT
         MVC   SSSAID,=C'SSSA'         SSSA ACRON.
         LA    R0,SSSALN+SSSA1LN+32    LENGTH
         STH   R0,SSSALEN
         MVC   SSSAVER,=AL2(SSOBSSVR)  VERSION NUMBER
         MVC   SSSASFN,=AL2(SSSAACTV)  RETURNS DATA FROM THE ACTIVE CFG
         MVI   SSSAIFLG,SSSANAUT       CALLER NOT AUTHORIZED
$C0      EQU   *
         CLC   PARM1,=C'AVL'           ARG(1) = 'AVL' ?
         BNE   $C1                     NO, TRY NEXT
         MVI   SSSA1TYP,SSSA1AVL       RETURN THE LIST OF ALL VOLUMES
         B     $C9
$C1      CLC   PARM1,=C'VOL'           ARG(1) = 'VOL' ?
         BNE   $C2                     NO, TRY NEXT
         MVI   SSSA1TYP,SSSA1VOL       RETURN A VOLUME
         MVC   SSSA1NML,=AL2(6)        LENGTH OF VOLSER
         MVC   SSSA1NAM(6),PARM2+0     MOVE VOLSER
         B     $C9
$C2      CLC   PARM1,=C'SGV'           ARG(1) = 'SGV' ?
         BNE   $C3                     NO, TRY NEXT
         MVI   SSSA1TYP,SSSA1SGV       RETURN A LISTVOL FROM A STORGRP
         MVC   SSSA1NML,PARM2L         LENGTH OF STORGRP NAME
         MVC   SSSA1NAM(30),PARM2+0     MOVE STORGRP
         B     $C9
$C3      CLC   PARM1,=C'VSG'           ARG(1) = 'VSG' ?
         BNE   $C4                     NO, TRY NEXT
         MVI   SSSA1TYP,SSSA1VSG       RETURN THE SG FROM A VOLUME
         MVC   SSSA1NML,=AL2(6)        LENGTH OF VOLSER
         MVC   SSSA1NAM(6),PARM2+0     MOVE VOLSER
         B     $C9
$C4      EQU   *                       ARG(1) = 'SGL'
         MVI   SSSA1TYP,SSSA1SGL       RETURN SG LIST
         B     $C9
$C9      EQU   *
         MVC   SSSA1CNT,=F'1'          ONE REQUEST
         MVC   SSSA1LEN,=AL4(WKTBL)    LENGTH OF WORK AREA
         L     R1,WORKVLD              GET VLD WORK AREA
         ST    R1,SSSA1PTR             SAVE VLD WORK AREA
* CALL SSI
         LA    R1,PTRSSOB              GET ADD OF SSOB ADD
         IEFSSREQ ,                    CALL SSI
         LTR   R15,R15                 TEST RC
         BNZ   EXITBAD1                µ=0 -> EXIT BAD RETURN CODE
         L     R1,SSSARSN              LOAD SSSA REASON CODE
         LTR   R1,R1                   TEST RC
         BNZ   EXITBAD2                µ=0 -> EXIT BAD RETURN CODE
         DROP  R2,R3                   END OF PROCESS
RCALLSMS L     R14,SCALLSMS            GET RETURN ADD.
         BR    R14                     RETURN TO CALLER
* SAVEDAT - SAVE RETURNED INFORMATION
SAVEDAT  EQU       *
         ST    R14,SSAVEDAT            SAVE CALLER'S RET. ADD.
* PREPARE CALL TO QUEUE
         L     R1,ENVBLOCK_IRXEXTE     GET VECTOR EXTERNAL ROUTINES ADD
         L     R7,IRXSTK-IRXEXTE(,R1)  GET STACK ROUTINE ADD.
         ST    R11,_STKENV             SAVE ENV ADD
         MVC   STKFUNC,=CL8'QUEUE'    SET QUEUE FUNCTION
         LA    R1,_STKFUNC             GET ADD
         ST    R1,_STKPARM+0           SET AS PARM1
         LA    R1,_STKDAT              GET DATA ADDRESS
         ST    R1,_STKPARM+4           SET AS PARM2
         LA    R1,_STKLEN              GET DATA LENGTH
         ST    R1,_STKPARM+8           SET AS PARM3
         LA    R1,_STKRC               GET RC AREA
         ST    R1,_STKPARM+12          SET AS PARM4
         LA    R1,_STKENV              GET ENVBLCOK ADD
         ST    R1,_STKPARM+16          SET AS PARM5
         LA    R1,_STKRCE              GET RCE ADDRESS
         O     R1,=X'80000000'         SET AS LAST PARM
         ST    R1,_STKPARM+20          SET AS PARM6
* WRITE ITEMS
         L     R2,WORKVLD              GET WORK ADD
         USING VLD,R2                  MAP AS VLD/SGD
         L     R3,VLDPCNT              GET TOTAL COUNT
         L     R4,VLDPLEN              GET LENGTH OF EACH ITEM
         ST    R4,_STKLEN              SET LENGTH FOR IRXSTK
         LA    R2,VLDEF                GET FIRST ENTRY
         DROP  R2
NEXT     ST    R2,_STKDAT              SET DATA ADDRESS
         LR    R0,R11                  GET ENVBLOCK
         LR    R15,R7                  GET IRXSTK ENTRY POINT
         LA    R1,_STKPARM             LOAD PARM ADD
         BALR  R14,R15                 CALL IRXSTK
         AR    R2,R4                   SKIP TO NEXT ENTRY
         BCT   R3,NEXT                 REPEAT, UNTIL COUNT = 0
RSAVEDAT L     R14,SSAVEDAT            GET CALLER RETURN ADD
         BR    R14                     RETURN TO CALLER
* WRITER - WRITE ERROR MSG
WRITEER  EQU       *
         ST    R14,SWRITEER
* PREPARE CALL TO SAY
         L     R2,ENVBLOCK_IRXEXTE     GET VECTOR EXTERNAL ROUTINES ADD
         L     R7,IRXSAY-IRXEXTE(,R2)  GET STACK ROUTINE ADD.
         ST    R11,_STKENV             SAVE ENV ADD
         MVC   STKFUNC,=CL8'WRITEERR' SET WRITEERR FUNCTION
         LA    R2,_STKFUNC             GET ADD
         ST    R2,_STKPARM+0           SET AS PARM1
         LA    R2,_STKDAT              GET DATA ADDRESS
         ST    R2,_STKPARM+4           SET AS PARM2
         LA    R2,_STKLEN              GET DATA LENGTH
         ST    R2,_STKPARM+8           SET AS PARM3
         LA    R2,_STKENV              GET ENVBLCOK ADD
         ST    R2,_STKPARM+12          SET AS PARM4
         LA    R2,_STKRCE              GET RCE ADDRESS
         O     R2,=X'80000000'         SET AS LAST PARM
         ST    R2,_STKPARM+16          SET AS PARM5
* WRITE ERROR MSG
         LR    R3,R1                   LOAD PARM ADD
*        SR    R2,R2                   CLEAR R2
*EXLINE  ICM   R2,B'0011',0(R3)        GET LINE LENGTH
NEXLINE  LLH   R2,0(,R3)
         LTR   R2,R2                   IS ZERO ?
         BZ    RWRITEER                YES, -> END
         LA    R3,2(,R3)               GET DATA ADDRESS
         ST    R3,_STKDAT              SET DATA TO SAY
         ST    R2,_STKLEN              SET LENGTH TO SAY
         LR    R0,R11                  GET ENVBLOCK
         LR    R15,R7                  GET IRXSAY ENTRY POINT
         LA    R1,_STKPARM             LOAD PARM ADD
         BALR  R14,R15                 CALL IRXSAY
         AR    R3,R2                   ADD LINE LENGTH
         B     NEXLINE                 GO FOR NEXT LINE
RWRITEER L     R14,SWRITEER            GET RETURN ADD
         BR    R14                     RETURN TO CALLER
* DATA AREA
ERR01    DC    AL2(26),C'Usage: QUERYSMS(type,name)'
         DC    AL2(13),C' Where type ='
         DC    AL2(73),C'  SGV - return a list of volumes associated wiX
               th the storage group ''name'''
         DC    AL2(66),C'  VSG - return the storage group associated wiX
               th the volume ''name'''
         DC    AL2(39),C'  VOL - return ''name'' volume definition'
         DC    AL2(38),C'  AVL - return the list of all volumes'
         DC    AL2(41),C'  SGL - return the list of storage groups'
         DC    AL2(0)
ABE01    DC    AL2(39),C'Subsystem Interface Error, RC = '
ABE01M   DC    X'40202020212040'
         DC    AL2(33),C'  Note: See SYS1.MACLIB(IEFSSOBH)'
         DC    AL2(00)
ABE02    DC    AL2(24),C'SMS Error, RSN = '
ABE02M   DC    X'40202020212040'
         DC    AL2(32),C'  Note: See SYS1.MODGEN(IEFSSSA)'
         DC    AL2(00)
         LTORG
DATA     DSECT ,                       SAVE/WORK AREA
SAVEAREA DS    18F                     SAVE AREA
SSAVEDAT DS    F                       ROUTINE RETURN
SCALLSMS DS    F                       ROUTINE RETURN
SWRITEER DS    F                       ROUTINE RETURN
         DS    0D                       ALIGN.
_STKFUNC DS    CL8                     STKFUNC
_STKDAT  DS    F                       STKDAT
_STKLEN  DS    F                       STKLEN
_STKRC   DS    F                       STKRC
_STKENV  DS    F                       STKENV
_STKRCE  DS    F                       STKRCE
_STKPARM DS    6F                      PARM ADDRESS
WORKD    DS    D                       WORKING DECIMAL
PARM1    DS    CL3                     PARM 1
PARM2    DS    CL30                     PARM 2
PARM2L   DS    H                       PARM 2 LENGTH
TYPE     DS    X                       TYPE OF RETURN
PTRSSOB  DS    F                       -> TO SSOB
         DS    0D                       ALIGN.
WORKSSOB DS    XL(SSOBHSIZ)            WORKING SSOB
         DS    0D                       ALIGN.
WORKSSSA DS    XL(SSSALN+SSSA1LN+32)   WORKING SSSA
VLDLEN   EQU   VLDEND-VLDEF+VLDEND2-VLDSYSDT TOTAL VLD LENGTH
WKTBL    EQU   VLDEF-VLD+(VLDLEN*&MAXVOLS)
WORKVLD  DS    F
LDATA    EQU   *-DATA
* USED MAPS
DUMMY    DSECT
         IRXENVB                       REXX ENV. BLOCK
         IRXEFPL                       REXX EFPL
         IRXARGTB                      REXX ARG. TABLE
         IRXEVALB                      REXX EVAL BLOCK
         IRXEXTE                       REXX ROUTINES
         IEFUCBOB DEVCLAS=DA,PREFIX=YES  UCB MAPPING
         IEFJSSOB
         IEFSSSA                       SMS - SSI
         CVT DSECT=YES                 CVT
         IEFJESCT                      JESCT
         IGDVLD                        SMS VOLUME DEFINITION MAPPING
         IGDSGD                        SMS STORAGE GROUP DEFINITION MAP
         END   QUERYSMS
