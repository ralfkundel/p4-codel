# P4 Codel Implementation


## Install
For simple tests we recommend the use of our preinstalled VM.

### Preinstalled VM
A completely set up VM can be downloaded [here](ftp://ftp.kom.tu-darmstadt.de/VMs/P4-Codel.ova).
Please go to the codel folder and follow the Run-instructions of this Readme.
```
cd p4-codel
```
*Username:* **codel**
*Password:* **p4**

The VM is testet with Virtualbox. For Linux Users we recommend the use of a Host-only network and a ssh connection to the VM with X-forwarding. 
```
ssh -X codel@192.168.xxx.xxx
```
If you want to reproduce the results shown in the paper this virtual machine is not powerful enough. We recommend a bare-metal server with at least 6 cores for no thread interference.
### Setup
1. Install the following required tools:
    * [Mininet](https://github.com/mininet/mininet) - including **make install**
    * [P4 compiler bm](https://github.com/p4lang/p4c-bm)
    * [P4 behavioral model](https://github.com/p4lang/behavioral-model)

2. and in advance the following packages:
    ```
    sudo apt-get install openvswitch-testcontroller python-tk iperf3 xterm
    python -mpip install matplotlib
    pip install scapy
    ```
    
3. Clone the repository in the same parental folder than the 'behavioral-model'.

## Run
* Run Mininet with the P4(bmv2) CoDel implementation
```
./run.sh [--nocli, --nopcap]
```
Normally this script generates PCAP files for evaluation and enters the Mininet CLI mode for debugging.
With the optional command line parameters, this behavior can be changed.
* Run Mininet with a simple P4(bmv2) router (fixed-sized FIFO)
```
./simple_run.sh [--nocli, --nopcap]
```
* Run Mininet with the Linux kernel CoDel implementation
```
./linux_run.sh [--nocli, --nopcap]
```
* Run Mininet with the P4(bmv2) CoDel implementation with different RTTs
```
./rtt_run.sh [--nocli, --nopcap]
```

## Evaluate
To evaluate the measured results run:
```
./evaluate.sh [--gui]
```
With the parameter '--gui' the generated plots will be displayed in a GUI.
In the folder 'exampleOutputs' you can find results for 1000 pps and 2000 pps bottleneck speed produced on a 8 core bare-metal server.

### Debug
If the Mininet CLI mode is active, you can look into the running p4-appliction with:
```
./start_bmv2_CLI.sh
```
