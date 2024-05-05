#
# Copyright (c) 1995 The Regents of the University of California.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University nor of the Laboratory may be used
#    to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# This test suite calls out to ../ex/sfqcodel-test.tcl to run selected
# configurations of that test suite (which was provided as an example)
# 
# sfqcodel-test.tcl is parameterized as follows:
# ns sfqcodel.tcl f w c {b}Mb s d r
# where:
#       f = # ftps
#       w = # PackMime connections per second
#       c = # CBRs
#       b = bottleneck bandwidth in Mbps
#       s = filesize for ftp, -1 for infinite
#       d = dynamic bandwidth, if non-zero, changes (kind of kludgey)
#               have to set the specific change ratios in this file (below)
#       r = number of "reverse" ftps
#
# To run all tests:  ./test-all-sfqcodel
#
# To view a list of available tests to run with this script:
# ns test-suite-sfqcodel.tcl
#
# To run individual tests:
# ../../ns test-suite-sfqcodel.tcl SfqCoDel
# ...
#

proc usage {} {
        global argv0
        puts stderr "usage: ns $argv0 <tests> "
        puts stderr "Valid tests are:\t[get-subclasses TestSuite Test/]"
        exit 1
}

proc isProc? {cls prc} {
        if [catch "Object info subclass $cls/$prc" r] {
                global argv0
                puts stderr "$argv0: no such $cls: $prc"
                usage
        }
}

proc get-subclasses {cls pfx} {
        set ret ""
        set l [string length $pfx]

        set c $cls
        while {[llength $c] > 0} {
                set t [lindex $c 0]
                set c [lrange $c 1 end]
                if [string match ${pfx}* $t] {
                        lappend ret [string range $t $l end]
                }
                eval lappend c [$t info subclass]
        }
        set ret
}


Class TestSuite
TestSuite instproc init {} {
	$self instvar ns_ 
	set ns_ [new Simulator]
}

TestSuite proc runTest {} {
	global argc argv quiet

	set quiet false
	switch $argc {
		1 {
			set test $argv
			isProc? Test $test
		}
		2 {
			set test [lindex $argv 0]
			isProc? Test $test

			set quiet [lindex $argv 1]
			if {$quiet == "QUIET"} {
				set quiet true
			}
		}
		default {
			usage
		}
	}
	set t [new Test/$test]
	$t run
}

# codel-test.tcl defaults
Class Test/SfqCoDel -superclass TestSuite

Test/SfqCoDel instproc init {} {
  $self instvar test_
  set test_ SfqCoDel
}
Test/SfqCoDel instproc run {} {
    $self instvar test_
    exec ../../ns ../ex/sfqcodel-test.tcl
    # move output trace to temp.rands so test-all-template1 can process it
    exec mv sfqcodel-redqvar.tr temp.rands
    exit 0 
}

# Exercise non-defaults for all command-line arguments
# num_ftps=2, web_rate=0, num_cbrs=1, bottleneck=5Mb, filesize=inf,
# dynamic_bw=5, reverse=2
Class Test/SfqCoDel_f2_w0_c1_b5_fsinf_d5_r2 -superclass TestSuite

Test/SfqCoDel_f2_w0_c1_b5_fsinf_d5_r2 instproc init {} {
  $self instvar test_
  set test_ SfqCoDel_f2_w0_c1_b5_fsinf_d5_r2
}
Test/SfqCoDel_f2_w0_c1_b5_fsinf_d5_r2 instproc run {} {
    $self instvar test_
    exec ../../ns ../ex/sfqcodel-test.tcl 2 0 1 5Mb -1 5 2
    # move output trace to temp.rands so test-all-template1 can process it
    exec mv sfqcodel-redqvar.tr temp.rands
    exit 0
}


TestSuite runTest

