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

#define SOJOURN_TARGET          5000000  //in nsec
#define CONTROL_INTERVAL      100000000 //in nsec

struct register_operations {
	bit<32>     val1;
	bit<32>     val2;
}

struct codel_metadata_t{
	bit<32> egress_tstamp;
	bit<32> queue_delay;
	bit<32> sojourn_remainder;
	bit<1> sojourn_violation;
	bit<1> first_sojourn_violation;
	bit<1> codel_drop;
}

control CoDelEgress (in bit<48> ingress_tstamp, 
                    in bit<48> egress_tstamp, 
                    in bit<9> egress_port, 
                    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr){

    codel_metadata_t codel_metadata;

    //Stateful ALU1
	Register< bit<32>, bit<9> > (32w512) codel_drop_state;
	RegisterAction<bit<32>, bit<9>, bit<1> >(codel_drop_state) codel_drop_state_action = {
		void apply(inout bit<32> drop_state, out bit<1> first_soujourn_violation){
			if(drop_state== 32w0x0  && codel_metadata.sojourn_violation == 1w0x1){
				first_soujourn_violation = 1w0x1;
			}else{
				first_soujourn_violation = 1w0x0;
			}
			if(codel_metadata.sojourn_violation == 1w0x1){
				drop_state = 32w0x1;
			}else {
				drop_state = 32w0x0;
			}
		}

	};

    //Stateful ALU2
	MathUnit< bit<32> > (true, -1, 20,
		{0x46, 0x48, 0x4b, 0x4e,
		0x52, 0x56, 0x5a, 0x60,
		0x66, 0x6f, 0x79, 0x87,
		0x0, 0x0, 0x0, 0x0}) sqrtn;
	//for tofino2 the following simplified mode can be used instead
		//MathUnit<bit<32>>(RSQRT, 1<<20) sqrtn;
	Register< register_operations, bit<9>> (32w512) codel_salu_2;
	RegisterAction<register_operations, bit<9>, bit<1> >(codel_salu_2) codel_salu_2_action = {
		void apply(inout register_operations inout_vals, out bit<1> out_val){
			//val2 == drop count
			//val1 == next_drop_time
			out_val = 1w0x0;
			if(codel_metadata.first_sojourn_violation == 1w0x1){
				inout_vals.val1 = codel_metadata.egress_tstamp + CONTROL_INTERVAL;
				inout_vals.val2 = 1;
			} else 
			if(codel_metadata.egress_tstamp > inout_vals.val1) {
				//we want to drop
				inout_vals.val2 = inout_vals.val2 + 1;
				inout_vals.val1 = inout_vals.val1  + sqrtn.execute(inout_vals.val2);
				out_val = 1w0x1;
			}
		}

	};

	action a_compute_remainder(){
		codel_metadata.sojourn_remainder = SOJOURN_TARGET |-| codel_metadata.queue_delay;
	}

	table t_compute_remainder {
		actions = {
			a_compute_remainder;
		}
		default_action = a_compute_remainder;
	}

	action a_drop(){
		eg_intr_md_for_dprsr.drop_ctl = 3w0x1;
	}

    apply{
		eg_intr_md_for_dprsr.drop_ctl = 3w0x0; //default value, otherwise the value is undefined in case of "non dropping" and everything can happen

		codel_metadata.egress_tstamp = (bit<32>) egress_tstamp;
		codel_metadata.queue_delay = (bit<32>)(egress_tstamp - ingress_tstamp);

		t_compute_remainder.apply();
		if(codel_metadata.sojourn_remainder == 0){
			codel_metadata.sojourn_violation = 1w0x1;
		}else{
			codel_metadata.sojourn_violation = 1w0x0;
		}
		codel_metadata.first_sojourn_violation = codel_drop_state_action.execute(egress_port);
		codel_metadata.codel_drop = codel_salu_2_action.execute(egress_port);
		if( (codel_metadata.codel_drop == 1w0x1) && (codel_metadata.sojourn_violation == 1w0x1) ){
			a_drop();
		}

    }
}
