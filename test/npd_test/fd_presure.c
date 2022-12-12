//总fd 759033; 80%fd 607227
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
int main(){
    int fd;
    int i;
    for(i=1; i<=67777; i++){
            char* file=malloc(10);
            sprintf(file, "%d", i);
            printf("str:%s\n", file);

            fd = open(file,O_RDWR);

            printf("%d\n",fd);
            printf("open succeed\n");
            if(fd == -1){
                fd = open(file,O_RDWR|O_CREAT,0600);
                printf("%d\n",fd);
                printf("create succeesd\n");
            }
        }

    //        for(i=1; i<=10000; i++){
    //            fd = open("./file"+i,O_RDWR);
    //            printf("%d\n",fd);
    //        }
    //        close(fd)
    printf("done");
    getchar();
}