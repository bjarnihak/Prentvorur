#!/bin/bash
./getconsum.sh -H 192.168.1.142 -C public -x "CONSUM ALL" | awk -F'|' '{print $2}'
