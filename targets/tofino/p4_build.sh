#!/bin/sh
# set SDE and SDE_INSTALL variable to default values
: ${SDE=/opt/bf-sde-9.9.1}
: ${SDE_INSTALL=$SDE/install}
mkdir -p compile
$SDE_INSTALL/bin/bf-p4c -v -o $PWD/compile/ srcP4/l1switchCodel.p4
