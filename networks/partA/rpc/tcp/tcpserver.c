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

    if (argc != 3)
    {
        printf("Usage: %s <port1> <port2>\n", argv[0]);
        return 1;
    }

    sockfd1 = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd1 < 0)
    {
        printf("Error creating socket 1.\n");
        return 1;
    }
    bzero((char *)&server_address1, sizeof(server_address1));
    portno1 = 1235;
    server_address1.sin_family = AF_INET;
    server_address1.sin_addr.s_addr = inet_addr("127.0.0.1");
    server_address1.sin_port = htons(portno1);
    if (bind(sockfd1, (struct sockaddr *)&server_address1, sizeof(server_address1)) < 0)
    {
        printf("Error in binding 1\n");
        return 1;
    }
    clientlength1 = sizeof(client_address1);

    sockfd2 = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd2 < 0)
    {
        printf("Error creating socket 2.\n");
        return 1;
    }
    bzero((char *)&server_address2, sizeof(server_address2));
    portno2 = 5434;
    server_address2.sin_family = AF_INET;
    server_address2.sin_addr.s_addr = inet_addr("127.0.0.1");
    server_address2.sin_port = htons(portno2);
    if (bind(sockfd2, (struct sockaddr *)&server_address2, sizeof(server_address2)) < 0)
    {
        printf("Error in binding 2\n");
        return 1;
    }
    clientlength2 = sizeof(client_address2);

    if (listen(sockfd1, 3) < 0)
    {
        perror("Error in listen");
        exit(1);
    }
    if (listen(sockfd2, 3) < 0)
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

    newsockfd2 = accept(sockfd2, (struct sockaddr *)&client_address2, &clientlength2);
    if (newsockfd2 < 0)
    {
        printf("Error in accept 2 \n");
        return 1;
    }
    char finalmsg1[256];
    char finalmsg2[256];
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
            if (strncmp(message, "EXIT", 4) == 0)
            {
                printf("YESSSSSSS\n");
                strcpy(finalmsg1, "EXIT");
                if (write(newsockfd2, finalmsg1, sizeof(finalmsg1)) < 0)
                {
                    printf("Error in writing 1\n");
                    return 1;
                }
                break;
            }
            l2 = recv(newsockfd2, message1, sizeof(message1), 0);
            if (l2 < 0)
            {
                printf("Error in read 2 \n");
                return 1;
            }
            if (strncmp(message1, "EXIT", 4) == 0 || strncmp(message, "EXIT", 4) == 0)
            {
                if (strncmp(message1, "EXIT", 4) == 0)
                {
                    // printf("YESSSSSSS\n");
                    strcpy(finalmsg1, "EXIT");
                    if (write(newsockfd1, finalmsg1, sizeof(finalmsg1)) < 0)
                    {
                        printf("Error in writing 1\n");
                        return 1;
                    }

                    break;
                }
            }
            else
            {
                strcpy(finalmsg1, "ok");
                if (write(newsockfd2, finalmsg1, sizeof(finalmsg1)) < 0)
                {
                    printf("Error in writing 1\n");
                    return 1;
                }
                if (write(newsockfd1, finalmsg1, sizeof(finalmsg1)) < 0)
                {
                    printf("Error in writing 1\n");
                    return 1;
                }
            }

            bzero(message, 256);
            l1 = recv(newsockfd1, message, sizeof(message), 0);
            if (l1 < 0)
            {
                printf("Error in read 1 \n");
                return 1;
            }

            printf("Client 1: %s\n", message);

            bzero(message1, 256);
            l2 = recv(newsockfd2, message1, sizeof(message1), 0);
            if (l2 < 0)
            {
                printf("Error in read 2 \n");
                return 1;
            }

            printf("Client 2: %s\n", message1);

            if (strcmp(message, "Rock\n") == 0 && strcmp(message1, "Scissor\n") == 0)
            {
                strcpy(finalmsg1, "YOU WIN!\n");
                strcpy(finalmsg2, "YOU LOSE!\n");
            }
            else if (strcmp(message, "Rock\n") == 0 && strcmp(message1, "Paper\n") == 0)
            {
                // printf("YES\n");
                strcpy(finalmsg1, "YOU LOSE!\n");
                strcpy(finalmsg2, "YOU WIN!\n");
            }
            else if (strcmp(message, "Paper\n") == 0 && strcmp(message1, "Scissor\n") == 0)
            {
                strcpy(finalmsg1, "YOU LOSE!\n");
                strcpy(finalmsg2, "YOU WIN!\n");
            }
            else if (strcmp(message, "Paper\n") == 0 && strcmp(message1, "Rock\n") == 0)
            {
                strcpy(finalmsg1, "YOU WIN!\n");
                strcpy(finalmsg2, "YOU LOSE!\n");
            }
            else if (strcmp(message, "Scissor\n") == 0 && strcmp(message1, "Paper\n") == 0)
            {
                strcpy(finalmsg1, "YOU WIN!\n");
                strcpy(finalmsg2, "YOU LOSE!\n");
            }
            else if (strcmp(message, "Scissor\n") == 0 && strcmp(message1, "Rock\n") == 0)
            {
                strcpy(finalmsg1, "YOU LOSE!\n");
                strcpy(finalmsg2, "YOU WIN!\n");
            }
            // printf("finalmsg1 = %s finalmsg2 = %s", finalmsg1, finalmsg2);
            if (write(newsockfd1, finalmsg1, sizeof(finalmsg1)) < 0)
            {
                printf("Error in writing 1\n");
                return 1;
            }

            if (write(newsockfd2, finalmsg2, sizeof(finalmsg2)) < 0)
            {
                printf("Error in writing 2\n");
                return 1;
            }
        }
        close(newsockfd1);
        close(newsockfd2);
    }

    close(sockfd1);
    close(sockfd2);
    return 0;
}
