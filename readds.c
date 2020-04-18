/*********************************************************************
 * readds.c                                                          *
 *  Purpose: Read the records of a VSAM data set and write them      *
 *           to a sequential Data Set                                *
 *                                                                   *
 *  Input:   SYSUT1 DD statement describing a Sequential Data Set    *
 *                   with DISP=SHR                                   *
 *           SYSPRINT DD statement that any messages will be written *
 *                  to.                                              *
 *  by Andrew Wilt                                                   *
 *********************************************************************/

#include <string.h>     /* for memcpy, memset, strlen                */
#include "ihadcb.h"     /* IHADCB mapping                            */

  /* statically define the DCB parameter list for a DCB that
     describes using QSAM I/O to a sequential dataset. The DCB
     is defined for output (PUTs). The output data set is a
     Variable Blocked data set (SYSOUT=*). A dummy DCBE address
     is coded so that the appropriate bits indicating that a
     DCBE exists are set.
   */
 __asm(
  " DCB DSORG=PS,MACRF=(PL),DCBE=2,"
       "RECFM=VBA,LRECL=137"
               : "DS"(stoutdcb));

/* statically define a DCBE for association with the DCB           */
__asm(
 " DCBE LOC=ANY,SYNAD=QSAMIOER,RMODE31=BUFF,BLOCKTOKENSIZE=LARGE,"
        "EADSCB=OK,EODAD=QSAMEOD"
       : "DS"(STDCBE));

/* statically define the DCB parameter list for a DCB that
   describes using QSAM I/O to a sequential dataset. The DCB
   is defined for input (GETs).                                     */
__asm(
" DCB DSORG=PS,MACRF=(GL),DCBE=2"
             : "DS"(stindcb));

  /* statically define the OPEN parameter list for opening the
     QSAM output DD. The long form of the parameter list (MODE=31)
     is requested so that the module can be AMODE 31. */
 __asm(
  " OPEN (,(OUTPUT)),MF=L,MODE=31" : "DS"(open_output));

 /* statically define the OPEN parameter list for opening the
    input DD. The long form of the parameter list (MODE=31)
    is requested so that the module can be AMODE 31.*/
__asm(
 " OPEN (,(INPUT)),MF=L,MODE=31" : "DS"(open_input));

  /* statically define the CLOSE parameter list for closing the
     QSAM output DD. The long form of the parameter list (MODE=31)
     is requested so that the module can be AMODE 31. */
 __asm(
  " CLOSE (),MF=L,MODE=31" : "DS"(close_static) );

#define null 0
#define kASALineFeed ' '            /* Line Feed for ASA control     */
#define kASA2LineFeed '0'           /* Line Feed 2 lines ASA control */
#define kASA3LineFeed '-'           /* Line Feed 3 lines ASA control */
#define kMAXLRECL 32760             /* Maximum Logical Record Length */
#define kParmList 1024
#define kDCBElen 56                 /* Length of a DCBE              */
int max(int x, int y){
    return x > y ? x : y;
}
int min(int x, int y){
    return x < y ? x : y;
}

   /* function prototype for Open QSAM DCB                           */
 struct ihadcb* open_QSAM_dcb(char*, char);
   /* function prototype for Close QSAM DCB                          */
 int close_QSAM_dcb(struct ihadcb*);
   /* function prototype for reading QSAM Data Set functionality     */
 int read_QSAM_dataset(struct ihadcb* in, struct ihadcb* out);

 /* Main Line code */
 int main(void* USRPARM){
     /* ensure that the user parm is not padded with extra bytes     */
#pragma pack(packed)
     /* option values passed via PARM= JCL parameter                 */
     typedef struct opts{
         unsigned short optlen;
         char optlist[100];
     } ;
     struct opts *loc_opts;
#pragma pack(reset)

     char SYSPRINTdd[9];
     char SYSUT1dd[9];
     struct ihadcb *sysPRdcbp;      /* Pointer to SYSPRINT DCB       */
     struct ihadcb* sysUT1dcbp;     /* Pointer to SYSUT1 DCB         */
     int retcode = 0;
     int total_written;             /* total number of bytes written
                                       to the output data set        */
     /* Begin Mainline Code */
     memcpy(SYSPRINTdd, "SYSPRINT", 9); /* Set the SYSPRINT DCB name */
     memcpy(SYSUT1dd, "SYSUT1  ", 9);   /* Set the SYSUT1 DCB name   */

     /* Open SYSPRINT DD for QSAM Output. A pointer to a DCB block is
      * returned upon a successful open. */
     sysPRdcbp = open_QSAM_dcb(SYSPRINTdd,'o');

     /* Open the VSAM data set specified on the SYSUT1 DD statement.
      * A pointer to an ACB is returned upon a successful open. */
     sysUT1dcbp = open_QSAM_dcb(SYSUT1dd,'i');

     /* Read the data set and write its contents to the
      * output DD.
      */
     if(sysUT1dcbp != null &&
        sysPRdcbp != null){
         total_written = read_QSAM_dataset(sysUT1dcbp, sysPRdcbp);

         /* Close SYSPRINT DCB */
         retcode = max(retcode, close_QSAM_dcb(sysPRdcbp));
         sysPRdcbp = null;
         /* Close SYSUT1 data Set */
         retcode = max(retcode, close_QSAM_dcb(sysUT1dcbp));
         sysPRdcbp = null;
     } else
         retcode = 16;
     return retcode;
 }

 /* Functionality to read records from sequential data set and
  * write them to the output Sequential data set.
  * Input: Pointer to Opened Input DCB
  *        Pointer to Opened Output DCB
  * Output: Number of bytes written.
  */
 /* Request that the compiler insert the default prolog
    and epilog code to get and free autodata storage */
 #pragma prolog(read_QSAM_dataset,"MYPROLOG")
 #pragma epilog(read_QSAM_dataset,"MYEPILOG")
 int read_QSAM_dataset(struct ihadcb* in, struct ihadcb* out){
     int bytes_written=0;
     int readlen = 0;
     char *buff;
 #pragma pack(packed)
  struct qsamrec{
    short qs_rdw;                    /* Record Descriptor Word        */
    short qs_filler;                 /* Two byte reserved field       */
    char  qs_asa;                    /* ASA control character         */
    char  qs_buff[kMAXLRECL];        /* Message buffer                */
  };
 #pragma pack(reset)
  struct qsamrec *outrec;
  /* fields to know if EOF has been reached, or there was an I/O err  */
     int qsam_EOF;

     qsam_EOF = 0;                   /* init EOF indicator            */
     buff = 0;                       /* init buff pointer             */
     /* Read records from the input and write to the output           */
     while(qsam_EOF == 0){
         /* Get a Record from the input data set                      */
         __asm("  LR 1,%1\n"         /* Load the DCB address in Reg1  */
               "  LA 5,%2\n"         /* put address of qsam_EOF in r5 */
               "  GET (1)\n"         /* Issue GET macro               */
               "  ST 1,%0" :         /* Store buff ptr from reg1      */
               "=m"(buff) :          /* Output buffer return pointer  */
               "r"(in),              /* Input DCB address             */
               "m"(qsam_EOF) :       /* EOF indicator                 */
               "r1","r5");           /* Regs 1,5 used                 */
         readlen = in->dcblrecl;     /* remember amount of data read  */

         /* Put that record to the output data set
          * Since the Output DCB was defined as a Put Locate type,
          * a pointer to an available buffer is returned in reg 1. Once
          * PUT returns, we can then copy in the information to be
          * written to the returned buffer for processing later.      */
         if (qsam_EOF == 0){
             __asm("  LR 5,%1\n"     /* Load the DCB address in Reg5  */
               "  PUT (5)\n"         /* Issue PUT macro               */
               "  ST 1,%0" :         /* Store buff ptr from reg1      */
               "=m"(outrec) :        /* Output buffer return pointer  */
               "r"(out) :            /* Input DCB address             */
               "r1","r5");           /* Regs 1,5,14,15 used           */
             /* Copy message into buffer */
             outrec->qs_rdw = in->dcblrecl+1+4; /* msglen + asachar +
                                                   rdwsize            */
             outrec->qs_asa = kASALineFeed; /* ASA Line Feed char     */
             memcpy(&outrec->qs_buff, buff, in->dcblrecl);
             bytes_written += readlen;      /* increment # bytes      */
         }
     };

     return bytes_written;
 }

 /* Open a DCB for QSAM I/O
  * Returns a pointer to a DCB area for the opened DD.
  * Input: An 8 character, null terminated DD name string where the DD
  *         name is left-justified and padded on the right with blanks.
  *        A 1 character Open type - O for Output, I for Input
  */
 /* Request that the compiler insert the default prolog
    and epilog code to get and free autodata storage */
#pragma prolog(open_QSAM_dcb,"MYPROLOG")
#pragma epilog(open_QSAM_dcb,"MYEPILOG")

struct ihadcb* open_QSAM_dcb(char* ddname, char opentype){
   struct ihadcb* dcbptr;
   void* dcbe;

   /* Check the parameters */
   /* Check the parameters */
   if (ddname == null ||
       strlen(ddname) > 8 ||
       (opentype != 'O' &&
        opentype != 'o' &&
        opentype != 'I' &&
        opentype != 'i'))
       return null;


   /* Get 24 bit storage (backed anywhere in 64 bit) for the DCB.    */
   __asm(
     "        STORAGE OBTAIN,LENGTH=%1,"
     "ADDR=%0,SP=131,LOC=(24,64),"
     "KEY=8,BNDRY=DBLWD"
           : "+m"(dcbptr)           /* Output dcb pointer field      */
           : "i"(sizeof(struct ihadcb)+
                 sizeof(STDCBE)) /* Length to allocate        */
             );
   dcbe = (void*)((void*)dcbptr)+sizeof(struct ihadcb);
   /* clear newly obtained storage     */
   memset(dcbptr, 0, sizeof(struct ihadcb)+
                     sizeof(STDCBE));

   /* Copy the DCB from static memory to storage  */
   switch(opentype){
       case 'O':
       case 'o':
           memcpy(dcbptr,&stoutdcb,
                  sizeof(struct ihadcb));
           break;
       case 'I':
       case 'i':
           memcpy(dcbptr,&stindcb,
                  sizeof(struct ihadcb));
       /*    dcbptr->dcblrecl = 80;    set 80 byte records.          */
           break;
       default:
           break;
   }

   /* copy in the static DCBE definition */
   memcpy(dcbe,&STDCBE,kDCBElen);

   /* Set other fields in DCB */
   /* Set the DDNAME to be the requested DD name for this DCB */
   memcpy(&dcbptr->dcbddnam, ddname, 8);
   /* Replace the dummy DCBE pointer in the DCB */
   dcbptr->dcbdcbe = dcbe;

   /******************************************************************
    * Open the DCB
    ******************************************************************/
   /* Copy the DCB from static memory to storage  */
   switch (opentype){
       case 'O':
       case 'o':
           /* define the OPEN parameter list in the dynamic
              Autodata storage The long form of the parameter list
              (MODE=31) is requested so that the module can be
              AMODE 31. */
           __asm(
             " OPEN (,(OUTPUT)),MF=L,MODE=31" : "DS"(open_out_list));
           /* Copy the static parameter list to dynamic stg */
           open_out_list = open_output;

           /* Open the output DD */
           __asm(" OPEN ((%0)),MF=(E,(%1)),MODE=31" :
                 : "r"(dcbptr), "r"(&open_out_list));
           break;
       case 'I':
       case 'i':
           /* define the OPEN parameter list in the dynamic
              Autodata storage The long form of the parameter list
              (MODE=31) is requested so that the module can be
              AMODE 31. */
           __asm(
             " OPEN (,(INPUT)),MF=L,MODE=31" : "DS"(open_in_list));
           /* Copy the static parameter list to dynamic stg */
           open_in_list = open_input;

           /* Open the output DD */
           __asm(" OPEN ((%0)),MF=(E,(%1)),MODE=31" :
                 : "r"(dcbptr), "r"(&open_in_list));
           break;
       default:
           break;
       }

   /* Was the DD not Opened successfully? */
   if (dcbptr->dcbofopn != 1)
   {
       /* Free the DCB storage */
       __asm(
             "        STORAGE RELEASE,LENGTH=%1,KEY=8,"
             "SP=131,ADDR=(%0)"
             :                      /* No output fields              */
             : "r"(dcbptr),         /* pointer to storage to free    */
               "i"(sizeof(struct ihadcb)) /* Length to free          */
               );
       dcbptr = null;               /* clear pointer                 */
   }

   return dcbptr;                   /* Return DCB pointer            */
 }

 /* Close a non-VSAM data set.
  * Input : DCB to be closed
  * Output: Return code from CLOSE                       */
#pragma prolog(close_QSAM_dcb,"MYPROLOG")
#pragma epilog(close_QSAM_dcb,"MYEPILOG")

 int close_QSAM_dcb(struct ihadcb* dcbptr){
   int close_ret_code=0;

   /* If the Output DD was Opened, then CLOSE it */
   if (dcbptr->dcbofopn == 1){
     /* The DCB was opened */
     __asm(" CLOSE (),MF=L,MODE=31" : "DS"(close_list) );
     close_list = close_static;
     close_ret_code = 0;

     /* CLOSE the DD */
     __asm(" CLOSE ((%1)),MF=(E,(%2)),MODE=31\n"
           " ST 15,%0"              /* Store return code from reg15  */
           : "=m"(close_ret_code)   /* Output return code field      */
           : "r"(dcbptr),           /* Input DCB pointer             */
             "r"(&close_list));     /* CLOSE parameter list          */

   } else
       close_ret_code = 0;          /* Return 0 if DCB was not open  */

   /* If the dcbptr is not null, free the storage                    */
   if (dcbptr != null){
       /* Free the DCB storage */
       __asm(
             "        STORAGE RELEASE,LENGTH=%1,KEY=8,"
             "SP=131,ADDR=(%0)"
             :                      /* No output fields              */
             : "r"(dcbptr),         /* Input pointer to free         */
               "i"(sizeof(struct ihadcb)) ); /* Length to free       */
   }
   return close_ret_code;
 }

 /* The QSAMEOD function gets control when there is an End Of Data
    event during a PUT/GET call using QSAM.
    Before invoking GET, Register 5 is loaded with the address
    of a field that indicates that End of File has been reached.
    This code expects register 5 to contain the address of a 4 byte
    field.
    This function stores the value 1 into the field that register 5
    points to as an indicator that End of File was reached.          */
#pragma prolog(QSAMEOD,"MYPROLOG")
#pragma epilog(QSAMEOD,"MYEPILOG")
 void QSAMEOD(void){
     /* Remember that we hit End of File. */
     __asm("  LA 2,1\n"             /* put 1 into reg 2              */
           "  ST 2,0(,5)"           /* store 1 into stg at r5        */
           : : : "r2","r5");        /* regs 2,5 used                 */
 }

 /* The QSAMIOER function gets control when there is an I/O error
    during a PUT/GET call using QSAM.
    Before invoking PUT/GET, Register 5 should be loaded with the
    address of a field that indicates that an I/O Error has occurred.
    This code expects register 5 to contain the address of a 4 byte
    field.
    This function stores the value 2 into the field that register 5
    points to as an indicator that I/O Error has occurred.          */
#pragma prolog(QSAMIOER,"MYPROLOG")
#pragma epilog(QSAMIOER,"MYEPILOG")
 void QSAMIOER(void){
     /* Remember that we had an I/O Error. */
     __asm("  LA 2,2\n"             /* put 2 into reg 2              */
           "  ST 2,0(,5)"           /* store 2 into storage at r5    */
           : : : "r2","r5");        /* regs 2,5 used                 */
 }