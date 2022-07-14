//总进程 32768; 85%进程 27853
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>

void child() {
    printf("child process\n");
}

int main() {
    int i;
    int wstatus;
    for(i=1; i<=3200; i++){
        pid_t pid0 = fork();
        printf("pid = %d\n", pid0);
        waitpid(pid0, &wstatus, 0);
    }

    getchar();
}