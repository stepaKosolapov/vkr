BEGIN {
    seqno = -1; 
    droppedPackets = 0;
    receivedPackets = 0;
    count = 0;
} {
    event = $1
    time = $2
    pkt_size = $8
    level = $4
    if(level == "AGT" && event == "s" && seqno < $6) {
        seqno = $6;
    } else if((level == "AGT") && (event == "r")) {
        receivedPackets++;
    } else if (event == "D" && $7 == "tcp" && pkt_size > 512){
        droppedPackets++; 
    }
} END { 
    print receivedPackets/(seqno+1)*100;
}