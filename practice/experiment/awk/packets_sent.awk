BEGIN {
    seqno = -1;    
}{
    if ($4 == "AGT" && $1 == "s" && seqno < $6) {
        seqno = $6;
    }
} END {
    print seqno+1;
} 
