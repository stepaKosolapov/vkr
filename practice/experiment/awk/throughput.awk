BEGIN {
     recvdSize = 0
     startTime = 400
     stopTime = 0
} {
	event = $1
	time = $2
	node_id = $3
	pkt_size = $8
	level = $4
     if (level == "AGT" && event == "s" && pkt_size >= 512) {
          if (time < startTime) {
               startTime = time
          }
     }
     if (level == "AGT" && event == "r" && pkt_size >= 512) {
          if (time > stopTime) {
               stopTime = time
          }
          hdr_size = pkt_size % 512
          pkt_size -= hdr_size
          recvdSize += pkt_size
     }
} END {
     print (recvdSize/(stopTime-startTime))*(8/1000)
}