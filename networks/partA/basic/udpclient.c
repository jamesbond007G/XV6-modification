#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        fprintf(stderr, "Usage: %s <server_ip> <server_port>\n", argv[0]);
        return 1;
    }

    int client_socket;
    struct sockaddr_in server_addr;
    char message[256];

    if ((client_socket = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("Error creating socket");
        exit(1);
    }

    int portno = atoi(argv[2]);
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(portno);
    server_addr.sin_addr.s_addr = inet_addr(argv[1]); // Use the IP address provided in the command line argument

    while (1)
    {
        printf("Enter a message: ");
        bzero(message, sizeof(message));
        fgets(message, sizeof(message), stdin);
        
        if (sendto(client_socket, message, strlen(message), 0, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
        {
            perror("Error in sending message");
            exit(1);
        }

        int r_final = recvfrom(client_socket, message, sizeof(message), 0, NULL, NULL);
        if (r_final == -1)
        {
            perror("Error in receiving message");
            exit(1);
        }
        printf("Server: %s\n", message);
    }

    // Close the socket
    close(client_socket);

    return 0;
}
