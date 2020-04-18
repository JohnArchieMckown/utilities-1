#pragma runopts("POSIX(ON)")
#define _ALL_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio_ext.h>
#include <stdbool.h>
#include <string>
int main(int argc, char **argv)
{
        int i;
        bool argDelimit = false;        /* seen -- ? */
        bool verbose = false;   /* seen -v or --verbose ? */
        bool interactive = false;       /* seen -i ? */
        bool doit;
        if (0 == argc) {
                usage();
                return (0);
        }
        while (argc) {
                /* check for -- to allow - as an
                 * argument instead of an option
                 */
                if (!strcmp("--", *argv))
                        argDelimit = true;
                else {
                        if (('-' == **argv) && !argDelimit) {
                                /* process option */
                        } else {        /* process argument */
                        if}
                        argv
                                ++;
                        argc--;
                }
        }
}
