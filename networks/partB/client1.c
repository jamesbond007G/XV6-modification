
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <time.h>
#include <sys/time.h>

#define SERVER_IP "127.0.0.1"
#define SERVER_PORT 8080
#define SERVER_PORT1 8081

#define MAX_PACKET_SIZE 6 // MAX packet size
#define TIMEOUT_SEC 1     // Timeout in seconds

struct packet2
{
    int seq_number;
    char data[MAX_PACKET_SIZE];
    int flag_awk;
    int send_time;
};
struct Packet
{
    int seq_number;
    char data[MAX_PACKET_SIZE];
};
void send_packet(int sockfd, struct Packet packet, struct sockaddr_in *server_addr)
{
    sendto(sockfd, &packet, sizeof(packet), 0, (struct sockaddr *)server_addr, sizeof(*server_addr));
}
int check(struct packet2 *arr, int chunks)
{
    for (int i = 0; i < chunks; i++)
    {
        if (arr[i].flag_awk == 1)
        {
            continue;
        }
        else
        {
            return 0;
        }
    }
    return 1;
}
struct Packet1
{
    int seq_number;
    char data[MAX_PACKET_SIZE];
    int flag_awk;
    int ack;
};
int expected_num_packets;
int check1(struct Packet1 received_packets[expected_num_packets])
{
    int flag = 0;
    for (int i = 0; i < expected_num_packets; i++)
    {
        if (received_packets[i].ack == 1)
        {
            continue;
        }
        else
        {
            return flag;
        }
    }
    flag = 1;
    return flag;
}
int main()
{
    while (1)
    {
        // int chunks;
        char message[100000];
        printf("Enter the string you want to send: ");

        if (fgets(message, sizeof(message), stdin) == NULL)
        {
            perror("fgets");
            exit(1);
        }

        // Remove the newline character from the input
        message[strcspn(message, "\n")] = '\0';
        int ll = strlen(message);
        printf("%d\n", ll);
        int chunks = (ll + MAX_PACKET_SIZE - 1) / MAX_PACKET_SIZE; // Calculate the number of chunks
        struct packet2 sender_packets[chunks];                     // Array to track packets

        for (int i = 0; i < chunks; i++)
        {
            int j = 0;
            char string[MAX_PACKET_SIZE + 1];  // Allocate memory for the string
            memset(string, 0, sizeof(string)); // Initialize the string to all null characters

            while (j < MAX_PACKET_SIZE && (i * MAX_PACKET_SIZE + j) < ll)
            {
                printf("o\n");
                string[j] = message[(i * MAX_PACKET_SIZE) + j];
                j++;
            }
            string[j] = '\0';

            sender_packets[i].seq_number = i;       // Set the sequence number
            strcpy(sender_packets[i].data, string); // Copy data to the packet
            sender_packets[i].flag_awk = 0;
        }
        // Print the packets
        for (int i = 0; i < chunks; i++)
        {
            printf("Packet %d: %s\n", sender_packets[i].seq_number, sender_packets[i].data);
        }

        int sockfd;
        struct sockaddr_in server_addr;

        // Create UDP socket
        if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
        {
            perror("Socket creation error");
            exit(1);
        }

        memset(&server_addr, 0, sizeof(server_addr));
        server_addr.sin_family = AF_INET;
        server_addr.sin_port = htons(SERVER_PORT);
        server_addr.sin_addr.s_addr = inet_addr(SERVER_IP);

        char syn_ack_packet[MAX_PACKET_SIZE];
        socklen_t addr_len = sizeof(server_addr);
        // recvfrom(sockfd, syn_ack_packet, MAX_PACKET_SIZE, 0, (struct sockaddr *)&server_addr, &addr_len);
        // printf("Received: %s\n", syn_ack_packet);

        // char ack_packet[] = "ACK";
        // send_packet(sockfd, (struct Packet){0, ack_packet}, &server_addr);
        // printf("ACK sent\n");

        // srand(time(NULL)); // Seed for random number generation

        // Simulated data transfer
        struct timeval start_time, current_time;
        gettimeofday(&start_time, NULL);

        int sent_packets = 0;
        int acked_packets = 0;
        struct Packet num_packets_packet;
        num_packets_packet.seq_number = -1; // Use a special sequence number to indicate the number of packets
        sprintf(num_packets_packet.data, "%d", chunks);
        // num_packets_packet.flag_awk = 0;
        send_packet(sockfd, num_packets_packet, &server_addr);
        struct timespec current_time1;

        // Retrieve the current time using CLOCK_REALTIME
        if (clock_gettime(CLOCK_MONOTONIC, &current_time1) == -1)
        {
            perror("clock_gettime");
            return 1;
        }

        for (int i = 0; i < chunks; i++)
        {

            struct Packet data_packet;
            data_packet.seq_number = i;
            strcpy(data_packet.data, sender_packets[i].data);
            if (clock_gettime(CLOCK_MONOTONIC, &current_time1) == -1)
            {
                perror("clock_gettime");
                return 1;
            }
            sender_packets[i].send_time = time(NULL);
            send_packet(sockfd, data_packet, &server_addr);

            printf("Data packet %d sent %s\n", i, data_packet.data);
        }
        while (check(sender_packets, chunks) == 0)
        {
            // printf("gopal\n");
            char ack_response[5];
            recvfrom(sockfd, ack_response, sizeof(ack_response), MSG_DONTWAIT, (struct sockaddr *)&server_addr, &addr_len); // if()
            if (strncmp(ack_response, "DONE", 4) == 0)
            {
                break;
            }
            if (sender_packets[atoi(ack_response)].flag_awk == 0)
            {
                sender_packets[atoi(ack_response)].flag_awk = 1;
                printf("recevied acknowledgement - %d\n", atoi(ack_response));
            }
            for (int i = 0; i < chunks; i++)
            {
                // printf("gopal1\n");

                if (clock_gettime(CLOCK_MONOTONIC, &current_time1) == -1)
                {
                    perror("clock_gettime");
                    return 1;
                }

                if (time(NULL) - sender_packets[i].send_time >= 1)
                {
                    if (sender_packets[i].flag_awk == 0)
                    {
                        printf("resent %d\n", i);
                        struct Packet data_packet;
                        data_packet.seq_number = i;
                        strcpy(data_packet.data, sender_packets[sent_packets].data);
                        sender_packets[data_packet.seq_number].send_time = time(NULL);
                        send_packet(sockfd, data_packet, &server_addr);
                    }
                }
            }
            // if()
        }
        close(sockfd);

        int sockfd1;

        struct sockaddr_in server_addr1, client_addr1;
        if ((sockfd1 = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
        {
            perror("Socket creation error");
            exit(1);
        }
        memset(&server_addr1, 0, sizeof(server_addr1));
        server_addr1.sin_family = AF_INET;
        server_addr1.sin_port = htons(SERVER_PORT1);
        server_addr1.sin_addr.s_addr = inet_addr(SERVER_IP);

        if (bind(sockfd1, (struct sockaddr *)&server_addr1, sizeof(server_addr1)) == -1)
        {
            perror("Binding error");
            exit(1);
        }
        // if (bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
        // {
        //     perror("Binding error");
        //     exit(1);
        // }

        printf("Server listening on %s:%d\n", SERVER_IP, SERVER_PORT1);
        // struct Packet num_packets_packet;

        // Receive the number of packets as the first packet
        addr_len = sizeof(client_addr1);
        ssize_t recv_bytes = recvfrom(sockfd1, &num_packets_packet, sizeof(num_packets_packet), 0, (struct sockaddr *)&client_addr1, &addr_len);

        if (recv_bytes == -1)
        {
            perror("Receive error");
            exit(1);
        }

        if (num_packets_packet.seq_number == -1)
        {
            expected_num_packets = atoi(num_packets_packet.data);

            char *received_data = (char *)malloc(expected_num_packets * MAX_PACKET_SIZE);
            if (received_data == NULL)
            {
                perror("Memory allocation error");
                exit(1);
            }
            memset(received_data, 0, expected_num_packets * MAX_PACKET_SIZE);
            printf("Expecting %d packets\n", expected_num_packets);
        }
        else
        {
            // Handle unexpected first packet (not containing the number of packets)
            printf("Unexpected first packet with sequence number %d\n", num_packets_packet.seq_number);
        }
        // expected_num_packets = 10;
        struct Packet1 *received_packets = malloc((expected_num_packets + 10) * sizeof(struct Packet1));
        for (int i = 0; i < expected_num_packets + 10; i++)
        {
            received_packets[i].flag_awk = 0;
            received_packets[i].ack = 0;
        }
        if (received_packets == NULL)
        {
            perror("Memory allocation error");
            exit(1);
        }

        // Initialize received_packets array
        for (int i = 0; i < expected_num_packets; i++)
        {
            strcpy(received_packets[i].data, "#");
        }
        srand(time(NULL)); // Seed for random number generation

        int expected_seq_number = 0;
        int flag[10] = {0};
        int l = 0;
        while (1)
        {
            // if(l==20){
            //     break;
            // }
            struct Packet data_packet;
            // data_packet.data = (char*)malloc(sizeof(char)*(MAX_PACKET_SIZE));
            socklen_t addr_len = sizeof(client_addr1);

            // Receive data packet from the client
            ssize_t recv_bytes = recvfrom(sockfd1, &data_packet, sizeof(data_packet), 0, (struct sockaddr *)&client_addr1, &addr_len);
            if (recv_bytes == -1)
            {
                perror("Receive error");
                exit(1);
            }

            // Simulate packet loss by randomly dropping some packets
            // flag[data_packet.seq_number] = 1;
            printf("%d %s\n", data_packet.seq_number, data_packet.data);
            // if (received_packets[data_packet.seq_number].seq_number == 0)
            // {
            // printf("Y")
            // }
            // if (strcmp(received_packets[data_packet.seq_number].data, "$$$$$$$$") == 0)
            // {

            strcpy(received_packets[data_packet.seq_number].data, data_packet.data);
            received_packets[data_packet.seq_number].seq_number = data_packet.seq_number;
            // received_packets[data_packet.flag_awk] = 1;
            printf("before receving\n");
            for (int i = 0; i < expected_num_packets; i++)
            {
                // received_packets[i].flag_awk = 1;
                printf("%s\n", received_packets[i].data);
            }
            if (data_packet.seq_number != 4)
            {
                char ack_packet[MAX_PACKET_SIZE];
                snprintf(ack_packet, sizeof(ack_packet), "%d", data_packet.seq_number);
                received_packets[data_packet.seq_number].ack = 1;
                sendto(sockfd1, ack_packet, strlen(ack_packet), 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
            }
            else

            {

                printf("ywsss %d %d\n", data_packet.seq_number, received_packets[data_packet.seq_number].flag_awk);
                if (received_packets[data_packet.seq_number].flag_awk == 0)
                {
                    printf("dropped packets %d\n", data_packet.seq_number);
                    // received_packets[data]
                    strcpy(received_packets[data_packet.seq_number].data, "#");
                    received_packets[data_packet.seq_number].flag_awk = 1;
                    received_packets[data_packet.seq_number].ack = 0;
                }
                else
                {
                    received_packets[data_packet.seq_number].ack = 1;
                }

                // continue;
            }

            printf("after receving\n");

            for (int i = 0; i < expected_num_packets; i++)
            {
                printf("%s\n", received_packets[i].data);
            }
            // l++;
            if (check1(received_packets) == 1)
            {
                break;
            }
        }
        char ack_packet[MAX_PACKET_SIZE];

        // snprintf(ack_packet, sizeof(ack_packet), "%s", done);
        strcpy(ack_packet, "DONE");
        // received_packets[data_packet.seq_number].ack = 1;
        sendto(sockfd1, ack_packet, strlen(ack_packet), 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));

        // Reconstruct and display the text
        printf("Received text: ");
        for (int i = 0; i < expected_num_packets; i++)
        {
            printf("%s", received_packets[i].data);
        }
        printf("\n");

        // send_packet(sockfd,data)
        close(sockfd1);
    }
    return 0;
}
