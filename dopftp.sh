#!/bin/bash

DIR=`date +%s`
echo $DIR
#echo $MOTIW
lftp -e 'mirror --parallel=10 -R /home/motiw /motiw/'$DIR'/home' -u backup,$MOTIW 10.32.236.125
lftp -e 'mirror --parallel=10 -R /var/Motiw /motiw/'$DIR'/var/Motiw' -u backup,$MOTIW 10.32.236.125
lftp -e 'mirror --parallel=10 -R /etc /motiw/'$DIR'/etc' -u backup,$MOTIW 10.32.236.125

