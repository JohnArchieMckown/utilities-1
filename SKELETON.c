#include <stdlib.h>
#include <stdio.h>
int main(int argc, char *argv[])
{
        FILE *sysprint;
        int fclose_result = 0;
        int fprintf_result = 0;
        sysprint = fopen("//DD:SYSPRINT", "r");
        if (NULL == sysprint) {
                fprintf(stderr, "Could not open DD:SYSPRINT\n");
                return 1;
        }
        fprintf_result = fprintf(sysprint, "Hello, World!\n");
        fclose_result = fclose(sysprint);
        return fprintf_result + fclose_result;
        /* return 0; */
}
