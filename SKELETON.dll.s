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
         IEABRCX DEFINE
*        IEABRCX DISABLE
         IEABRCX ENABLE
_BALR    OPSYN BALR
BALR     OPSYN BASR
         POP   PRINT
         SYSSTATE ASCENV=P,
               AMODE64=NO,
               ARCHLVL=2
SKELETON CEEENTRY PPA=SKELETON_PPA,
               MAIN=NO,
               EXPORT=YES,
               AUTO=DSASIZE,
               BASE=R11_32
SKELETON ALIAS C'skeleton'
         USING CEECAA,R12_32
         USING CEEDSA,R13_32
         J     GO
GOBACK   DS    0H
CEETERM  DS    0H
         CEETERM RC=RETURN_CODE,
               MODIFIER=MODIFIER
GO       DS    0H
         LR    R10_32,R1_32       SAVE R1 UPON ENTRY
         USING PARMS,R10_32
         ST    R15_32,MODIFIER
         MVC   RETURN_CODE,=F'-1'
         LT    R2_32,0(,R10_32)   First parm NULL?
         JZ    CEETERM
RET0     DS    0H
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
CEE3DMP  DC    V(CEE3DMP)
TOHEX    DC    C'0123456789ABCDEF'
TAB      DC    X'05'
NL       DC    X'15'
TITLE    DC    CL80'SKELETON DUMP'
OPTIONS  DC    CL255'BLOCKS,STORAGE,REGST(256),GENOPTS'
         LTORG *
SKELETON_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=YES,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=SKELETON,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
         DS    0D                 FORCE DOUBLEWORD
RETURN_CODE DS F
MODIFIER DS    F
RETURN_VALUE DC A(0)               PREVIOUS DEFAULT DUB
REASON_CODE DC A(0)
CALLX    DS    30F
FC       DS    3F
@DUMPRET DS    A
DSASIZE  EQU   *-CEEDSA
         BPXYCONS DSECT=YES,LIST=YES
         BPXYERNO LIST=YES
         BPXYIOV
         CEECAA
PARMS    DSECT
         regs
         END   SKELETON