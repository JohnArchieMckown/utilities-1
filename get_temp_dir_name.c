/*
 * This routine returs a char * which defines the directory
 * into which to place "temporary" files. The coding may 
 * look weird, but basically it simply checks for the
 * environment variables: TMPDIR, TMP, TEMPDIR, and TEMP
 * in that order and returns the first one that it finds.
 * If it finds none, it returns a pointer to "/tmp".
 */
#include <stdlib.h>
char *const get_temp_dir_name(void)
{
        const char *const tmp = "/tmp";
        char *envp;
        if (NULL == (envp = getenv("TMPDIR")))
                if (NULL == (envp = getenv("TMP")))
                        if (NULL == (envp = getenv("TEMPDIR")))
                                if (NULL == (envp = getenv("TEMP")))
                                        envp = (char *)tmp;
        return (char *const)envp;
}
