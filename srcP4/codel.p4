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

#define SOJOURN_TARGET 32w5000  //in usec - 5ms
#define CONTROL_INTERVAL 48w100000 //in usec - 100 ms - Changes must be done here AND in commandsCodelRouter.txt
#define INTERFACE_MTU 1500

register<bit<32>>(32w1) r_drop_count;
register<bit<48>>(32w1) r_drop_time;
register<bit<32>>(32w1) r_last_drop_count;
register<bit<48>>(32w1) r_next_drop;
register<bit<1>>(32w1) r_state_dropping;

control c_codel(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {

    action a_codel_control_law(bit<48> value) {
        meta.codel.drop_next = meta.codel.time_now + value;
        r_next_drop.write((bit<32>)0, (bit<48>)meta.codel.drop_next);
    }

    action a_codel_init() {
        meta.codel.ok_to_drop = 1w0;
        meta.codel.time_now = (bit<48>)standard_metadata.enq_timestamp + (bit<48>)standard_metadata.deq_timedelta;
        meta.codel.new_drop_time = meta.codel.time_now + CONTROL_INTERVAL;
        r_state_dropping.read(meta.codel.state_dropping, (bit<32>)0);
        r_drop_count.read(meta.codel.drop_cnt, (bit<32>)0);
        r_last_drop_count.read(meta.codel.last_drop_cnt, (bit<32>)0);
        r_next_drop.read(meta.codel.drop_next, (bit<32>)0);
        r_drop_time.read(meta.codel.drop_time, (bit<32>)0);
    }

    action a_go_to_drop_state() {
        mark_to_drop();
        r_state_dropping.write((bit<32>)0, (bit<1>)1);
        meta.codel.delta = meta.codel.drop_cnt - meta.codel.last_drop_cnt;
        meta.codel.time_since_last_dropping = meta.codel.time_now - meta.codel.drop_next;
        meta.codel.drop_cnt = 32w1;
        r_drop_count.write((bit<32>)0, (bit<32>)1);
    }

    table t_codel_control_law {
        actions = {
            a_codel_control_law;
        }
        key = {
            meta.codel.drop_cnt: lpm;
        }
        size = 32;
    }

    apply {
        a_codel_init();
        if (standard_metadata.deq_timedelta < SOJOURN_TARGET || standard_metadata.deq_qdepth < 19w1) { 
            meta.codel.reset_drop_time = 1w1;
        }

        if (meta.codel.reset_drop_time == 1w1) {
            r_drop_time.write(0, (bit<48>)0);
            meta.codel.drop_time = 48w0;
        }
        else {
            if (meta.codel.drop_time == 48w0) {
                r_drop_time.write(0, (bit<48>)meta.codel.new_drop_time);
                meta.codel.drop_time = meta.codel.new_drop_time;
            }
            else { //if (meta.codel.drop_time > 48w0)
                if (meta.codel.time_now >= meta.codel.drop_time) {
                    meta.codel.ok_to_drop = 1w1;
                }
            }
        }

        if (meta.codel.state_dropping == 1w1) {
            if (meta.codel.ok_to_drop == 1w0) {
                r_state_dropping.write(0, (bit<1>)0); //leave drop state
            }
            else {
                if (meta.codel.time_now >= meta.codel.drop_next) {
                    mark_to_drop();
        	    meta.codel.drop_cnt = meta.codel.drop_cnt + 32w1;
        	    r_drop_count.write(0, (bit<32>)meta.codel.drop_cnt);
                    t_codel_control_law.apply();
                }
            }
        }
        else {
            if (meta.codel.ok_to_drop == 1w1) {
                    a_go_to_drop_state();
                if (meta.codel.delta > 32w1 && meta.codel.time_since_last_dropping < CONTROL_INTERVAL*16) {
                    r_drop_count.write(0, (bit<32>)meta.codel.delta);
        	        meta.codel.drop_cnt = meta.codel.delta;
                }
                r_last_drop_count.write(0, (bit<32>)meta.codel.drop_cnt);
                t_codel_control_law.apply();
            }
        }
    }
}