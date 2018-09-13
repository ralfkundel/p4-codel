#!/usr/bin/python

# Copyright 2018-present Ralf Kundel, Jeremias Blendin, Nikolas Eller
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from mininet.node import Node

class LinuxRouter( Node ):
    "A Node with IP forwarding enabled."
    # taken from
    # https://github.com/mininet/mininet/blob/f530c99415d8215a0ab7dba4b55e7a64297dd268/examples/linuxrouter.py

    def config( self, **params ):
        super( LinuxRouter, self).config( **params )
        # Enable forwarding on the router
        self.cmd( 'sysctl net.ipv4.ip_forward=1' )
        #http://man7.org/linux/man-pages/man8/tc-codel.8.html

        self.cmd('tc qdisc add dev r1-eth2 handle 1: root htb default 11')
        self.cmd('tc class add dev r1-eth2 parent 1: classid 1:11 htb rate 24224kbit')
        self.cmd('tc qdisc add dev r1-eth2 parent 1:11 handle 2:0 codel limit 100000')
        print self.cmd('tc qdisc')


    def start(self):
        ret = self.cmd('tcpdump -i r1-eth1 -w r1-eth1_out.pcap not ether src 00:00:00:00:01:fe &')
        print(ret)
        ret = self.cmd('tcpdump -i r1-eth2 -w r1-eth2_in.pcap not ether dst 00:00:00:00:02:fe &')
        print(ret)

    def terminate( self ):
        self.cmd( 'sysctl net.ipv4.ip_forward=0' )
        print("terminate LinuxRouter")
