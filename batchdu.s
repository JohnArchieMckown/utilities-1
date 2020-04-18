BATCHDU  TITLE 'PROGRAM TO OUTPUT DASD VOLUME STATISTICS'
BATCHDU  CSECT
BATCHDU  AMODE 24
BATCHDU  RMODE 24
         SPLEVEL SET
         GBLC  &ZPRINT
&ZPRINT  SETC  'YES'
****************************************************************
*                                                              *
****************************************************************
         REGS
         USING *,R11
         BAKR  R14,R0              SAVE CALLER'S AR'S AND GPR'S
         LR    R11,R15
         CNOP  0,4
         BAS   R13,GO
         DC    A(0),CL4'F1SA',16F'0'
GOBACK   DS    0H
         CLOSE (SPACEDTA)
         LR    R15,R5              LOAD CONDITION CODE
         PR                        RETURN TO CALLER.
GO       DS    0H
         OPEN  (SPACEDTA,(OUTPUT))
         IOCINFO IOCTOKEN=TOKEN
         XC     SCANWORK,SCANWORK
SEARCH   DS    0H
         UCBSCAN COPY,UCBAREA=UCBCOPY,
               WORKAREA=SCANWORK,
               UCBPAREA=UCBPAREA,
               CMXTAREA=CMXTAREA,
               RANGE=ALL,
               PLISTVER=MAX,
               DYNAMIC=YES,
               DCEAREA=MYDCE,
               DCELEN=LMYDCE,
               DEVCLASS=DASD,
               IOCTOKEN=TOKEN
         LTR   R15,R15
         BNZ   TESTDYN
         LA    R2,UCBCOPY         GET UCB ADDRESS THAT THE SCAN
         USING UCBOB,R2
*                                  SERVICE RETURNED
         TM     UCBSTAT,UCBONLI    Q. IS THIS DEVICE ONLINE ?
         BNO    SEARCH             A. NO - TRY AGAIN
         CLI    UCBTBYT3,UCB3DACC  DASD?
         BNE   SEARCH              NO
         LSPACE UCB=((2)),
               DATA=SDATA,
               SMF=NONE,
               F4DSCB=RDSCB4
         LSPACE UCB=((2)),
               SMF=NONE,
               EXPMSG=EXPMSG
         DROP  R2
         LA    R2,SDATA
         USING LSPACE,R2
         LA    R3,RDSCB4
         USING DSCB4,R3
         LA    R4,UCBCOPY
         USING UCB,R4
         LA    R5,MYDCE
         USING DCE,R5
         MVC   OUTDEV,DCEOBRDT
         MVC   UCBCOPY2,UCBCOPY
         PUT   SPACEDTA,RECORD
         DROP  R2
         DROP  R3
         DROP  R4
         DROP  R5
         B     SEARCH
TESTDYN  DS    0H
         SLR   R5,R5
         C     R15,=F'12'          CONFIG CHANGE?
         BNE   GOBACK              YES - RETRY
         CLOSE (SPACEDTA)
         B     GO
         DS    0D
TOKEN    DS    XL48
TOKEN2   DS    XL48
UCBCOPY  DS    XL48
CMXTAREA DS    CL32
UCBPAREA DS    CL48
SCANWORK DS    CL100
         DS    0D
RECORD   DS    0D
RDSCB4   DC    0D'0',(LDSCB4)X'00'
SDATA    DC    9F'0'
UCBCOPY2 DS    XL48
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
         DS    0F
EXPMSG   DC    CL40' '
DLEN     EQU   *-RECORD
         LTORG *
SPACEDTA DCB   DDNAME=SPACEDTA,
               LRECL=DLEN,
               DSORG=PS,
               RECFM=FB,
               MACRF=PM
MYDCE    DC    XL100'00'
LMYDCE   DC    AL2(L'MYDCE)
         EJECT
UCB      DSECT
         IEFUCBOB LIST=YES         UCB MAPPING MACRO
         IECDDCE
X2       CVT    DSECT=YES,LIST=YES
DSCB4    DSECT
         IECSDSL1 (4)
LDSCB4   EQU   *-DSCB4
LSPACE   LSPACE MF=(D,DATA)
         END   BATCHDU
