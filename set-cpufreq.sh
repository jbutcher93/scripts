#!/usr/bin/env bash
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do  
  cpufreq-set -c "${cpu##*/cpu}" -g performance  
done   
