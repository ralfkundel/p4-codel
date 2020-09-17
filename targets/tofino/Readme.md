# P4 CoDel for Barefoot Tofino
This code is a P4 CoDel implementation for Barefoot Tofino.
Last tested SDE is version 9.1.1. The SDE should be best compiled with all additional packages (such as thrift & grpc support).

## Preparation

### Compile
In order to compile, use the build script provided by the SDE:
```
../p4_build.sh /home/rkundel/p4_16-codel/l1switchCodel.p4 
```

### Window 1: switch control daemon
```
./run_switchd.sh -p l1switchCodel
```
This will take a few seconds. After the initialization process is finished, configure the ports. In this example, we will use port 64/0 and 64/1 for packet ingress and egress.

```
ucli
pm
port-add 64/- 10G NONE
port-enb 64/0
port-enb 64/1
show
```
After a few seconds the show command should show that the corresponding interfaces are up. If not, you can stop here and start debugging your physical links ;-)

### Window 2: switch control daemon
In a second window start the barefoot CLI with the following command in the SDE:
```
./run_bfshell.sh
```

In order to benefit from a lot of (python) features, we will do the following steps with the python runtime. This can be started with:
```
bfrt_python
```
Now enter the following commands in order to fill the Layer-1 routing tables. In fact, this table performs simple port bridging. E.g. all packets ingressing on port 412 will be sent out on port 413. The pipeline port mapping on phyiscal ports can be seen in Window 1, as described above.
```
bfrt.l1switchCodel.pipe.SwitchIngress.t_l1_forwarding.clear() 
bfrt.l1switchCodel.pipe.SwitchIngress.t_l1_forwarding.add_with_send(ingress_port=412, egress_port=413)
bfrt.l1switchCodel.pipe.SwitchIngress.t_l1_forwarding.add_with_send(ingress_port=413, egress_port=412)
```

### Window 3: Enable Port Shaping
The CoDel algorithm itself is on a per port base and do not require any table entries. However, the corresponding egress port queue must be configured to shape the traffic in order to build up a queue. For that, in a third window, start the following script of the SDE:
```
./run_pd_rpc.py
```
and enter the following commands:
```
tm.set_port_shaping_rate(412, False, 1600, 100000)
tm.enable_port_shaping(412)
```

## Run it
After setting it up, simply run your desired TCP load generator which is sending traffic over the two configured ports. E.g. iperf3 is a nice tool for testing the shaping behavior.

However, in order to observe the queueing delay, a tool like MoonGen or P4STA is needed. The iperf3 latency output is around one order of magnitude higher (30 to 100 ms) than the queueing delay (5 to 10 ms), caused by non-constant measurement errors.

