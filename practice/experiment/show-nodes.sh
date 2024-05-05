#!/bin/bash

cp -r 2024* tmp_sumo
NODES_NUM=$(sumo -c ./tmp_sumo/osm.sumocfg 2>/dev/null | grep Inserted | awk  '{print $2}')
echo $NODES_NUM
mv tmp_sumo mobility/node_$NODES_NUM

rm -rf ./2024*
