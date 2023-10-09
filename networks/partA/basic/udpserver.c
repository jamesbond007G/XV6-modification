#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include "arpa/inet.h"
int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s <port>\n", argv[0]);
        return 1;
    }

    int sockfd;
    int portno = atoi(argv[1]);
    char buffer[256];
    struct sockaddr_in server_address, client_address;
    socklen_t client_length = sizeof(client_address);

    // Create a UDP socket
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0)
    {
        perror("Error creating socket");
        return 1;
    }

    // Initialize server_address structure
    memset((char *)&server_address, 0, sizeof(server_address));
    server_address.sin_family = AF_INET;
    server_address.sin_addr.s_addr = INADDR_ANY;
    server_address.sin_port = htons(portno);

    // Bind the socket to the specified port
    if (bind(sockfd, (struct sockaddr *)&server_address, sizeof(server_address)) < 0)
    {
        perror("Error in binding");
        return 1;
    }

    while (1)
    {
        bzero(buffer, sizeof(buffer));

        // Receive data from a client
        int n = recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&client_address, &client_length);
        if (n < 0)
        {
            perror("Error in read");
            break;
        }
        printf("Client:%s\n", buffer);
        // buffer to be sent below
        printf("Enter a message: ");
        bzero(buffer, sizeof(buffer));
        fgets(buffer, sizeof(buffer), stdin);
        if (sendto(sockfd, buffer, strlen(buffer), 0, (struct sockaddr *)&client_address, client_length) < 0)
        {
            perror("Error in writing");
            break;
        }
    }

    close(sockfd);  
    return 0;
}
