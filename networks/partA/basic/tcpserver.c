#include "stdio.h"
#include "stdlib.h"
#include "unistd.h"
#include "sys/types.h"
#include "sys/socket.h"
#include "netinet/in.h"
#include "netdb.h"
#include "string.h"
#include "arpa/inet.h"

int main(int argc, char *argv[])
{
    int sockfd1, sockfd2, newsockfd1, newsockfd2, portno1, portno2, l1, l2;
    char message[256];
    struct sockaddr_in server_address1, server_address2, client_address1, client_address2;
    socklen_t clientlength1, clientlength2;

    if (argc < 2)
    {
        printf("give port no. also as an argument \n");
        return 1;
    }

    sockfd1 = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd1 < 0)
    {
        printf("Error creating socket 1.\n");
        return 1;
    }
    bzero((char *)&server_address1, sizeof(server_address1));
    portno1 = atoi(argv[1]);
    server_address1.sin_family = AF_INET;
    server_address1.sin_addr.s_addr = inet_addr("127.0.0.1");
    server_address1.sin_port = htons(portno1);
    if (bind(sockfd1, (struct sockaddr *)&server_address1, sizeof(server_address1)) < 0)
    {
        printf("Error in binding 1\n");
        return 1;
    }
    clientlength1 = sizeof(client_address1);

    if (listen(sockfd1, 3) < 0)
    {
        perror("Error in listen");
        exit(1);
    }


    newsockfd1 = accept(sockfd1, (struct sockaddr *)&client_address1, &clientlength1);
    if (newsockfd1 < 0)
    {
        printf("Error in accept 1 \n");
        return 1;
    }

   
    char finalmsg1[256];
    while (1)
    {
        char message1[256];
        while (1)
        {

            bzero(message, 256);
            l1 = recv(newsockfd1, message, sizeof(message), 0);
            if (l1 < 0)
            {
                printf("Error in read 1 \n");
                return 1;
            }

            printf("Client 1: %s\n", message);

            bzero(finalmsg1, 255);
            // printf("DO YOU WANT TO PLAY if yes then say YES, else say EXIT?\n");
            fgets(finalmsg1, 255, stdin);
            // printf("finalmsg1 = %s finalmsg2 = %s", finalmsg1, finalmsg2);
            if (write(newsockfd1, finalmsg1, sizeof(finalmsg1)) < 0)
            {
                printf("Error in writing 1\n");
                return 1;
            }
        }
        close(newsockfd1);
    }

    close(sockfd1);
    return 0;
}
