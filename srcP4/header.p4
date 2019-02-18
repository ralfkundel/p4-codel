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

struct routing_metadata_t {
    bit<16> tcpLength;
}

struct codel_t {
    bit<48> drop_time;
    bit<48> time_now;
    bit<1>  ok_to_drop;
    bit<1>  state_dropping;
    bit<32> delta;
    bit<48> time_since_last_dropping;
    bit<48> drop_next;
    bit<32> drop_cnt;
    bit<32> last_drop_cnt;
    bit<1>  reset_drop_time;
    bit<48> new_drop_time;
    bit<48> new_drop_time_helper;
    bit<9>  queue_id;
}

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ethertype;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header udp_t {
    bit<16> sourcePort;
    bit<16> destPort;
    bit<16> length_;
    bit<16> checksum;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header tcp_opt_t {
    bit<32> a;
    bit<32> b;
    bit<32> c;
}

header queue_delay_t {
    bit<32> delay;
}

struct headers {
    ethernet_t    ethernet; 
    ipv4_t        ipv4; 
    queue_delay_t queue_delay; 
    tcp_t         tcp; 
    tcp_opt_t     tcp_options; 
    udp_t         udp;
}

struct metadata {
    codel_t             codel; 
    routing_metadata_t  routing_metadata;
}




