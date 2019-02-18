/*
* Copyright 2018-present Ralf Kundel, Nikolas Eller
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

#include <core.p4>
#include <v1model.p4>

#define add_queue_delay //uncomment this line, if the queue delays should be stored in the TCP packets

#include "header.p4"
#include "codel.p4"

#ifdef add_queue_delay
#include "queue_measurement.p4"
#include "tcp_checksum.p4"
#endif

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        meta.routing_metadata.tcpLength = hdr.ipv4.totalLen;
        transition select(hdr.ipv4.protocol) {
            8w17: parse_udp;
            8w6: parse_tcp;
            default: accept;
        }
    }
    state parse_payload {
        packet.extract(hdr.tcp_options);
	#ifdef add_queue_delay
        packet.extract(hdr.queue_delay);
	#endif
        transition accept;
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
	#ifdef add_queue_delay
        transition select(hdr.tcp.dataOffset) {
            4w0x8: parse_payload;
            default: accept;
        }
	#else
	transition accept;
	#endif
    }
    state parse_udp {
        packet.extract(hdr.udp);
        /*transition select(hdr.udp.destPort) {
            default: accept;
        }*/
	transition accept;
    }
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ethertype) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    c_checksum() c_checksum_0;
    c_codel() c_codel_0;
    c_add_queue_delay() c_add_queue_delay_0;
    apply {
        if (standard_metadata.ingress_port == 9w1) {
            c_codel_0.apply(hdr, meta, standard_metadata);
        }
	#ifdef add_queue_delay
        c_add_queue_delay_0.apply(hdr, standard_metadata);
        c_checksum_0.apply(hdr, meta);
	#endif
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action forward(bit<9> egress_spec, bit<48> dst_mac) {
        standard_metadata.egress_spec = egress_spec;
        hdr.ethernet.dst_addr = dst_mac;
    }
    table forwarding {
        actions = {
            forward;
        }
        key = {
            standard_metadata.ingress_port: exact;
            hdr.ipv4.dstAddr              : exact;
        }
    }
    apply {
        forwarding.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.tcp_options);
        packet.emit(hdr.queue_delay);
        packet.emit(hdr.udp);
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

