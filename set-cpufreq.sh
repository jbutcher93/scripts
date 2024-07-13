#!/usr/bin/env bash

# This script must be run prefixed with 'sudo' for admin rights

for cpu in /sys/devices/system/cpu/cpu[0-9]*; do  
  cpufreq-set -c "${cpu##*/cpu}" -g performance  
done   
