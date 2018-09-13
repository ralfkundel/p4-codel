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

import argparse
import os, sys
import json
from plotting import *
from scapy.all import *


def parse_multi_iperf3_json(folder):
    range = [0, 2, 5, 10, 20, 50]
    all_runs = {}
    for i in range:
        path = os.path.join(folder, "iperf_output"+str(i)+".json")
        if not os.path.isfile(path):
            return None
        parse_result = parse_iperf3_json(path)
        all_runs[i] = parse_result
    return all_runs



def parse_iperf3_json(path):
    content = readFiletoString(path)
    content = json.loads(content)
    #now content is a dict
    loRawInputs = content['intervals']
    resLst = []
    for x in loRawInputs:
        innerLst = []
        for y in x['streams']:
            innerLst.append(y) #TODO hier wird nur der erste Stream geparst
        resLst.append(innerLst)
    return  resLst

def parse_ping_trace(folder, dropFirstN=0):
    content = readFiletoString(os.path.join(folder, "ping_out.txt"))
    lines=content.splitlines()
    del lines[0] #"'PING 10.0.0.4 (10.0.0.4) 56(84) bytes of data.'"
    del lines[:dropFirstN]
    del lines[-4:] #delete last lines
    result = []
    for line in lines:
        splitline = line.split(" ")
        ping_time = splitline[6].replace("time=", "")
        result.append(float(ping_time))
    return result

def parse_pcap_trace(folder):
    packets_in = rdpcap(os.path.join(folder, "r1-eth1_out.pcap"))
    packets_out = rdpcap(os.path.join(folder, "r1-eth2_in.pcap"))
    out_pointer = 0
    print("number  ingoing packets: "+str(len(packets_in)))
    print("number outgoing packets: "+str(len(packets_out)))
    resLst = []
    length = len(packets_out)
    dropLst = []
    basePacket = packets_in[0]
    counterDrops = 0
    for packet in packets_in:
        if (length == out_pointer):
            break
        out_packet = packets_out[out_pointer]
        tcp_in = packet['TCP']
        tcp_out = out_packet['TCP']
        match = tcp_in.seq == tcp_out.seq
        if(match):
            out_pointer+=1
            resLst.append((packet, out_packet))
        else:
            counterDrops = counterDrops + 1
            print("Packet dropped: " + str(packet.time - basePacket.time))
            dropLst.append(packet)
    print("number drops: " + str(counterDrops))
    print("number matched packets: "+str(len(resLst)))
    return packets_in, resLst

def readFiletoString(file_name):
    file = open(file_name, "r")
    content = file.read()
    return content



def evaluate(folder):
    if not check_for_pcap(folder):
        return
    out_folder = os.path.join(os.getcwd(), folder)
    #evaluate_iperf(out_folder)
    #pingResLst = parse_ping_trace(out_folder)

    pcap_in_trace, pcap_trace = parse_pcap_trace(out_folder)
    plotPcapTrace(pcap_trace)
    plotPcapInBandwidth(pcap_in_trace)
    plotPcapBandwidth(pcap_trace)
    plotPcapQueueDelay(pcap_trace)

def evaluate_iperf(folder):
    out_folder = os.path.join(os.getcwd(), folder)
    iperf3_file = os.path.join(out_folder, "iperf_output.json")
    if not os.path.isfile(iperf3_file):
        return
    iperf3ResLst = parse_iperf3_json(iperf3_file)
    plotIperf3(iperf3ResLst)

def evaluate_multi_iperf(folder):
    res = parse_multi_iperf3_json(folder)
    if res != None:
        plot_multiple_iperf3_runs(res)

def check_for_pcap(folder):
    packets_in = os.path.join(folder, "r1-eth1_out.pcap")
    packets_out = os.path.join(folder, "r1-eth2_in.pcap")
    if not os.path.isfile(packets_in):
        return False
    if not os.path.isfile(packets_out):
        return False
    return True

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Processes the mininet out files and creates statistics')
    parser.add_argument('Path', nargs='?', default="out", help='path to out folder')
    parser.add_argument('--gui', help='Show plots in a GUI',
                        type=bool, action="store")
    parser.set_defaults(gui=False)
    args = parser.parse_args()
    folder = args.Path

    evaluate_multi_iperf(folder)

    evaluate_iperf(folder)

    evaluate(folder)

    if args.gui:
        show_plots()
