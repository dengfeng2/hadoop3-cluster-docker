#!/bin/bash

HOSTS=( hadoop01 hadoop02 hadoop03 )

for HOST in ${HOSTS[*]}
do
    echo "--------- $HOST ---------"
    ssh -T $HOST << DELIMITER
    jps | grep -iv jps
    exit
DELIMITER

done
