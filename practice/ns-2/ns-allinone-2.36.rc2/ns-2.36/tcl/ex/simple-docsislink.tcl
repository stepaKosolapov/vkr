#
# Copyright (c) 2012-2013 Cable Television Laboratories, Inc.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions, and the following disclaimer,
#    without modification.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The names of the authors may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# Alternatively, provided that this notice is retained in full, this
# software may be distributed under the terms of the GNU General
# Public License ("GPL") version 2, in which case the provisions of the
# GPL apply INSTEAD OF those given above.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Authors:
#   Greg White <g.white@cablelabs.com>
#   Joey Padden <j.padden@cablelabs.com>
#   Takashi Hayakawa <t.hayakawa@cablelabs.com>
#
# simple-docsislink.tcl

#Create a Simulator
set ns [new Simulator]

#Create a trace file
#set mytrace [open out-docsis.tr w]
#$ns trace-all $mytrace

#Create a NAM trace file
set myNAM [open out.nam w]
$ns namtrace-all $myNAM

# Define a procedure finish
proc finish {} {
    global ns fname myNAM
    $ns flush-trace
    close $myNAM
    exit 0
}

# ------- config info is all below this line ----------

# DOCSIS Upstream values
# bwus              sets the upstream link phy bandwidth
# maxsustained      configures the cable modem upstream service flow token bucket rate limit
# maxburst          configures number of bytes to allow to burst at peakrate
# peakrate          peak burst bandwidth rate
# mapint            sets the DOCSIS MAP interval, this is the upstream transmission grant period
# dynamic_bw        toggles DOCSIS congestion model:
#                   0 = no congestion, 1 = light congestion, 2 = moderate congestion, 3 = heavy congestion
# dynamic_interval  sets the time spent at each throughput rate in congestion model
# grantvar          is the grant-to-grant variability as percent of the mean for the congested cases
# bufsize           sets the buffersize in seconds @ maxsustained rate

# experiment settings
# stopTime          sets the length of the simulation run in seconds
# psize             sets the nominal packet size used for buffer scaling calculations
# nominal_rtt       sets the nominal round trip time used for bandwidth delay product calculation


#DOCSIS Downstream values - maxburstDS configured to approx. 5 sec @ peakrateDS
# bwds              sets the downstream link phy bandwidth
# maxsustainedDS    sets the cable modem downstream service flow token bucket rate limit
# maxburstDS        sets the number of bytes allow to purst at peakrateDS
# peakrateDS        sets the peak burst bandwidth rate

# bandwidth and buffersize for all the links between model and application nodes
# linkbw            sets the bandwidth for ethernet modeled links between CM/CMTS and server/client
# linkbuffersize    sets buffer sizes for the same links


# DOCSIS Upstream values - maxburst configured to approx. 10 sec @ peakrate
    set bwus [bw_parse 100Mb]
    set maxsustained [bw_parse 2Mb]
    set maxburst 6250000
    set peakrate [bw_parse 5Mb]
    set mapint .002
    set dynamic_bw 1
    set dynamic_interval 5
    set grantvar 20
    set bufsize 1

# experiment settings
    set stopTime 61
    set psize 1500
    set nominal_rtt [delay_parse 100ms]

#DOCSIS Downstream values - maxburstDS configured to approx. 5 sec @ peakrateDS
    set bwds [bw_parse 32Mb]
    set maxsustainedDS [bw_parse 10Mb]
    set maxburstDS 10000000
    set peakrateDS [bw_parse 15Mb]

# bandwidth and buffersize for all the links between model and application nodes
    set linkbw [bw_parse 1000Mb]
    set linkbuffersize 25000

# ------- config info is all above this line ----------

#DOCSIS MAC upstream params
DocsisLink set maxgrant_ [expr $peakrate * $mapint/8]
if { $dynamic_bw == 0 } {
    DocsisLink set mgvar_ 1
} else {
    DocsisLink set mgvar_ $grantvar
}
DocsisLink set mapint_ $mapint
puts "upstream link mean capacity = $maxsustained"

#set docsis rate shaper
DocsisLink set rate_ $maxsustained
DocsisLink set bucket_ $maxburst
DocsisLink set peakrate_ $peakrate

#bdp in packets, based on the nominal rtt
set bdp [expr round($maxsustained*$nominal_rtt/(8*$psize))]

#buffersizes
Queue/DropTail set queue_in_bytes_ true
set CMbuffersize [expr round($maxsustained*$bufsize/(8*500))]

#Create Nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

#Connect Client Node with CM node
$ns duplex-link $n0 $n1 $linkbw 1ms DropTail
$ns queue-limit $n0 $n1 $linkbuffersize
$ns queue-limit $n1 $n0 $linkbuffersize

#Connect CM to CMTS over DOCSIS model for upstream
$ns simplex-link $n1 $n2 $bwus 1ms DropTail DocsisLink
$ns simplex-link-op $n1 $n2 orient right
$ns simplex-link-op $n1 $n2 queuePos 0.5
$ns queue-limit $n1 $n2 $CMbuffersize

#Connect CMTS to CM via downstream model: node 2 -> node 1, attached using a token bucket link
$ns simplex-link $n2 $n1 $bwds 1ms DropTail DelayLinkTb
set buff [expr round(250000/$psize)]
puts "CMTS downstream buffer $buff"
$ns queue-limit $n2 $n1 $buff
[[$ns link $n2 $n1] link] set rate_ $maxsustainedDS
[[$ns link $n2 $n1] link] set bucket_ $maxburstDS
[[$ns link $n2 $n1] link] set peakrate_ $peakrateDS

#third link from CMTS to server
$ns duplex-link $n2 $n3 1000Mb 1ms DropTail

#setup dynamic bandwidth on the DocsisLink
if { $dynamic_bw != 0 } {

switch $dynamic_bw {
    1 {  #light congestion
        set us_rates(1) [bw_parse 1.65Mb]
        set us_rates(2) [bw_parse 2.00Mb]
        set us_rates(3) [bw_parse 2.25Mb]
        set us_rates(4) [bw_parse 2.50Mb]
    }
    2 { #moderate congestion
        set us_rates(1) [bw_parse 1.85Mb]
        set us_rates(2) [bw_parse 1.90Mb]
        set us_rates(3) [bw_parse 2.00Mb]
        set us_rates(4) [bw_parse 2.25Mb]
    }
    3 { #heavy congestion
        set us_rates(1) [bw_parse 1.00Mb]
        set us_rates(2) [bw_parse 1.20Mb]
        set us_rates(3) [bw_parse 1.80Mb]
        set us_rates(4) [bw_parse 2.00Mb]
    }
    default {
        puts "Improper RF congestion selection: $dynamic_bw.   Must be 0,1,2,3. Exiting."
        exit 1
    }
}
array names us_changes
set us_changes(1) $us_rates(2)
set us_changes(2) $us_rates(1)
set us_changes(3) $us_rates(2)
set us_changes(4) $us_rates(3)
set us_changes(5) $us_rates(1)
set us_changes(6) $us_rates(3)
set us_changes(7) $us_rates(2)
set us_changes(8) $us_rates(4)
set us_changes(9) $us_rates(1)
set us_changes(10) $us_rates(4)
set us_changes(11) $us_rates(3)
set us_changes(12) $us_rates(4)

puts "upstream starts at max grant of [expr $maxsustained * $mapint/8]"

    set k 1
    for {set changeTime 0} {$changeTime <= $stopTime} {incr changeTime $dynamic_interval} {
        set newMG [expr $us_changes($k) * $mapint/8]
        puts "change at $changeTime to $newMG and mean capacity of $us_changes($k)"
        $ns at $changeTime "[[$ns link $n1 $n2] link] set maxgrant_ $newMG"
        set k [expr {($k % 12) + 1} ]
    }
}


#trace
set fname simple-docsis-queue.tr
puts "fname=$fname"
$ns trace-queue $n1 $n2 [open $fname w]

# Create a UDP agent
set udp [new Agent/UDP]
$ns attach-agent $n0 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null
$udp set fid_ 1

# Create a CBR traffic source
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set packetSize_ 1000
$cbr set rate_ 5Mb

# Create a TCP agent
set tcp [new Agent/TCP]
$ns attach-agent $n0 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink
$ns connect $tcp $sink
$tcp set fid_ 2

# Create an FTP session
set ftp [new Application/FTP]
$ftp attach-agent $tcp

# Schedule events
$ns at 0.05 "$ftp start"
$ns at 0.1 "$cbr start"
$ns at [expr $stopTime - 1] "$ftp stop"
$ns at [expr $stopTime - 0.5] "$cbr stop"
$ns at $stopTime "finish"

#  Start the simulation
$ns run
