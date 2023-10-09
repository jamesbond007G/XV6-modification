
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

char *null_terminate(char *message, int size)
{
    char *l = (char *)malloc(sizeof(char) * strlen(message));
    message[size] = '\0';
    strcpy(l, message);
    return l;
}
int main(int argc, char *argv[])
{
    int client_socket;
    struct sockaddr_in server_addr;
    char message[256];

    if ((client_socket = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        exit(1);
    }

    int portno;
    portno = atoi(argv[2]);
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(portno);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    while (1)
    {
        printf("DO you want to play, enter YES or NO\n");
        bzero(message, 256);
        fgets(message, 256, stdin);
        if (sendto(client_socket, message, strlen(message), 0, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
        {
            printf("Error in sending messag\n");
            exit(1);
        }
        if (strncmp(message, "NO", 2) == 0)
        {
            break;
        }
        int r_final = recvfrom(client_socket, message, 256, 0, NULL, NULL);
        if (r_final == -1)
        {
            printf("Error in receiving message\n");
            exit(1);
        }
        printf("Server: %s\n", message);
        if (strncmp(message, "YES", 3) == 0)
        {
            // message[r_final] = '\0';
            // char *j = null_terminate(message, r_final);
            // strcpy(message, j);

            // printf("type 'NO' for exiting game ");
            fgets(message, 256, stdin);
            char mess1[256];
            strcpy(mess1, message);
            if (sendto(client_socket, message, strlen(message), 0, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
            {
                perror("Error sending message");
                exit(1);
            }
            if (strncmp(message, "EXIT", 4) == 0)
            {
                // printf("YEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZ");
                break;
            }

            bzero(message, 256);

            r_final = recvfrom(client_socket, message, 256, 0, NULL, NULL);
            printf("%s", message);
        }
        else
        {
            break;
        }
    }

    // Close the socket
    close(client_socket);

    return 0;
}