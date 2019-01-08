/*
* Copyright 2018-present Ralf Kundel, Jeremias Blendin
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
#define add_queue_delay

#include "header.p4"
#include "codel.p4"

#ifdef add_queue_delay
#include "tcp_checksum.p4"
#include "queue_measurement.p4"
#endif

header ethernet_t ethernet;
header ipv4_t ipv4;
header udp_t udp;
header tcp_t tcp;
header tcp_opt_t tcp_options;
metadata queueing_metadata_t queueing_metadata;

/////////////////////////////////
//        begin parser         //
/////////////////////////////////

parser start {
	extract(ethernet);
	return select(ethernet.ethertype){
		0x0800: parse_ipv4;
		default: ingress;
	}
}

parser parse_ipv4 {
    extract(ipv4);
    set_metadata(routing_metadata.tcpLength, latest.totalLen);
    return select(ipv4.protocol){
		17: parse_udp;
        6: parse_tcp;
		default: ingress;
	}
}

parser parse_udp {
    extract(udp);
    return select(udp.destPort){
		//1234: parse_delay;
		default: ingress;
	}
}

parser parse_tcp {
    extract(tcp);
    #ifdef add_queue_delay
    return select(tcp.dataOffset){
        0x8: parse_payload;
        default: ingress;
    }
    #else
    return ingress;
    #endif
}
parser parse_payload {
    extract(tcp_options);
    #ifdef add_queue_delay
    extract(queue_delay);
    #endif
    return ingress;
}

/////////////////////////////////
//          end parser         //
/////////////////////////////////


/////////////////////////////////
//        begin tables         //
/////////////////////////////////

table forwarding {
	reads {
		standard_metadata.ingress_port : exact;
        ipv4.dstAddr : exact;
	}
	actions {
		forward;
	}
}

//Drops at the beginning with src_mac
action forward(egress_spec, dst_mac) {
	modify_field(standard_metadata.egress_spec, egress_spec);
    modify_field(ethernet.dst_addr, dst_mac);
}

action _drop () {
	drop() ;
}
action nop(){
}



/////////////////////////////////
//         end  tables         //
/////////////////////////////////


control ingress {
	apply(forwarding);
}

control egress {
    if (standard_metadata.ingress_port == 1) {
        c_codel();
    }
    #ifdef add_queue_delay
    c_add_queue_delay();
    apply(t_checksum);
    #endif
}
