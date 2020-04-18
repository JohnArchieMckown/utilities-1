//#pragma target(zOSV1R11)
#pragma title("z/OS UNIX command to delete a z/OS UNIX file, legacy dataset, or member of a PDS")
#pragma subtitle("(c) John A. McKown, released under GPLv2+")
#pragma langlvl(extc99)
#pragma options(inline,optimize,rent)
#pragma runopts(trap(off),stack(24K,4K,ANYWHERE))
#pragma strings(readonly)
//#define _POSIX_SOURCE 200112L
//#define _POSIX_C_SOURCE 200112L
//#define _ALL_SOURCE_
#define _XOPEN_SOURCE 600
//#define _XOPEN_SOURCE_EXTENDED 1
//#define _LARGE_FILES
//#define _LARGE_TIME_API
#include <stdarg.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
/* CELEBR12
   When you invoke this example with a file name, the program attempts to
   remove that file.
   It issues a message if an error occurs.
 */

void usage()
{
        printf("Usage: %s fn ...\n", argv[0]);
        printf("This command will remove UNIX files,\n");
        printf(" z/OS data sets, and members from a\n");
        printf(" a PDS or PDSE library.\n");
        printf("To remove a UNIX file:            %s filename\n", argv[0]);
        printf(" where filename is a relative or absolute UNIX file name.\n");
        printf("To delete a z/OS legacy data set: %s \"//dsn\"\n", argv[0]);
        printf(" where dsn is a standard legacy data set name.\n");
        printf(" note that if you do not enclose the DSN in ' characters,");
        printf(" your RACF id will be used as the high level qualifier.\n");
        printf("To delete a member of a PDS:      %s \"//dsn(member)\"\n",
               argv[0]);
}

int main(int argc, char **argv)
{
        int argno;
        int errorOccurred = 0;
        if (argc < 2) {
                usage();
                return (0);
        }
        while (argc) {
                if (remove(*argv) != 0) {
                        fprintf(stderr, "Error removing file: %s", *argv);
                        perror();
                        errorOccurred = 1;
                } else {
                        printf("Removed file: %s\n", *argv);
                }
                argc--;         /* decrease number of arguments to process */
                argv++;         /* point to next argument */
        }
        return (errorOccurred);
}
