#include <stdio.h>
#include <stdlib.h>
int main(int argc, char *argv[])
{
        short int sint;
        int iint;
        long int lint;
/*  long long int llint; */
        printf("sizeof(short int)=%d\n", sizeof(sint));
        printf("sizeof(int)=%d\n", sizeof(iint));
        printf("sizeof(long)=%d\n", sizeof(lint));
/*  printf("sizeof(long long)=%d\n",sizeof(llint)); */
        return 0;
}
