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

#define SOJOURN_TARGET 5000  //in usec - 5ms
#define CONTROL_INTERVAL 100000 //in usec - 100 ms - Changes must be done here AND in commandsCodelRouter.txt
#define INTERFACE_MTU 1500

header_type codel_t {
    fields {
        drop_time: 48;
        time_now : 48;
        ok_to_drop: 1;
        state_dropping: 1;
        delta: 32;
        time_since_last_dropping: 48;

        drop_next : 48;
        drop_cnt : 32;
        last_drop_cnt: 32;

        reset_drop_time : 1;
        new_drop_time : 48;

        // Control law variables
        new_drop_time_helper: 48;
    }
}

header_type queueing_metadata_t {
    fields {
        enq_timestamp : 48;
        enq_qdepth : 16;
        deq_timedelta : 32;
        deq_qdepth : 16;
        qid : 8;
    }
}


metadata codel_t codel;
metadata queueing_metadata_t queueing_metadata;


/////////////////////////////////
///// begin Ralf
/////////////////////////////////
action a_codel_init() {
    //for debugging
    modify_field(codel.ok_to_drop, 0);
    add(codel.time_now, queueing_metadata.enq_timestamp, queueing_metadata.deq_timedelta);
    add(codel.new_drop_time, codel.time_now, CONTROL_INTERVAL);
    register_read(codel.state_dropping , r_state_dropping, 0);
    register_read(codel.drop_cnt, r_drop_count, 0);
    register_read(codel.last_drop_cnt, r_last_drop_count, 0); //r_last_drop_count wird nie geschrieben...
    register_read(codel.drop_next, r_next_drop, 0);
    register_read(codel.drop_time, r_drop_time, 0);
}
action a_codel_init_no_sojourn_violation() {
    a_codel_init();
    modify_field(codel.reset_drop_time, 1);
    //inc_reg_statistic(0);
}
action a_codel_init_sojourn_violation() {
    a_codel_init();
    modify_field(codel.reset_drop_time, 0);
    //inc_reg_statistic(1);
}

table t_codel_init_no_sojourn_violation {
    actions {
        a_codel_init_no_sojourn_violation;
    }
}
table t_codel_init_sojourn_violation {
    actions {
        a_codel_init_sojourn_violation;
    }
}


register r_drop_time {
    width: 48;
    // static: t_drop_time;
    instance_count: 1;  //one per queue?
}


table t_set_drop_time {
    actions {
        a_set_drop_time;
    }
}
table t_reset_drop_time {
    actions {
        a_reset_drop_time;
    }
}
action a_set_drop_time (){ //TODO add queue id
    register_write(r_drop_time, 0, codel.new_drop_time);
    modify_field(codel.drop_time, codel.new_drop_time);
}
action a_reset_drop_time (){ //TODO add queue id
    register_write(r_drop_time, 0, 0);
    modify_field(codel.drop_time, 0);
}

table t_set_ok_to_drop {
    actions {
        a_set_ok_to_drop;
    }
}
action a_set_ok_to_drop (){
    modify_field(codel.ok_to_drop, 1);
    //inc_reg_statistic(2);
}

register r_state_dropping {
    width: 1;
    instance_count: 1;  //one per queue?
}

control c_codel {
    //stage 0:
    if (queueing_metadata.deq_timedelta < SOJOURN_TARGET or queueing_metadata.deq_qdepth < 1) { //TODO: check if it works correctly
        apply(t_codel_init_no_sojourn_violation);
    } else {
        apply(t_codel_init_sojourn_violation);
    }
    //stage 1:
    if (codel.reset_drop_time == 1) {
        apply(t_reset_drop_time);
    } else {
        if(codel.drop_time == 0){
            apply(t_set_drop_time);
        }
    }

    //stage 2:
    if (codel.reset_drop_time == 0) {
        if(codel.drop_time > 0){
            if(codel.time_now >= codel.drop_time){
                apply(t_set_ok_to_drop);
            }
        }
    }

    //stage 3:
    if(codel.state_dropping == 1){
        if(codel.ok_to_drop == 0){
            apply(t_stop_dropping);
        } else if (codel.time_now >= codel.drop_next) {
            apply(t_drop);
            apply(t_codel_control_law); //TODO
        }
    } else {
        if(codel.ok_to_drop == 1){
            //start dropping
            apply(t_start_dropping);
            //stage 4:
            if(codel.delta > 1 and codel.time_since_last_dropping < CONTROL_INTERVAL*16){
                apply(t_start_dropping_hard);
            }
            apply(t_codel_set_last_drpcnt);
            apply(t_codel_control_law); //TODO
        }
    }
    //if(...) { //every time we dropped ...
            //apply(t_codel_control_law);
    //}
}

table t_start_dropping {
    actions{
        a_go_to_drop_state;
    }
}

table t_stop_dropping{
        actions{
        a_go_to_idle_state;
    }
}
register r_drop_count {
    width: 32;
    instance_count: 1;  //one per queue?
}
register r_last_drop_count {
    width: 32;
    instance_count: 1;  //one per queue?
}

register r_next_drop {
    width: 48;
    instance_count: 1;  //one per queue?
}

action a_go_to_idle_state (){
    register_write(r_state_dropping, 0, 0); //go to idle state
    //inc_reg_statistic(7);
}

action a_go_to_drop_state (){
    drop();
    register_write(r_state_dropping, 0, 1); //go to drop state
    subtract(codel.delta, codel.drop_cnt, codel.last_drop_cnt);
    subtract(codel.time_since_last_dropping, codel.time_now, codel.drop_next);
    modify_field(codel.drop_cnt, 1);
    register_write(r_drop_count, 0, 1);
    //inc_reg_statistic(9);
}

table t_start_dropping_hard {
    actions {
        a_start_hard_dropping;
    }
}

action a_start_hard_dropping (){
    register_write(r_drop_count, 0 , codel.delta);
    modify_field(codel.drop_cnt, codel.delta);
}

table t_codel_set_last_drpcnt {
    actions{ a_codel_set_last_drpcnt;}
}

action a_codel_set_last_drpcnt (){
    register_write(r_last_drop_count, 0, codel.drop_cnt);
    //inc_reg_statistic(8);
}

//counter c_codel_control_law {
//    type : packets;
//    direct : t_codel_control_law;
//}

table t_codel_control_law {
    reads {
        codel.drop_cnt : lpm;
    }
    actions {
        a_codel_control_law;
    }
    size : 32;
}


action a_codel_control_law(value) {
    add(codel.drop_next, codel.time_now , value);
    register_write(r_next_drop, 0, codel.drop_next);
}

//for all drops n >= 3, first drop is done by a_go_to_drop_state
table t_drop {
    actions {
        a_drop_normal;
    }
}

register r_statistic {
    width: 32;
    instance_count: 11;
}

action a_drop_normal(){
    drop();
    add(codel.drop_cnt, codel.drop_cnt, 1);
    register_write(r_drop_count,0, codel.drop_cnt);
    //inc_reg_statistic(10);
}

//header_type foo_t {
//    fields {
//        foo: 32;
//    }
//}
//metadata foo_t foo;
//action inc_reg_statistic (i){
//    register_read(foo.foo, r_statistic, i);
//    modify_field(foo.foo, foo.foo + 1);
//    register_write(r_statistic, i, foo.foo);
//}
