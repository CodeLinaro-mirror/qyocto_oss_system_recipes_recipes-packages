# Copyright (c) 2019,  2021 The Linux Foundation. All rights reserved.
# Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
enable_affinity_al02_c6() {

	#pci 3
	#assign 4 rx interrupts to each cores
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_4' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_5' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_6' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_7' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity

	#assign 3 tcl completions to last 3 CPUs
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_0' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_1' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_2' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity

	# assign lmac,reo err,release interrupts are mapped to one core alone
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_3' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity

	# assign 4th tcl completion ring interrupt to core 3
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_11' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity

	#pci 4
	#assign 4 rx interrupts to each cores from reverse
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_4' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_5' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_6' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_7' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity

	#assign 3 tcl completions to last 3 CPUs
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_0' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_1' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_2' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity

	#assign lmac,reo err,release interrupts are mapped to one core alone
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_3' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity

	# assign 4th tcl completion ring interrupt to core 3
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_11' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity

	#assign affinity for 2 GHz Alder
	#assign 4 rx interrupts to each cores
	irq_affinity_num=`grep -E -m1 'reo2host-destination-ring4' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'reo2host-destination-ring3' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'reo2host-destination-ring2' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'reo2host-destination-ring1' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity

	#assign 3 tcl completions to last 3 CPUs
	irq_affinity_num=`grep -E -m1 'wbm2host-tx-completions-ring3' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'wbm2host-tx-completions-ring2' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'wbm2host-tx-completions-ring1' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity

	#For monitor interrupts
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_8' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_8' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity

}

enable_affinity_al02_c4() {

	#pci 3
	#assign 4 rx interrupts to each cores
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_4' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_5' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_6' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_7' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity

	#assign 3 tcl completions to last 3 CPUs
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_0' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_1' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_2' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity

	# assign lmac,reo err,release interrupts are mapped to one core alone
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_3' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity

	 # assign 4th tcl completion ring interrupt to core 3
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_11' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity

	# Enable smp affinity for PCIE attach
	#pci 2

	#assign 4 rx interrupts to each cores
	irq_affinity_num=`grep -E -m1 'pci2_wlan_dp_4' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci2_wlan_dp_5' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci2_wlan_dp_6' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci2_wlan_dp_7' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity

	#assign 3 tcl completions to last 3 CPUs
	irq_affinity_num=`grep -E -m1 'pci2_wlan_dp_0' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci2_wlan_dp_1' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci2_wlan_dp_2' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity

	# assign lmac,reo err,release interrupts are mapped to one core alone
	irq_affinity_num=`grep -E -m1 'pci2_wlan_dp_3' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity

	# assign 4th tcl completion ring interrupt to core 3
	irq_affinity_num=`grep -E -m1 'pci2_wlan_dp_11' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity

	#pci 4
	#assign 4 rx interrupts to each cores from reverse
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_4' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_5' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_6' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_7' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity

	#assign 3 tcl completions to last 3 CPUs
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_0' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_1' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_2' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity

	#assign lmac,reo err,release interrupts are mapped to one core alone
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_3' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity

	# assign 4th tcl completion ring interrupt to core 3
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_11' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 8 > /proc/irq/$irq_affinity_num/smp_affinity

	#For monitor interrupts
	irq_affinity_num=`grep -E -m1 'pci2_wlan_dp_8' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 1 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci3_wlan_dp_8' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 2 > /proc/irq/$irq_affinity_num/smp_affinity
	irq_affinity_num=`grep -E -m1 'pci4_wlan_dp_8' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	[ -n "$irq_affinity_num" ] && echo 4 > /proc/irq/$irq_affinity_num/smp_affinity

}
start(){
	local board_name=$(cat /tmp/sysinfo/board_name | awk -F 'ap-' '{print$2}')
        echo "$board_name"

case "$board_name" in
        al02-c6)
		until [ -d "/sys/class/net/wlan0" ] && [ -d "/sys/class/net/wlP3p1s0" ] && [ -d "/sys/class/net/wlP4p1s0" ]
		do
			sleep 1
		done
		enable_affinity_al02_c6
		tc qdisc replace dev eth4 root noqueue
		tc qdisc replace dev eth5 root noqueue
		ethtool -K eth4 gro off
		ethtool -K eth4 gso off
		ethtool -K eth5 gro off
		ethtool -K eth5 gso off
		ssdk_sh fdb learnCtrl set disable
		ssdk_sh fdb entry flush 1
		sysctl -w net.bridge.bridge-nf-call-ip6tables=1
		sysctl -w net.bridge.bridge-nf-call-iptables=1

		echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
		echo "performance" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
		echo "performance" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
		echo "performance" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor

		if [ -d "/sys/kernel/debug/ath12k" ]; then
		    # logic to identify QCN9274 V1.0 / V2.0
		    soc=`ls  /sys/kernel/debug/ath12k/ | head -n1 |awk '{print substr($0,0,13)}' | awk '{print $2}'`
		    case $soc in
		    "hw1.0")
			echo 0x21321321 > /sys/kernel/debug/ath12k/qcn92xx\ hw1.0_0004\:01\:00.0/rx_hash_ix2
			echo 0x13213213 > /sys/kernel/debug/ath12k/qcn92xx\ hw1.0_0004\:01\:00.0/rx_hash_ix3
			echo 0x21321321 > /sys/kernel/debug/ath12k/qcn92xx\ hw1.0_0003\:01\:00.0/rx_hash_ix2
			echo 0x13213213 > /sys/kernel/debug/ath12k/qcn92xx\ hw1.0_0003\:01\:00.0/rx_hash_ix3
			;;
		    "hw2.0")
			echo 0x21321321 > /sys/kernel/debug/ath12k/qcn92xx\ hw2.0_0004\:01\:00.0/rx_hash_ix2
			echo 0x13213213 > /sys/kernel/debug/ath12k/qcn92xx\ hw2.0_0004\:01\:00.0/rx_hash_ix3
			echo 0x21321321 > /sys/kernel/debug/ath12k/qcn92xx\ hw2.0_0003\:01\:00.0/rx_hash_ix2
			echo 0x13213213 > /sys/kernel/debug/ath12k/qcn92xx\ hw2.0_0003\:01\:00.0/rx_hash_ix3
		    ;;
		    esac
		fi
		echo 0 > /sys/class/net/wlan0/queues/rx-0/rps_cpus
		echo 0 > /sys/class/net/wlP3p1s0/queues/rx-0/rps_cpus
		echo 0 > /sys/class/net/wlP4p1s0/queues/rx-0/rps_cpus
		tc qdisc replace dev wlan0 root noqueue
		tc qdisc replace dev wlP3p1s0 root noqueue
		tc qdisc replace dev wlP4p1s0 root noqueue
		;;
	al02-c4)
		until [ -d "/sys/class/net/wlP3p1s0" ] && [ -d "/sys/class/net/wlP3p1s0" ] && [ -d "/sys/class/net/wlP4p1s0" ]
		do
			sleep 1
		done
		enable_affinity_al02_c4
		tc qdisc replace dev eth4 root noqueue
		tc qdisc replace dev eth5 root noqueue
		ethtool -K eth4 gro off
		ethtool -K eth4 gso off
		ethtool -K eth5 gro off
		ethtool -K eth5 gso off
		ssdk_sh fdb learnCtrl set disable
		ssdk_sh fdb entry flush 1
		sysctl -w net.bridge.bridge-nf-call-ip6tables=1
		sysctl -w net.bridge.bridge-nf-call-iptables=1

		echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
		echo "performance" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
		echo "performance" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
		echo "performance" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor

		if [ -d "/sys/kernel/debug/ath12k" ]; then
		    # logic to identify QCN9274 V1.0 / V2.0
		    soc=`ls  /sys/kernel/debug/ath12k/ | head -n1 |awk '{print substr($0,0,13)}' | awk '{print $2}'`
		    case $soc in
		    "hw1.0")
			echo 0x21321321 > /sys/kernel/debug/ath12k/qcn92xx\ hw1.0_0002\:01\:00.0/rx_hash_ix2
			echo 0x13213213 > /sys/kernel/debug/ath12k/qcn92xx\ hw1.0_0002\:01\:00.0/rx_hash_ix3
			echo 0x21321321 > /sys/kernel/debug/ath12k/qcn92xx\ hw1.0_0004\:01\:00.0/rx_hash_ix2
			echo 0x13213213 > /sys/kernel/debug/ath12k/qcn92xx\ hw1.0_0004\:01\:00.0/rx_hash_ix3
			echo 0x21321321 > /sys/kernel/debug/ath12k/qcn92xx\ hw1.0_0003\:01\:00.0/rx_hash_ix2
			echo 0x13213213 > /sys/kernel/debug/ath12k/qcn92xx\ hw1.0_0003\:01\:00.0/rx_hash_ix3
		    ;;
		   "hw2.0")
			echo 0x21321321 > /sys/kernel/debug/ath12k/qcn92xx\ hw2.0_0002\:01\:00.0/rx_hash_ix2
			echo 0x13213213 > /sys/kernel/debug/ath12k/qcn92xx\ hw2.0_0002\:01\:00.0/rx_hash_ix3
			echo 0x21321321 > /sys/kernel/debug/ath12k/qcn92xx\ hw2.0_0004\:01\:00.0/rx_hash_ix2
			echo 0x13213213 > /sys/kernel/debug/ath12k/qcn92xx\ hw2.0_0004\:01\:00.0/rx_hash_ix3
			echo 0x21321321 > /sys/kernel/debug/ath12k/qcn92xx\ hw2.0_0003\:01\:00.0/rx_hash_ix2
			echo 0x13213213 > /sys/kernel/debug/ath12k/qcn92xx\ hw2.0_0003\:01\:00.0/rx_hash_ix3
		    ;;
		    esac
		fi

		echo 0 > /sys/class/net/wlP3p1s0/queues/rx-0/rps_cpus
		echo 0 > /sys/class/net/wlP4p1s0/queues/rx-0/rps_cpus
		echo 0 > /sys/class/net/wlP2p1s0/queues/rx-0/rps_cpus
		tc qdisc replace dev wlP3p1s0 root noqueue
		tc qdisc replace dev wlP4p1s0 root noqueue
		tc qdisc replace dev wlP2p1s0 root noqueue
		;;
                *)
		echo "invalid board_number"
	esac
}


case "$1" in
    start)
	modprobe -a ath11k_ahb ath12k
	start
        ;;
        *)
        echo "Unsupported operation: available operations (start)"
esac



