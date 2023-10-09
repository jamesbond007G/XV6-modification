## Title: Enhancing UDP Reliability Through Sequencing and Retransmission

## Abstract:
In this report, we present an implementation that enhances the reliability of User Datagram Protocol (UDP) by incorporating key features typically associated with Transmission Control Protocol (TCP). UDP is known for its simplicity and low overhead but lacks built-in mechanisms for data sequencing and retransmission, which are crucial for ensuring reliable data transfer. Our approach combines the lightweight nature of UDP with sequencing and retransmission capabilities to provide a reliable data transfer solution. We also discuss options for implementing flow control to further enhance reliability.

## 1. Introduction:
UDP is a connectionless protocol that offers low latency and minimal overhead. However, it does not guarantee the order of packet delivery nor does it include automatic retransmission of lost packets. In contrast, TCP ensures data reliability through features such as sequencing, acknowledgment, and retransmission. Our implementation bridges this gap by adding sequencing and retransmission capabilities to UDP while maintaining its efficiency.

## 2. Explanation :
First, sender will send a message by dividing message into chunks then assigning each chunk a new seqeunce number and storing both in struct packet, then i will send all the packets to the receiver, and after that will wait for either retramsission or acknowledgement, if it receives acknowledgement within a particular time then i am setting it to 1, else if it exceeds the time we will rsend the the same packet of whom we have not received acknowldegment, we will contiue it till all packets have not been marked acknowledged, 
on receiver side I am receving all the packets and sending acknwoledgement for the particular packet, now for checking retransmission i am dropping packet with sequence number 4 once. 
I am making message at the same time packet is received,so on dropping packets i am deleting that chunk and replacing it again with #. to check if the packet is received after some time.
and at the end sending the done message to sender so that it can assure all packets is received and stop sending. 

## 3. Sequencing of Data:
In our implementation, we address the issue of unordered packet delivery in UDP by dividing the original message into smaller chunks. Each chunk is assigned a unique sequence number, creating a sequence of data packets. Alongside the message content, these sequence numbers are stored within a data structure called a "packet." The sender transmits these packets to the receiver, ensuring that the original message can be reconstructed correctly.

## 4. Retransmission Mechanism:
To address the lack of built-in retransmission in UDP, our implementation includes a retransmission mechanism. After sending the data packets, the sender awaits acknowledgments (ACKs) from the receiver within a specified time frame. If an ACK is not received within the allotted time, the sender resends the packet associated with the missing acknowledgment. This process continues until all packets have been acknowledged, ensuring that no data is lost during transmission.
## 5. Differences:
	1). Time Out interval: 
	in my implementation, i have kept the time out interval to be fixed, but in tcp it is varied according to time by formula. 
	2). fixed Sequence number : 
	in my implementation, i have kept fixed seqeunce number, but in tcp sequence number is kept random by complex algorithms for security purposes. 
	3). ACK Handling:
	UDP-Based Implementation: The receiver sends ACK packets for received data chunks. The sender uses these ACKs to determine which chunks need retransmission.
    	TCP: TCP includes more sophisticated acknowledgment mechanisms, including cumulative ACKs and selective acknowledgments (SACKs), to optimize retransmissions.
    	4). Error Handling:
	UDP-Based Implementation: Error detection and handling are simplified in this UDP-based approach. It relies on retransmission for error recovery.
    	TCP: TCP includes various error detection and recovery mechanisms, including checksums, retransmissions, and timeouts.
	5). TCP is a connection-oriented protocol, while UDP is connectionless. In our implementation, we are using UDP sockets to simulate some TCP-like features, but there is no actual connection setup or teardown.
	6).TCP provides reliable, in-order delivery of data. In contrast, our UDP-based approach involves manual sequencing of data chunks and retransmissions if ACKs are not received, mimicking reliability features of TCP.
	7).TCP has built-in congestion control and flow control mechanisms. Our implementation does not address flow control (yet)
    	
## 6. Flow Control:
While UDP offers minimal flow control capabilities, we introduce additional measures to enhance reliability. my approach will be s to include information about the receiver's buffer size in the packet. This informs the sender about the receiver's capacity, preventing the sender from oversending the receiver with too much data.
Or, a sliding window approach can be employed. 

Sliding Window Mechanism:

One common approach to implementing flow control is through the use of a sliding window mechanism. In this mechanism, both the sender and receiver maintain a window of sequence numbers that represents the allowable range of chunks to be sent and received.
Sender's Role:

    Sender's Window Size: The sender defines its sending window size, which determines the maximum number of unacknowledged chunks that can be in transit at any given time. This window size is dynamic and may vary based on feedback from the receiver.

    Sending Chunks: The sender starts by sending chunks within the current window, which is initially set to the size of the sender's buffer.

    ACK Reception: As ACKs are received from the receiver, the sender advances its window to allow for more chunks to be sent. For example, if ACKs for chunks 1 to 5 are received, the sender can advance the window to allow chunks 6 and beyond to be sent.

    Handling Window Constraints: If the sender's window is completely filled (i.e., all chunks in the window are unacknowledged), it must wait until an ACK is received before sending more data. This ensures that the sender doesn't overwhelm the receiver.

Receiver's Role:

    Receiver's Window Size: The receiver defines its receiving window size, which indicates how many chunks it can accept without overflowing its buffer.

    Buffer Space Availability: The receiver informs the sender of its buffer space availability using the ACK packets. For example, the ACK packet can include an acknowledgment number and a "window size" field.

    Accepting Chunks: The receiver accepts incoming chunks and processes them. It should only acknowledge chunks that it can accommodate in its buffer.

    Sending Window Updates: If the receiver's buffer space becomes available (e.g., due to processing and freeing up space), it updates its window size information in the ACK packets sent back to the sender.


## 7. Conclusion:
In conclusion, our implementation augments UDP's simplicity and efficiency with sequencing, retransmissions. This approach allows for reliable data transfer while maintaining low latency and reduced overhead compared to traditional TCP. It offers flexibility in adapting to various network conditions and requirements, making it a good choice for applications where a balance between reliability and performance is needed.

