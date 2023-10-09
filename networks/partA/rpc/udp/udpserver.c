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

    char finalmsg1[256];
    char finalmsg2[256];
    int sockfd1, sockfd2, portno1, portno2, l1, l2;
    char message[256];
    struct sockaddr_in server_address1, server_address2, client_address1, client_address2;
    socklen_t clientlength1, clientlength2;

    if (argc != 3)
    {
        printf("Usage: %s <port1> <port2>\n", argv[0]);
        return 1;
    }

    sockfd1 = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd1 < 0)
    {
        printf("Error creating socket 1.\n");
        return 1;
    }
    // bzero((char *)&server_address1, sizeof(server_address1));
    portno1 = atoi(argv[1]);
    server_address1.sin_family = AF_INET;
    server_address1.sin_addr.s_addr = INADDR_ANY;
    server_address1.sin_port = htons(portno1);
    if (bind(sockfd1, (struct sockaddr *)&server_address1, sizeof(server_address1)) < 0)
    {
        printf("Error in binding 1\n");
        return 1;
    }
    clientlength1 = sizeof(client_address1);

    sockfd2 = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd2 < 0)
    {
        printf("Error creating socket 2.\n");
        return 1;
    }
    portno2 = atoi(argv[2]);
    server_address2.sin_family = AF_INET;
    server_address2.sin_addr.s_addr = INADDR_ANY;
    server_address2.sin_port = htons(portno2);
    if (bind(sockfd2, (struct sockaddr *)&server_address2, sizeof(server_address2)) < 0)
    {
        printf("Error in binding 2\n");
        return 1;
    }
    clientlength2 = sizeof(client_address2);

    char message1[256];
    while (1)
    {

        int k = sizeof(struct sockaddr_in);
        l1 = recvfrom(sockfd1, message, sizeof(message), 0, (struct sockaddr *)&client_address1, &k);
        if (l1 < 0)
        {
            printf("Error in read 1 \n");
            break;
        }
        if (strncmp(message, "NO", 2) == 0)
        {
            // if (sendto(sockfd1, finalmsg1, sizeof(finalmsg1), 0, (struct sockaddr *)&client_address1, sizeof(client_address1)) < 0)
            // {
            //     printf("Error in writing 1\n");
            //     close(sockfd1);
            //     close(sockfd2);

            //     return 1;
            // }
            strcpy(finalmsg2, "EXIT");
            printf("HA\n");
            if (sendto(sockfd2, finalmsg2, sizeof(finalmsg2), 0, (struct sockaddr *)&client_address2, sizeof(client_address2)) == -1)
            {
                close(sockfd1);
                close(sockfd2);

                printf("Error in writing 2\n");
                return 1;
            }
            break;
        }
        printf("Client 1: %s\n", message);

        int k1 = sizeof(struct sockaddr_in);
        l2 = recvfrom(sockfd2, message1, sizeof(message1), 0, (struct sockaddr *)&client_address2, &k1);
        if (l2 < 0)
        {
            printf("Error in read 2 \n");
            break;
        }
        if (strncmp(message1, "NO", 2) == 0)
        {
            strcpy(finalmsg1, "EXIT");
            if (sendto(sockfd1, finalmsg1, sizeof(finalmsg1), 0, (struct sockaddr *)&client_address1, sizeof(client_address1)) < 0)
            {
                printf("Error in writing 1\n");
                close(sockfd1);
                close(sockfd2);

                return 1;
            }

            // if (sendto(sockfd2, finalmsg2, sizeof(finalmsg2), 0, (struct sockaddr *)&client_address2, sizeof(client_address2)) < 0)
            // {
            //     close(sockfd1);

            //     close(sockfd2);
            //     printf("Error in writing 2\n");
            //     return 1;
            // }
            break;
        }
        if (strncmp(message1, "NO", 2) != 0 && strncmp(message, "NO", 2) != 0)
        {
            strcpy(finalmsg1, "YES");

            if (sendto(sockfd1, finalmsg1, sizeof(finalmsg1), 0, (struct sockaddr *)&client_address1, sizeof(client_address1)) < 0)
            {
                printf("Error in writing 1\n");
                close(sockfd1);
                close(sockfd2);

                return 1;
            }
            strcpy(finalmsg2, "YES");
            if (sendto(sockfd2, finalmsg2, sizeof(finalmsg2), 0, (struct sockaddr *)&client_address2, sizeof(client_address2)) < 0)
            {
                close(sockfd1);

                close(sockfd2);
                printf("Error in writing 2\n");
                return 1;
            }

            l1 = recvfrom(sockfd1, message, sizeof(message), 0, (struct sockaddr *)&client_address1, &k);
            if (l1 < 0)
            {
                printf("Error in read 1 \n");
                break;
            }
            l2 = recvfrom(sockfd2, message1, sizeof(message1), 0, (struct sockaddr *)&client_address2, &k1);
            if (l2 < 0)
            {
                printf("Error in read 2 \n");
                break;
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
            printf("finalmsg1 = %s finalmsg2 = %s", finalmsg1, finalmsg2);

            if (sendto(sockfd1, finalmsg1, sizeof(finalmsg1), 0, (struct sockaddr *)&client_address1, sizeof(client_address1)) < 0)
            {
                printf("Error in writing 1\n");
                close(sockfd1);
                close(sockfd2);

                return 1;
            }

            if (sendto(sockfd2, finalmsg2, sizeof(finalmsg2), 0, (struct sockaddr *)&client_address2, sizeof(client_address2)) < 0)
            {
                close(sockfd1);

                close(sockfd2);
                printf("Error in writing 2\n");
                return 1;
            }
        }
    }

    close(sockfd1);
    close(sockfd2);
    return 0;
}