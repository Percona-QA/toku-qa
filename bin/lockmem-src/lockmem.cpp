#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>

int usage(const char *progname) {
    printf("%s: NBYTES\n", progname);
    printf("640MiB may be expressed as 640m\n");
    printf("if mlock fails then check the limit on locked memory (ulimit -l)\n");
    return 1;
}

size_t get_size(char *sp) {
    size_t m = 1; // size multiplier (see later)
    char *eptr;
    size_t n = strtoul(sp, &eptr, 10);
    switch (*eptr) {
    case 'g': case 'G':
        m *= 1024;
    case 'm': case 'M':
        m *= 1024;
    case 'k': case 'K':
        m *= 1024;
    }
    return n*m;
}
    
int main(int argc, char *argv[]) {
    int i;
    for (i=1; i<argc; i++) {
        char *arg = argv[i];
        if (arg[0] != '-')
            break;
        return usage(argv[0]);
    }
    if (i >= argc)
        return usage(argv[0]);
    size_t n = get_size(argv[i]);
    void *vp = malloc(n);
    if (vp == 0) {
        printf("malloc failed: %d %s\n", errno, strerror(errno));
        return 1;
    }
    int r = mlock(vp, n);
    if (r != 0) {
        printf("mlock failed: %d %s\n", errno, strerror(errno));
        return 1;
    }

    for (;;) sleep(1000);

    return 0;
}
