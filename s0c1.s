*PROCESS ALIGN,NOCOMPAT,DXREF,FLAG(ALIGN,CONT,RECORD)
*PROCESS NOFOLD,NOINFO,PC(ON,DATA,GEN,MCALL),RENT,
*PROCESS RA2,NORLD,MXREF,RXREF,USING(MAP,WARN(13))
*PROCESS TYPECHECK(MAGNITUDE,REGISTER)
*WARNING - THIS PROGRAM REQUIRES THE HIGH-LEVEL ASSEMBLER
*          AS WELL AS LE/370
*          THIS PROGRAM IS RE-ENTRANT.
         PUSH  PRINT
         PRINT NOGEN
         IEABRCX DEFINE
         IEABRCX DISABLE
          IEABRCX ENABLE
_BALR     OPSYN BALR
BALR     OPSYN BASR
         POP   PRINT
S0C1     CEEENTRY PPA=S0C1_PPA,
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
GO       DS    0H
         LR    R10_32,R1_32       SAVE R1 UPON ENTRY
         USING PARMS,R10_32
         LM    R3_32,R5_32,@ARGC
         L     R2_32,4(,R13_32)
         USING PSA,0
         L     R6_32,PSATOLD
         DROP  0
         USING TCB,R6_32
         L     R6_32,TCBJSTCB
         L     R7_32,TCBFSA
         L     R8_32,8(,R7_32)
         J     *+2
         XC    RETURN_CODE,RETURN_CODE
         XC    MODIFIER,MODIFIER
         LTR   R3_32,R3_32
         JZ    GOBACK
         LR    R9_32,R3_32       SAVE
         J     GOBACK
         LTORG *
S0C1_PPA CEEPPA LIBRARY=NO,
               PPA2=YES,
               EXTPROC=YES,
               TSTAMP=YES,
               PEP=YES,
               INSTOP=NO,
               EXITDSA=NO,
               OWNEXM=YES,
               EPNAME=S0C1,
               VER=1,
               REL=1,
               MOD=0,
               DSA=YES
         CEEDSA
* DYNAMIC AREA IS DEFINED HERE.
* THIS IS WITHIN A DSECT, SO NO DATA IS REALLY INITIALIZED
         DS    0D                 FORCE DOUBLEWORD
CEETERM_BLOCK CEETERM MF=L
RETURN_CODE DS F
MODIFIER DS    F
STORAGE@ DS    A
DSASIZE  EQU   *-CEEDSA
         regs
         CEECAA
         IKJTCB
         IHAPSA
PARMS    DSECT
@ARGC    DS    A                  ADDRESS OF NUMBER OF ARGUMENTS
@ARGVL   DS    A                  ADDRESS OF VECTOR OF LENGTH OF S0C1
@ARGV    DS    A                  ADDRESS OF VECTOR OF S0C1
@OPTSTR  DS    A                  ADDRESS OF OPTION STRING
         END   S0C1
