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

import matplotlib
import os
if "DISPLAY" not in os.environ:
    matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scapy.utils import hexdump
from scapy.all import *

import numpy as np

noTitle = True
legendCenter = False

def plotIperf3(raw_data):

    plt.figure(1)
    fig = plt.gcf()
    fig.canvas.set_window_title('IPerf3')
    plt.subplot(211)

    x_values = [0]
    y_values = [0]
    for data in raw_data:
        x_val = data[0]['start']
        y_val = 0
        for x in data:
            y_val += x['rtt']/1000.0
        y_val = y_val/len(data)
        x_values.append(x_val)
        y_values.append(y_val)
    plt.plot(x_values, y_values)
    plt.ylim(ymin = 0)
    plt.ylabel('RTT [ms]')
    ax = plt.gca()
    ax.set_xticklabels([])

    plt.subplot(212)
    x_values = [0]
    y_values = [0]
    for data in raw_data:
        x_val = data[0]['start']
        y_val = 0
        for x in data:
            y_val += x['bytes'] / x['seconds']
        y_val = y_val/1000
        x_values.append(x_val)
        y_values.append(y_val)
    plt.plot(x_values, y_values)
    plt.ylim(ymin = 0)
    plt.xlabel('time [s]')
    plt.ylabel('Throughput [kbytes/s]')
    if not noTitle:
        plt.suptitle('iperf3 json output')
    fig = plt.gcf()
    fig.set_size_inches(6, 3, forward=True)
    plt.savefig('out/iperf3.pdf', bbox_inches='tight')

def plot_multiple_iperf3_runs(runs):

    plt.figure(2)
    fig = plt.gcf()
    fig.canvas.set_window_title('Multiple Iperf Runs')
    x_vals = []
    run_ids = [10, 20, 50] #TODO
    i = 0
    style_list = ['-', '--', ':']
    for x in runs[0]:
        x_vals.append(x[0]['start']) #start time of first tcp flow in this time section
    print("print all runs in a single graph here")
    for run_id in run_ids:
        y_vals = []
        for x in runs[run_id]:
            y_val = 0.0
            for y in x:
                y_val += y['rtt'] / 1000.0
            y_val = y_val / len(x)
            y_vals.append(y_val)
        rtt = run_id
        plt.plot(x_vals, y_vals, style_list[i], label = "link delay = "+str(rtt)+" ms")
        i+=1
    plt.ylim(ymin=0)
    plt.ylabel('RTT [ms]')
    plt.xlabel('time [s]')
    if legendCenter:
        plt.legend(shadow=True, bbox_to_anchor=[0.5, 0.6],
           loc='center', ncol=2) #, fontsize='x-large'
    else:
        plt.legend(shadow=True, bbox_to_anchor=[1, 0.63],
                  loc='right', ncol=1)  # , fontsize='x-large'
    fig = plt.gcf()
    fig.set_size_inches(6, 3, forward=True)
    plt.savefig('out/multipleIperfRuns.pdf', bbox_inches='tight')


def plotPcapTrace(trace):
    plt.figure(3)
    fig = plt.gcf()
    fig.canvas.set_window_title('Pcap Trace')
    plt.subplot(211)

    x_values = []
    y_values = []
    basetime = trace[0][0].time
    for tuple in trace:
        a = tuple[0]
        b = tuple[1]
        diff = float(b.time - a.time)*1000.0
        x_val = (a.time - basetime)
        y_val = diff
        x_values.append(x_val)
        y_values.append(y_val)
    plt.plot(x_values, y_values)
    plt.ylim(ymin = 0)
    plt.ylabel('delay [ms]')
    # plt.xlabel('time [s]')
    ax = plt.gca()
    ax.set_xticklabels([])

    plt.subplot(212)
    x_values = []
    y_values = []
    basetime = trace[0][0].time
    p = []
    n = 10
    for i in range(0, n):
        p.append(trace[0][1])
    i = 0.0
    for tuple in trace:
        i += 1
        p[n - 1] = tuple[1]
        if (i < n):
            diff = float(p[n - 1].time - p[0].time) / i  # error correction for the n first entries
        else:
            diff = float(p[n - 1].time - p[0].time) / n  # microseconds per packet
        x_val = (p[n - 1].time - basetime)
        if diff == 0:
            y_val = 0
        else:
            y_val = 1 / diff
        x_values.append(x_val)
        y_values.append(y_val)
        for j in range(0, n - 1):
            p[j] = p[j + 1]
    plt.plot(x_values, y_values)
    plt.ylim(ymin = 0)
    plt.ylabel('rate [pps]')
    plt.xlabel('time [s]')
    if not noTitle:
        plt.suptitle('bmv2 pcap analysis')
    fig = plt.gcf()
    fig.set_size_inches(6, 3, forward=True)
    plt.savefig('out/pcapTrace.pdf', bbox_inches='tight')

def plotPcapBandwidth(trace):
    plt.figure(4)
    fig = plt.gcf()
    fig.canvas.set_window_title('Pcap Out Bandwidth')
    x_values = []
    y_values = []
    basetime = trace[0][0].time
    p = []
    n = 50
    for i in range(0, n):
        p.append(trace[0][1])
    i = 0
    for tuple in trace:
        i+=1
        p[n-1] = tuple[1]
        if(i < n):
            diff = (p[n - 1].time - p[0].time) / i #error correction for the n first entries
        else:
            diff = (p[n-1].time - p[0].time)/n # microseconds per packet
        x_val = (p[n-1].time - basetime)
        if diff == 0:
            y_val = 0
        else:
            y_val = 1/diff
        x_values.append(x_val)
        y_values.append(y_val)
        for j in range(0, n-1):
            p[j] = p[j+1]
    plt.plot(x_values, y_values)
    plt.ylabel('rate [pps]')
    plt.xlabel('time [s]')
    if not noTitle:
        plt.title('pcap outgoing bandwidth')
    fig = plt.gcf()
    fig.set_size_inches(6, 3, forward=True)
    plt.savefig('out/pcapBandwidth.pdf', bbox_inches='tight')

def plotPcapInBandwidth(in_trace):
    plt.figure(5)
    fig = plt.gcf()
    fig.canvas.set_window_title('Pcap In Bandwidth')
    x_values = []
    y_values = []
    basetime = in_trace[0].time
    p = []
    n = 50
    for i in range(0, n):
        p.append(in_trace[0])
    i = 0
    for p_in in in_trace:
        i+=1
        p[n-1] = p_in
        if(i < n):
            diff = (p[n - 1].time - p[0].time) / i #error correction for the n first entries
        else:
            diff = (p[n-1].time - p[0].time)/n # microseconds per packet
        x_val = (p[n-1].time - basetime)
        if diff == 0:
            y_val = 0
        else:
            y_val = 1/diff
        x_values.append(x_val)
        y_values.append(y_val)
        for j in range(0, n-1):
            p[j] = p[j+1]
    plt.plot(x_values, y_values)
    plt.ylabel('rate [pps]')
    plt.xlabel('time [s]')
    if not noTitle:
        plt.title('pcap ingoing bandwidth')
    fig = plt.gcf()
    fig.set_size_inches(6, 3, forward=True)
    plt.savefig('out/pcapInBandwidth.pdf', bbox_inches='tight')

def plotPcapQueueDelay(trace):
    plt.figure(6)
    fig = plt.gcf()
    fig.canvas.set_window_title('Pcap Queue Delay')
    x_values = []
    y_values = []
    basetime = trace[0][0].time
    for tuple in trace:
        packet = tuple[1] ##only egress is interesting for us
        x_val = float(packet.time-basetime)
        if packet['IP'].len < 500:
            continue
        tcp = packet['TCP']
        payload = tcp.payload
        data = raw(payload)
        a = orb(data[0])
        b = orb(data[1])
        c = orb(data[2])
        d = orb(data[3])
        delay = (a << 24) + (b << 16) + (c << 8) + d
        y_val = delay/1000.0
        x_values.append(x_val)
        y_values.append(y_val)

    plt.plot(x_values, y_values)
    plt.plot([0, x_values[len(x_values) - 1] + 0.2], [5, 5], '--', color='C5')
    plt.ylabel('queue delay [ms]')
    plt.xlabel('time [s]')
    if not noTitle:
        plt.title('p4 queue delay')
    fig = plt.gcf()
    fig.set_size_inches(6, 3, forward=True)
    plt.savefig('out/pcapQueueDelay.pdf', bbox_inches='tight')

def show_plots():
    plt.show()
