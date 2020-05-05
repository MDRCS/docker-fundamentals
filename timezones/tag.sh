#!/bin/bash
x=1
  for id in $(docker history -q "centos:7" | grep -vw missing | tac)
do
   docker tag "${id}" "centos:latest_step_${x}"
  	((x++))
done
