#include <stdlib.h>
#include <stdio.h>
#include <string.h>
int main(int argc, char *argv[])
{
        char *psaaold;
        char *ascbjbni;
        unsigned char *ascbjbns;
        unsigned char *ascbjbn;
        unsigned char *a;
        unsigned char jobname[9];
        psaaold = *(unsigned char **)0x224;     /* address of PSAAOLD */
//printf("%s\n",psaaold);
        ascbjbni = *(unsigned char **)(psaaold + 0xac);
        ascbjbns = *(unsigned char **)(psaaold + 0xb0);
        ascbjbn = ascbjbni;
//printf("%s\n",ascbjbni);
        if (ascbjbn == NULL)
                ascbjbn = ascbjbns;
//memcpy(jobname,ascbjbn,8);
        a = (unsigned char *)memccpy(jobname, ascbjbn, ' ', 8);
        if (NULL == a)
                a = jobname + 9;
        *(--a) = '\0';
        *(jobname + 8) = '\0';
        printf("%s - %8.8s\n", jobname, ascbjbn);
}
