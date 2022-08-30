#!/system/bin/sh

freq_table=/data/gpu_freq_table.conf

opp_list=$(tac /proc/gpufreqv2/stack_working_opp_table | awk '{print $3$5}' | sed "s/.$//" | sed "s/,/ /g")

preset="# Freq Volt
$opp_list
"

if [[ ! -f $freq_table ]]; then
    echo "$preset" > $freq_table
fi
