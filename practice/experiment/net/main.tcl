#===================================
#     Simulation parameters setup
#===================================
set val(chan)   Channel/WirelessChannel    ;# тип канала
set val(prop)   Propagation/TwoRayGround   ;# модель радио распространения
set val(netif)  Phy/WirelessPhy            ;# тип сетевого интерфейса
set val(mac)    Mac/802_11                 ;# тип MAC
set val(ifq)    Queue/DropTail/PriQueue    ;# тип очереди
set val(ll)     LL                         ;# тип уровня link
set val(ant)    Antenna/OmniAntenna        ;# антенна
set val(ifqlen) 50                         ;# максимальное кол-во пакетов ifq
set val(sn)     3                          ;# количество статичных узлов
set val(x)      1500                       ;# X измерение в топографии
set val(y)      1500                       ;# Y измерение в топографии
set val(stop)   500.0                      ;# время симуляции

$val(netif) set Pt_ 0.3

set argc [llength $argv]
for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    if {$arg == "-n"} {
       incr i
       set val(mn) [lindex $argv $i]
       continue
    }
    if {$arg == "-f"} {
       incr i
       set val(src) [lindex $argv $i]
       continue
    }
    if {$arg == "-o"} {
       incr i
       set val(out) [lindex $argv $i]
       continue
    }
    if {$arg == "-rp"} {
       incr i
       set val(rp) [lindex $argv $i]
       continue
    }
}

if { $val(rp) == "DSDV" } {
    Agent/DSDV set perup_          6        ;
    Agent/DSDV set use_mac_        0        ;
    Agent/DSDV set min_update_periods_ 2    ;
}

if { $val(rp) == "DSR" } {
    set val(ifq) CMUPriQueue
} else {
    set val(ifq) Queue/DropTail/PriQueue
}

set val(nn) [expr $val(sn) + $val(mn) ]

#===================================
#        Initialization        
#===================================
set ns_ [new Simulator]

set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)

set tracefile [open $val(out)/trace.tr w]
$ns_ trace-all $tracefile

set namfile [open $val(out)/trace.nam w]
$ns_ namtrace-all $namfile
$ns_ namtrace-all-wireless $namfile $val(x) $val(y)
set chan [new $val(chan)];

#===================================
#     Mobile node parameter setup
#===================================
$ns_ node-config -adhocRouting  $val(rp) \
        -llType        $val(ll) \
        -macType       $val(mac) \
        -ifqType       $val(ifq) \
        -ifqLen        $val(ifqlen) \
        -antType       $val(ant) \
        -propType      $val(prop) \
        -phyType       $val(netif) \
        -channel       $chan \
        -topoInstance  $topo \
        -agentTrace    ON \
        -routerTrace   ON \
        -macTrace      ON \
        -movementTrace ON

#===================================
#        Nodes Definition        
#===================================

for {set i 0} {$i < $val(nn) } {incr i} {
    set node_($i) [$ns_ node]	
}

source $val(src)

# Создаём стационарные устройства

set src_node_i $val(mn)
set sink_node_i [expr $src_node_i + 2]

$node_($src_node_i) set X_ 300
$node_($src_node_i) set Y_ 785
$node_($src_node_i) set Z_ 0

$node_([expr $src_node_i + 1]) set X_ 525
$node_([expr $src_node_i + 1]) set Y_ 605
$node_([expr $src_node_i + 1]) set Z_ 0

$node_($sink_node_i) set X_ 750
$node_($sink_node_i) set Y_ 425
$node_($sink_node_i) set Z_ 0

for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ initial_node_pos $node_($i) 10
}

# #===================================
# #        Agents Definition        
# #===================================
set tcp_0 [new Agent/TCP/Newreno]
$ns_ attach-agent $node_($src_node_i) $tcp_0
set sink_0 [new Agent/TCPSink]
$ns_ attach-agent $node_($sink_node_i) $sink_0
$ns_ connect $tcp_0 $sink_0
$tcp_0 set packetSize_ 1500

#===================================
#        Applications Definition        
#===================================
set ftp_0 [new Application/FTP]
$ftp_0 attach-agent $tcp_0
$ns_ at 0.1 "$ftp_0 start"
$ns_ at $val(stop) "$ftp_0 stop"

#===================================
#        Termination        
#===================================
proc finish {} {
    global ns_ tracefile namfile
    $ns_ flush-trace
    close $tracefile
    close $namfile
    exit 0
}
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns_ at $val(stop) "$node_($i) reset"
}
$ns_ at $val(stop) "$ns_ nam-end-wireless $val(stop)"
$ns_ at $val(stop) "finish"
$ns_ at $val(stop) "puts \"done\" ; $ns_ halt"
$ns_ run
