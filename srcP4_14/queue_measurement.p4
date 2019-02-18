/*
* Copyright 2018-present Ralf Kundel
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

header queue_delay_t queue_delay;

control c_add_queue_delay {
    if(ipv4.totalLen > 500){
        if(valid(queue_delay)){
            apply(t_addQueueDelay);
        }
    }
}

table t_addQueueDelay {
	actions {
		addQueueDelay;
	}
}

action addQueueDelay(){
    modify_field(queue_delay.delay , queueing_metadata.deq_timedelta);
}
