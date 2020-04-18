#pragma runopts("POSIX(ON)")
#define _ALL_SOURCE_NO_THREADS
#define _ISOC99_SOURCE
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdarg.h>
#include <stdint.h>
#include <fcntl.h>
#include <termios.h>
#include <signal.h>
#include <setjmp.h>
static struct termios tcsave;
static int abortSignaled = 0;
static int normalExit = 0;
jmp_buf mark;
void reset(void);
void handle_signal(int);
int main(int argc, char *argv[])
{
        int keycode;
        printf("Press control-C to exit\n");
        struct termios tcparms, tcsave;
        if (0 != tcgetattr(STDIN_FILENO, &tcparms))
                perror("tcgetattr() failed.");
        memcpy(&tcsave, &tcparms, sizeof(tcsave));
        tcparms.c_iflag &= ~BRKINT;
/*    tcparms.c_lflag &= ~ICANON ; */
        tcparms.c_lflag &= ~ECHO;
        if (atexit(reset))
                perror("failed to set exit program. Aborting.");
        signal(SIGINT, handle_signal);
        if (0 != tcsetattr(STDIN_FILENO, TCSANOW, &tcparms))
                perror("tcsetattr() failed.");
        if (setjmp(mark)) {
                fputs("Unable to set recovery address. Aborting.\n", stderr);
                exit(1);
        }
        for (; !abortSignaled;) {
                keycode = getchar();
                if (abortSignaled)
                        break;
                if (keycode == EOF)
                        break;
                printf("%#04x %c ", keycode, isprint(keycode) ? keycode : ' ');
                fflush(stdout);
        }
        if (0 != tcsetattr(STDIN_FILENO, TCSANOW, &tcsave))
                perror("tcsetattr() failed.");
        fputs("Exit normal.\n", stderr);
        normalExit = 1;
}

void handle_signal(int signal)
{
        abortSignaled = 1;
        fputs("Handling signal\n", stderr);
//   signal(signal,SIG_DFL);
        return;
}

void reset(void)
{
        if (!normalExit) {
                puts("reset() called\n");
                if (0 != tcsetattr(STDIN_FILENO, TCSANOW, &tcsave))
                        perror("tcsetattr() failed.");
        }
}
