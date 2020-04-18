#define _XOPEN_SOURCE_EXTENDED 1
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <cstdio>
#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
        struct rlimit rlim;
        int i;
        i = getrlimit(RLIMIT_NOFILE, &rlim);
        if (i < 0)
                perror("getrlimit() failed.");
        printf("RLIMIT_NOFILE soft=%d hard=%d\n", rlim.rlim_cur, rlim.rlim_max);
//      std::cout<<"RLIMIT_NOFILE current="<<rlim.rlim_cur<<" maximum="<<rlim.rlim_max;
        return 0;
}
