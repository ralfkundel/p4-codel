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

import subprocess
import time
import os, sys, glob

class IperfTest():
    def IperfTest(self, a, b, c, d):
        #self.startPingTest(c, d)
        #time.sleep(2)
        self.startIperfTest(a, b)
        #time.sleep(1)
        #self.stopPingTest(c)
        self.copyFiles()

    def copyFiles(self): #dirty workaround
        for file in glob.glob("*.pcap"):
            os.rename(file, "out/"+file)

    # data are transmitted from a to b
    def startIperfTest(self, a, b):
        cmd1 = ["iperf3", "-s", "&"]
        b.cmd(cmd1)
        print('start iperf3 test')
        cmd2 = ["iperf3", "-c", str(b.IP()), "-J", "-t 10", "-i 0.1", "-P 1"]
        out = a.cmd(cmd2)
        b.sendInt()
	print("finished iperf3 test")
        self.writeStringToFile("out/iperf_output.json", out)
        #print(out)

    def startPingTest(self, a, b):
        cmd = ["ping", str(b.IP()), "-i 0.1"]
        output = a.sendCmd(cmd)
        print(output)

    def stopPingTest(self, a):
        a.sendInt()
        time.sleep(1)
        out = a.waitOutput()
        self.writeStringToFile("out/ping_out.txt", out)
        print(out)

    def writeStringToFile(self, file_name, content):
        if not os.path.exists(os.path.dirname(file_name)):
            os.mkdir(os.path.dirname(file_name))
        file = open(file_name, "w")
        file.write(content)
        file.close()
