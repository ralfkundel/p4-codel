/*
* Copyright 2020-present Ralf Kundel
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
#include <tna.p4>
#include "header.p4"
#include "CoDel.p4"

parser SwitchIngressParser(packet_in packet, out headers_t hdr, out my_metadata_t meta, out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
		packet.extract(ig_intr_md);
		packet.advance(PORT_METADATA_SIZE);
		packet.extract(hdr.ethernet);
		transition accept;
	}

}

control SwitchIngress(
    inout headers_t hdr,
	inout my_metadata_t meta,
	in ingress_intrinsic_metadata_t ig_intr_md,
	in ingress_intrinsic_metadata_from_parser_t ig_intr_parser_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action send(bit<9> egress_port) {
		ig_intr_tm_md.ucast_egress_port = egress_port;
	}

	table t_l1_forwarding {
		key = {
			ig_intr_md.ingress_port : exact;
		}
		actions = {
			send;
		}
		size = 64;
	}



    apply{
        t_l1_forwarding.apply();
		meta.bridged_metadata.setValid();
		meta.bridged_metadata.ingress_tstamp = ig_intr_parser_md.global_tstamp;
        }
}

control SwitchIngressDeparser(packet_out packet, inout headers_t hdr, in my_metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
	  packet.emit(meta.bridged_metadata);
      packet.emit(hdr);  
    }

}

parser SwitchEgressParser(packet_in packet, out headers_t hdr, out my_metadata_t meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
		packet.extract(eg_intr_md);
		packet.extract(meta.bridged_metadata);
		packet.extract(hdr.ethernet);
		transition accept;
	}

}


control SwitchEgress(
    inout headers_t hdr,
	inout my_metadata_t meta,
	in egress_intrinsic_metadata_t eg_intr_md,
	in egress_intrinsic_metadata_from_parser_t eg_intr_parser_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

	CoDelEgress() codel_egress;

	apply{
		codel_egress.apply(	meta.bridged_metadata.ingress_tstamp, 
							eg_intr_parser_md.global_tstamp,
							eg_intr_md.egress_port,
							eg_intr_md_for_dprsr);
	}

}

control SwitchEgressDeparser(packet_out packet, inout headers_t hdr, in my_metadata_t meta, in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    apply {
      packet.emit(hdr);  
    }

}


Pipeline(SwitchIngressParser(),
	SwitchIngress(),
	SwitchIngressDeparser(),
	SwitchEgressParser(), 
	SwitchEgress(),
	SwitchEgressDeparser()) pipe;

Switch(pipe) main;
