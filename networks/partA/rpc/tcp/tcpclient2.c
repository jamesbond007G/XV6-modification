#include "stdio.h"
#include "stdlib.h"
#include "unistd.h"
#include "sys/types.h"
#include "sys/socket.h"
#include "netinet/in.h"
#include "netdb.h"
#include "string.h"

int main(int argc, char *argv[])
{
    int sockfd, portno, l;
    char message[256];
    struct sockaddr_in server_address;
    // socklen_t clientlength;
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0)
    {
        printf("Error creatign socket at 1.\n");
    }
    struct hostent *server;
    server = gethostbyname(argv[1]);
    if (server == NULL)
    {
        printf("error in finding host\n");
    }
    portno = atoi(argv[2]);
    bzero((char *)&server_address, sizeof(server_address));
    server_address.sin_family = AF_INET;
    bcopy((char *)server->h_addr_list[0], (char *)&server_address.sin_addr.s_addr, server->h_length);
    server_address.sin_port = htons(portno);
    if (connect(sockfd, (struct sockaddr *)&server_address, sizeof(server_address)) < 0)
    {
        printf("Error in connecting\n");
        // close(sockfd);
        return 0;

        // exit(0);
    }
    // printf("YES\n");
    while (1)
    {
        bzero(message, 255);
        fgets(message, 255, stdin);
        l = write(sockfd, message, sizeof(message));
        if (l < 0)
        {
            printf("Error in writing\n");
        }
        // printf("YES message sent\n");
        bzero(message, 255);
        l = recv(sockfd, message, sizeof(message), 0);
        if (l < 0)
        {
            printf("Error is coming\n");
        }
        printf("Server : %s", message);
    }

    close(sockfd);
    return 0;
}