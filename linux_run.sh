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

argsCommand=""

if [ "$1" = "--nopcap" ] || [ "$1" = "--nocli" ]; then
  argsCommand=$1" True"
fi

if [ "$2" = "--nopcap" ] || [ "$2" = "--nocli" ]; then
  argsCommand=$argsCommand" "$2" True"
fi

#delete old pcap files
sudo rm out/*.pcap
sudo killall ovs-testcontroller
sudo mn -c
#start mininet environment
sudo PYTHONPATH=$PYTHONPATH:../behavioral-model/mininet/ \
    python srcPython/toposetup.py \
    --json ./DOESNOTEXIST.json \
    --cli DOESNOTEXIST \
    --cliCmd DOESNOTEXIST.txt \
    $argsCommand
